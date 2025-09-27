FROM node:20-alpine
WORKDIR /work

# install wget for health checks
RUN apk add --no-cache wget

RUN npm install -g directus-sync@3.3.0

# copy directus-sync config file
COPY directus-sync.config.js /work/directus-sync.config.js

# copy wait script and make executable
COPY wait-for-directus.sh /work/wait-for-directus.sh
RUN chmod +x /work/wait-for-directus.sh

ENTRYPOINT ["/work/wait-for-directus.sh"]