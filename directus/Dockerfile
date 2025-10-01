FROM directus/directus:11.12.0

USER root

RUN mkdir -p /directus/extensions

# Install the extension
RUN npm install --prefix /directus/extensions directus-extension-sync@^3.0.2

# Move the extension to the correct place
RUN mv /directus/extensions/node_modules/directus-extension-sync /directus/extensions/directus-extension-sync && \
    rm -rf /directus/extensions/node_modules

USER node