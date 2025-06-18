#!/bin/bash
set -e

dnf update -y

dnf install -y nginx

systemctl enable nginx
systemctl start nginx

mkdir -p /var/www/html
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html

cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /var/www/html;
        index        index.html index.htm;

        location / {
            try_files $uri $uri/ /index.html;
        }

        location /health {
            access_log off;
            return 200 "OK";
            add_header Content-Type text/plain;
        }

        error_page   404              /404.html;
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
}
EOF

nginx -t
systemctl reload nginx

echo "Web server setup completed for ${project_name}" > /var/log/user-data.log
