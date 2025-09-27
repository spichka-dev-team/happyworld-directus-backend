######
# Stage 1: Build the auth-otp extension with devDependencies
######
FROM node:20-alpine AS auth-otp-builder
WORKDIR /app

# Install deps first to leverage Docker layer caching
COPY ./extensions/auth-otp/package*.json ./
RUN npm ci

# Copy the rest and build
COPY ./extensions/auth-otp/ ./
RUN npm run build

######
# Stage 1b: Build the utils extension with devDependencies
######
FROM node:20-alpine AS utils-builder
WORKDIR /app

COPY ./extensions/utils/package*.json ./
RUN npm ci

COPY ./extensions/utils/ ./
RUN npm run build

######
# Stage 2: Final Directus image
######
FROM directus/directus:11.5.1

USER root

RUN mkdir -p /directus/extensions/auth-otp
RUN mkdir -p /directus/extensions/utils

# Copy only the built output and package.json (runtime only)
COPY --from=auth-otp-builder /app/dist /directus/extensions/auth-otp/dist
COPY --from=auth-otp-builder /app/package.json /directus/extensions/auth-otp/package.json

COPY --from=utils-builder /app/dist /directus/extensions/utils/dist
COPY --from=utils-builder /app/package.json /directus/extensions/utils/package.json

# Install runtime dependencies for the auth-otp extension (eg. jsonwebtoken)
RUN npm ci --omit=dev --prefix /directus/extensions/auth-otp || npm install --omit=dev --prefix /directus/extensions/auth-otp

# Install runtime dependencies for the utils extension
RUN npm ci --omit=dev --prefix /directus/extensions/utils || npm install --omit=dev --prefix /directus/extensions/utils

# -----------------------------
# directus-sync extension
# -----------------------------
RUN npm install --prefix /directus/extensions directus-extension-sync@^3.0.2 && \
    mv /directus/extensions/node_modules/directus-extension-sync \
       /directus/extensions/directus-extension-sync && \
    rm -rf /directus/extensions/node_modules

# Ensure proper ownership for the node user
RUN chown -R node:node /directus/extensions

USER node
