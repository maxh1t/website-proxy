FROM nginx:latest

RUN apt-get update && \
    apt-get install -y certbot python3-certbot-nginx cron && \
    rm -rf /var/lib/apt/lists/* \

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh
RUN echo "0 3 * * * certbot renew --quiet && nginx -s reload" >> /etc/crontab

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
