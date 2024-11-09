#!/bin/bash

envsubst '${DOMAIN_NAME} ${CLOCK_APP_NAME} ${MAIN_APP_PORT} ${CLOCK_APP_PORT}' < /etc/nginx/nginx.conf > /etc/nginx/conf.d/default.conf

if [ ! -d "/etc/letsencrypt/live/${DOMAIN_NAME}" ]; then
    certbot certonly --nginx --non-interactive --agree-tos --email ${EMAIL} -d ${DOMAIN_NAME} -d www.${DOMAIN_NAME}
fi
if [ ! -d "/etc/letsencrypt/live/${CLOCK_APP_NAME}.${DOMAIN_NAME}" ]; then
    certbot certonly --nginx --non-interactive --agree-tos --email ${EMAIL} -d ${CLOCK_APP_NAME}.${DOMAIN_NAME} -d www.${CLOCK_APP_NAME}.${DOMAIN_NAME}
fi

crond

nginx -g "daemon off;"

