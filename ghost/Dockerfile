FROM ghost:6-alpine

USER root

RUN mkdir -p /var/lib/ghost/content/adapters/storage/s3 \
    && cd /var/lib/ghost/content/adapters/storage/s3 \
    && npm init -y \
    && npm install ghost-storage-adapter-s3 --omit=dev

RUN printf "module.exports = require('ghost-storage-adapter-s3');\n" \
    > /var/lib/ghost/content/adapters/storage/s3/index.js

USER node
