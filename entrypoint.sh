#!/bin/bash

# Substitute environment variables in nginx template
envsubst '$DOMAIN_NAME $MAIN_APP_PORT $CLOCK_APP_NAME $CLOCK_APP_PORT' < /etc/nginx/nginx.conf > /tmp/nginx.conf.temp

# Verify that the substitution was successful
if [[ -f /tmp/nginx.conf.temp ]]; then
    echo "Substitution successful. Moving configuration file."
    mv /tmp/nginx.conf.temp /etc/nginx/nginx.conf
else
    echo "Error: envsubst failed to create the substituted nginx.conf file."
    exit 1
fi

nginx -g 'daemon off;'
