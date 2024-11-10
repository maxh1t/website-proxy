#!/bin/bash

# Debug: Check if environment variables are set
echo "Environment Variables:"
echo "DOMAIN_NAME: $DOMAIN_NAME"
echo "EMAIL: $EMAIL"
echo "MAIN_APP_PORT: $MAIN_APP_PORT"
echo "CLOCK_APP_NAME: $CLOCK_APP_NAME"
echo "CLOCK_APP_PORT: $CLOCK_APP_PORT"

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

nginx -s stop || true

# Check if certificates already exist, if not, obtain them with Certbot standalone mode
if [ ! -d "/etc/letsencrypt/live/$DOMAIN_NAME" ]; then
    echo "Obtaining SSL certificates for $DOMAIN_NAME and subdomains using standalone mode..."
    certbot certonly --standalone --non-interactive --agree-tos --email $EMAIL \
        -d $DOMAIN_NAME -d www.$DOMAIN_NAME -d $CLOCK_APP_NAME.$DOMAIN_NAME -d www.$CLOCK_APP_NAME.$DOMAIN_NAME

    # Check if Certbot was successful in creating certificates
    if [ -d "/etc/letsencrypt/live/$DOMAIN_NAME" ]; then
        echo "Certificates successfully obtained for $DOMAIN_NAME."
    else
        echo "Error: Failed to obtain SSL certificates for $DOMAIN_NAME."
        exit 1
    fi
else
    echo "SSL certificates already exist for $DOMAIN_NAME."
fi


# Set up automatic renewal using cron
echo "Setting up automatic SSL certificate renewal..."
echo "0 0,12 * * * root certbot renew --quiet && nginx -s reload" > /etc/cron.d/certbot-renew
chmod 0644 /etc/cron.d/certbot-renew
crontab /etc/cron.d/certbot-renew
service cron start

echo "Cron jobs for root:"
crontab -l

# Check the Certbot log for any errors or issues
echo "Contents of the Certbot log (/var/log/letsencrypt/letsencrypt.log):"
if [ -f /var/log/letsencrypt/letsencrypt.log ]; then
    cat /var/log/letsencrypt/letsencrypt.log
else
    echo "Certbot log file not found. Certbot may not have run yet or log location is incorrect."
fi

echo "Starting Nginx..."
nginx -g 'daemon off;'
