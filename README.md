![alt text](rh_small_logo.jpg)
# railhead_plane
* This repository contains scripts and code to deploy railhead_plane. For any additional details or inquiries, please contact us at christopher.sargent@railhead.io.

* [Plane](https://github.com/makeplane/plane)
* [Plane Self Hosting Documentation](https://docs.plane.so/self-hosting/docker-compose)

* Tested on STIG Hardened Ubuntu 20.04

1. ssh onrails@184.94.220.214 (keycloak02)
2. sudo -i 
3. curl -fsSL https://get.docker.com -o install-docker.sh && sudo sh install-docker.sh
4. mkdir railhead_plane
5. cd railhead_plane
6. curl -fsSL -o setup.sh https://raw.githubusercontent.com/makeplane/plane/master/deploy/selfhost/install.sh
7. chmod +x setup.sh
8. ./setup.sh
* Select 1
```
---------------------------------------
 ____  _
|  _ \| | __ _ _ __   ___
| |_) | |/ _` | '_ \ / _ \
|  __/| | (_| | | | |  __/
|_|   |_|\__,_|_| |_|\___|

---------------------------------------
Project management tool from the future
---------------------------------------

Select a Action you want to perform:
   1) Install (x86_64)
   2) Start
   3) Stop
   4) Restart
   5) Upgrade
   6) View Logs
   7) Exit

Action [2]:
```
9. Select 7 for exit
10. cd plane-app 
11. vim .env 
* Update NGINX_PORT, WEB_URL and CORS_ALLOWED_ORIGINS
```
APP_RELEASE=latest

WEB_REPLICAS=1
SPACE_REPLICAS=1
API_REPLICAS=1

NGINX_PORT=80
WEB_URL=http://gov.ash.pln.001
DEBUG=0
NEXT_PUBLIC_DEPLOY_URL=http://localhost/spaces
SENTRY_DSN=
SENTRY_ENVIRONMENT=production
GOOGLE_CLIENT_ID=
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
DOCKERIZED=1 # deprecated
CORS_ALLOWED_ORIGINS=http://gov.ash.pln.001

#DB SETTINGS
PGHOST=plane-db
PGDATABASE=plane
POSTGRES_USER=plane
POSTGRES_PASSWORD=plane
POSTGRES_DB=plane
PGDATA=/var/lib/postgresql/data
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${PGHOST}/${PGDATABASE}

# REDIS SETTINGS
REDIS_HOST=plane-redis
REDIS_PORT=6379
REDIS_URL=redis://${REDIS_HOST}:6379/

# EMAIL SETTINGS
EMAIL_HOST=
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
EMAIL_PORT=587
EMAIL_FROM=Team Plane <team@mailer.plane.so>
EMAIL_USE_TLS=1
EMAIL_USE_SSL=0

# LOGIN/SIGNUP SETTINGS
ENABLE_SIGNUP=1
ENABLE_EMAIL_PASSWORD=1
ENABLE_MAGIC_LINK_LOGIN=0
SECRET_KEY=60gp0byfz2dvffa45cxl20p1scy9xbpf6d8c5y0geejgkyp1b5

# DATA STORE SETTINGS
USE_MINIO=1
AWS_REGION=
AWS_ACCESS_KEY_ID=access-key
AWS_SECRET_ACCESS_KEY=secret-key
AWS_S3_ENDPOINT_URL=http://plane-minio:9000
AWS_S3_BUCKET_NAME=uploads
MINIO_ROOT_USER=access-key
MINIO_ROOT_PASSWORD=secret-key
BUCKET_NAME=uploads
FILE_SIZE_LIMIT=5242880

# Gunicorn Workers
GUNICORN_WORKERS=2
```
12. cp /etc/hosts /etc/hosts.$(date +'%Y%m%d%H%M')
13. echo '184.94.220.214 gov.ash.pln.001' >> /etc/hosts
14. vi /etc/docker/daemon.json
* Note that you have to change the IP subnet docker uses as the default is 172.18.0.0/24 which interferes with infrastructure at railhead
{
  "default-address-pools":
  [
    {"base":"10.10.0.0/16","size":24}
  ]
}
15. systemctl restart docker
16. cd ../ && ./setup.sh 
* 2 for Start
17. Select 7 for exit 
18. PowerShell Admin > notepad C:\Windows\System32\drivers\etc\hosts
```
184.94.220.214 gov.ash.pln.001
```
19. http://gov.ash.pln.001
20. 
# Set up for SSL
21. cd /root/railhead_plane

22. mkdir railhead_nginx
23. cd railhead_nginx
24. vim nginx_config.sh 
```
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
    proxy_pass http://184.94.220.214/;
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
```
25. chmod +x nginx_config.sh
26. ./nginx_config.sh
27. vim nginx-compose.yml 
```
version: '3'
services:
  nginx:
   container_name: railhead_nginx
   restart: always
   image: nginx
   volumes:
   - ./nginx/ssl/self.cert:/etc/nginx/ssl/self.cert:ro
   - ./nginx/ssl/self-ssl.key:/etc/nginx/ssl/self-ssl.key:ro
   - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
   - ./nginx/mysite.template:/etc/nginx/conf.d/default.conf:ro
   ports:
   - 443:443

  # run nginx
   command: /bin/bash -c "nginx -g 'daemon off;'"
```
28. docker compose -f nginx-compose.yml up -d
29. docker ps
```
CONTAINER ID   IMAGE                             COMMAND                  CREATED              STATUS              PORTS                                           NAMES
fbbf3a4d438a   nginx                             "/docker-entrypoint.…"   About a minute ago   Up About a minute   80/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp   railhead_nginx
dadd0c47de28   makeplane/plane-proxy:latest      "/docker-entrypoint.…"   12 minutes ago       Up 12 minutes       0.0.0.0:80->80/tcp, :::80->80/tcp               plane-app-proxy-1
dcf8517c6219   makeplane/plane-space:latest      "docker-entrypoint.s…"   12 minutes ago       Up 12 minutes       3000/tcp                                        plane-app-space-1
0b181bd02902   makeplane/plane-frontend:latest   "docker-entrypoint.s…"   12 minutes ago       Up 12 minutes       3000/tcp                                        plane-app-web-1
fb372c94730b   makeplane/plane-backend:latest    "./bin/beat"             12 minutes ago       Up 12 minutes       8000/tcp                                        plane-app-beat-worker-1
882168ca928c   makeplane/plane-backend:latest    "./bin/worker"           12 minutes ago       Up 12 minutes       8000/tcp                                        plane-app-worker-1
155a7e6c154d   makeplane/plane-backend:latest    "./bin/takeoff"          12 minutes ago       Up 12 minutes       8000/tcp                                        plane-app-api-1
d425e7e1a40f   postgres:15.2-alpine              "docker-entrypoint.s…"   12 minutes ago       Up 12 minutes       5432/tcp                                        plane-app-plane-db-1
af6e1d7c4497   redis:6.2.7-alpine                "docker-entrypoint.s…"   12 minutes ago       Up 12 minutes       6379/tcp                                        plane-app-plane-redis-1
79cb387c3167   minio/minio                       "/usr/bin/docker-ent…"   12 minutes ago       Up 12 minutes       9000/tcp                                        plane-app-plane-minio-1
```
30. https://184.94.220.214/god-mode
* christopher.sargent@railhead.io
* 31Nst31n!40
31. Got to Go Mode
