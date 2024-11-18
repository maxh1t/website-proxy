#!/bin/bash

# Check that essential environment variables are set
echo "Starting with the following environment variables:"
echo "DOMAIN_NAME: $DOMAIN_NAME"
echo "EMAIL: $EMAIL"
echo "MAIN_APP_PORT: $MAIN_APP_PORT"
echo "CLOCK_APP_NAME: $CLOCK_APP_NAME"
echo "CLOCK_APP_PORT: $CLOCK_APP_PORT"
echo "AUTH_FORM_APP_NAME: $AUTH_FORM_APP_NAME"
echo "AUTH_FORM_APP_PORT: $AUTH_FORM_APP_PORT"

# Substitute environment variables in nginx.conf template
echo "Configuring Nginx with environment variables..."
envsubst '$DOMAIN_NAME $MAIN_APP_PORT $CLOCK_APP_NAME $CLOCK_APP_PORT $AUTH_FORM_APP_NAME $AUTH_FORM_APP_PORT' < /etc/nginx/nginx.conf > /tmp/nginx.conf.temp

# Move the substituted config file if successful, else exit
if [[ -f /tmp/nginx.conf.temp ]]; then
    mv /tmp/nginx.conf.temp /etc/nginx/nginx.conf
    echo "Nginx configuration updated successfully."
else
    echo "Error: Failed to configure Nginx. Exiting."
    exit 1
fi

# Stop Nginx if running, to free up port 80 for Certbot standalone mode
nginx -s stop || true

# Obtain SSL certificates if not already present
if [ ! -d "/etc/letsencrypt/live/$DOMAIN_NAME" ]; then
    echo "SSL certificates not found. Requesting new certificates for $DOMAIN_NAME and subdomains..."
    certbot certonly --standalone --non-interactive --agree-tos --email $EMAIL \
        -d $DOMAIN_NAME -d www.$DOMAIN_NAME -d $CLOCK_APP_NAME.$DOMAIN_NAME -d www.$CLOCK_APP_NAME.$DOMAIN_NAME -d $AUTH_FORM_APP_NAME.$DOMAIN_NAME -d www.$AUTH_FORM_APP_NAME.$DOMAIN_NAME

    # Verify certificate issuance
    if [ -d "/etc/letsencrypt/live/$DOMAIN_NAME" ]; then
        echo "SSL certificates obtained successfully for $DOMAIN_NAME."
    else
        echo "Error: Failed to obtain SSL certificates. Exiting."
        exit 1
    fi
else
    echo "Existing SSL certificates found for $DOMAIN_NAME."
fi

# Set up a cron job for automatic SSL renewal
echo "Configuring automatic SSL certificate renewal..."
echo "0 0,12 * * * root certbot renew --quiet && nginx -s reload" > /etc/cron.d/certbot-renew
chmod 0644 /etc/cron.d/certbot-renew
crontab /etc/cron.d/certbot-renew
service cron start
echo "Automatic renewal configured. Cron job added to check twice daily."

# Display the initial Certbot log if available
if [ -f /var/log/letsencrypt/letsencrypt.log ]; then
    echo "Initial Certbot log:"
    tail -n 10 /var/log/letsencrypt/letsencrypt.log
else
    echo "No Certbot log found. Certbot may not have run yet."
fi

# Start Nginx in the foreground
echo "Starting Nginx..."
nginx -g 'daemon off;'
