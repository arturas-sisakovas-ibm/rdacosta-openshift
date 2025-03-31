#!/usr/bin/env bash

envsubst '${WORLD_API}' < /opt/app-root/src/config.template.js > /opt/app-root/src/config.js

exec nginx -g 'daemon off;'
