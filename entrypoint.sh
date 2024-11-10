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

# Check if certificates already exist, if not, obtain them with Certbot
if [ ! -d "/etc/letsencrypt/live/$DOMAIN_NAME" ]; then
    echo "Obtaining SSL certificates for $DOMAIN_NAME and subdomains..."
    certbot certonly --nginx --non-interactive --agree-tos --email $EMAIL \
        -d $DOMAIN_NAME -d www.$DOMAIN_NAME -d $CLOCK_APP_NAME.$DOMAIN_NAME -d www.$CLOCK_APP_NAME.$DOMAIN_NAME
else
    echo "SSL certificates already exist for $DOMAIN_NAME."
fi

# Set up automatic renewal using cron
echo "Setting up automatic SSL certificate renewal..."
echo "0 0,12 * * * root certbot renew --nginx --quiet && nginx -s reload" > /etc/cron.d/certbot-renew
chmod 0644 /etc/cron.d/certbot-renew
crontab /etc/cron.d/certbot-renew
service cron start

echo "Starting Nginx..."
nginx -g 'daemon off;'
