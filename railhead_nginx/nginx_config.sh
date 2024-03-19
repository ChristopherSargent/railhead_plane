#!/bin/sh
# Create folders
mkdir -p ./nginx/ssl && chmod -R +x ./init

# Create SSL certs
echo "Creating SSL certificates"
openssl req -nodes -newkey rsa:4096 -new -x509 -keyout nginx/ssl/self-ssl.key -out nginx/ssl/self.cert -subj '/C=US/ST=Virginia/L=Reston/O=Railhead/OU=Onrails/CN=gov.ash.pln.001'
echo "You can use your own certificates by placing the private key in nginx/ssl/self-ssl.key and the cert in nginx/ssl/self.cert"
echo "done"

# Fix mysite.template
echo "Create file mysite.template and add data"
touch ./nginx/mysite.template
echo '
### BBB
server {
    listen       443 ssl http2;
    server_name  localhost;

        ssl_certificate /etc/nginx/ssl/self.cert;
        ssl_certificate_key /etc/nginx/ssl/self-ssl.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
        ssl_ecdh_curve secp384r1;
        ssl_session_cache shared:SSL:10m;
        ssl_session_tickets off;
        ssl_stapling off;
        ssl_stapling_verify off;
#        resolver 8.8.8.8 8.8.4.4 valid=300s;
#        resolver_timeout 5s;

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    location / {
    proxy_pass http://gov.ash.pln.001/;
    proxy_buffering off;
    proxy_http_version 1.1;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
    proxy_cookie_path /guacamole/ /;
    access_log off;
    # allow large uploads (default=1m)
    # 4096m = 4GByte
    client_max_body_size 4096m;
}

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

}' > ./nginx/mysite.template

# Fix nginx.conf 
echo "Create file nginx.conf and add data"
touch ./nginx/nginx.conf
echo ' 
### AAA
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}' > ./nginx/nginx.conf
