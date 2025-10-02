# Directus Flows (PlantUML)

This file diagrams the backend automation we’ll implement in Directus Flows. Each diagram includes a brief wiring guide (trigger + key operations) so you can configure it in Directus.

---

## 1) Lesson Completed → Update User Course Progress

Trigger when a user completes a lesson. Ensures unique lesson_progress, sets completed_at, and updates user_course_progress lessons_completed and percent_complete.

```plantuml
@startuml
!theme plain
start
:Event: Items -> Update (lesson_progress);
:Guard: completed == true;
if (Existing progress for (user, lesson)?) then (yes)
:Continue;
else (no)
:Create lesson_progress(user, lesson);
endif
:Set completed_at = now() if null;

:' Fetch course via lesson -> course;
:Read lesson by id -> L;
:course_id = L.course;

:' Aggregate totals;
:total_lessons = COUNT(lessons WHERE course = course_id);
:completed_lessons = COUNT(lesson_progress WHERE user = user_id AND lesson in lessons(course_id) AND completed = true);

if (user_course_progress exists for (user, course)?) then (yes)
:Update lessons_completed = completed_lessons;
else (no)
:Create user_course_progress(user, course, lessons_completed = completed_lessons, tests_passed = 0, percent_complete = 0);
endif

:' Recompute percent_complete (0..100);
if (total_lessons > 0?) then (yes)
:percent_from_lessons = floor((completed_lessons / total_lessons) * 100);
else (no)
:percent_from_lessons = 0;
endif

:' Optionally blend with test completion later;
:Update user_course_progress.percent_complete = percent_from_lessons (or blended);
stop
@enduml
```

Wiring in Directus:

- Trigger: Event → Items → Update on collection `lesson_progress`
- Filter: `completed` changed to true
- Steps:
    - Read Item (lessons) by `lesson_progress.lesson`
    - Aggregate Count (lessons by course)
    - Aggregate Count (lesson_progress by user and in course)
    - Upsert Item (user_course_progress by unique (user, course))
    - Update Field (percent_complete)

---

## 2) Quiz Submitted → Compute Passed and Update Progress

On quiz_attempts submission, set passed based on score_pct vs quizzes.passing_score_pct, then update user_course_progress.tests_passed and percent_complete.

```plantuml
@startuml
!theme plain
start
:Event: Items -> Create/Update (quiz_attempts);
if (submitted_at is set?) then (yes)
:Read the related quiz by quiz_attempts.quiz -> Q;
:passing = Q.passing_score_pct;
if (score_pct >= passing?) then (yes)
:Set passed = true;
else (no)
:Set passed = false;
endif

:' Find course from quiz;
:course_id = Q.course;

:' Update user_course_progress;
:tests_passed = COUNT(quiz_attempts WHERE user = user_id AND passed = true AND quiz in quizzes(course_id));
if (user_course_progress exists?) then (yes)
:Update tests_passed;
else (no)
:Create user_course_progress(user, course, lessons_completed=0, tests_passed, percent_complete=0);
endif

:' Optionally blend percent complete with test progress;
:Recompute percent_complete = max(current, from_lessons/tests);
endif
stop
@enduml
```

Wiring in Directus:

- Trigger: Event → Items → Create + Update on `quiz_attempts`
- Filter: `submitted_at` is not null
- Steps:
    - Read Item (quizzes) by `quiz_attempts.quiz`
    - Conditional: compare `score_pct` with `quizzes.passing_score_pct`
    - Update Field (`passed`)
    - Aggregate Count (passed attempts per user/course)
    - Upsert Item (user_course_progress)
    - Update Field (percent_complete)

---

## 3) Maintain Course Aggregates (lessons_count, duration_hours)

Keep course counters in sync whenever lessons are created/updated/deleted.

```plantuml
@startuml
!theme plain
start
:Event: Items -> Create/Update/Delete (lessons);
:Identify course_id (from lesson.course or old record);
:total_lessons = COUNT(lessons WHERE course = course_id);
:total_minutes = SUM(lessons.duration_minutes WHERE course = course_id);
if (total_minutes is null) then (yes)
 :total_minutes = 0;
endif
:duration_hours = ceil(total_minutes / 60);
:Update courses.lessons_count = total_lessons;
:Update courses.duration_hours = duration_hours;
stop
@enduml
```

Wiring in Directus:

- Trigger: Event → Items → Create + Update + Delete on `lessons`
- Steps:
    - Resolve course_id (from payload or previous item on delete)
    - Aggregate Count (lessons by course)
    - Aggregate Sum (duration_minutes by course)
    - Update Item (courses)

---

## 4) Order Processing Status Transitions

Manage status transitions and timestamps on order_processors. On approved/rejected, stamp processed_at and, if needed, toggle subscription.active.

```plantuml
@startuml
!theme plain
start
:Event: Items -> Update (order_processors);
:new_status = item.status;
if (new_status in [approved, rejected]) then (yes)
 :Set processed_at = now();
 if (new_status == approved) then (yes)
  :Optionally set subscriptions.active = true for item.subscription;
 else (no)
  :No change to subscriptions.active (or set false per policy);
 endif
else (no)
 :No-op (pending/reviewed);
endif
stop
@enduml
```

Wiring in Directus:

- Trigger: Event → Items → Update on `order_processors`
- Steps:
    - Condition on `status`
    - Update Field (processed_at)
    - Optional: Update Related Item (`subscriptions.active`)

---

## 5) Scheduled/Manual Backfill: Recalculate User Course Progress

Maintenance flow to recompute user_course_progress for a user/course pair, useful after bulk changes.

```plantuml
@startuml
!theme plain
start
:Trigger: Scheduled or Manual (Webhook) with user_id, course_id;
:total_lessons = COUNT(lessons WHERE course = course_id);
:completed_lessons = COUNT(lesson_progress WHERE user = user_id AND lesson in lessons(course_id) AND completed = true);
:tests_passed = COUNT(quiz_attempts WHERE user = user_id AND passed = true AND quiz in quizzes(course_id));
if (user_course_progress exists?) then (yes)
 :Update lessons_completed, tests_passed;
else (no)
 :Create user_course_progress(user, course, lessons_completed, tests_passed, percent_complete=0);
endif
if (total_lessons > 0?) then (yes)
 :percent_from_lessons = floor((completed_lessons / total_lessons) * 100);
else (no)
 :percent_from_lessons = 0;
endif
:Update percent_complete = percent_from_lessons (or blended rule);
stop
@enduml
```

Wiring in Directus:
- Trigger: Schedule or Webhook
- Inputs: `user_id`, `course_id`
- Steps:
    - Aggregate Counts/Sums as above
    - Upsert user_course_progress
    - Update percent_complete

---

Notes
- All flows rely on the Directus default system fields; no extra custom audit fields are created.
- Percent complete currently uses lesson completion only. If you want to blend quizzes, define a formula, e.g., percent = round(0.8 * lessons + 0.2 * tests).
- Ensure unique constraints via Directus Composite Unique on (user, lesson) and (user, course) where applicable.

