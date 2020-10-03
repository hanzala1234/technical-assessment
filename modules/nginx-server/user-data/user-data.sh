#!/bin/bash

# Install Nginx
amazon-linux-extras install nginx1.12
service nginx start
mkdir -p /var/www/html
echo $(hostname) > /var/www/html/health.html
echo  " 
    worker_processes  1;
    events {
    worker_connections  1024;
    }

   http {

    server {
        listen       5000 default_server;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
        server {
        listen       6000 default_server;
        server_name  _;
        root         /var/www/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

    } 
    }" > /etc/nginx/nginx.conf
systemctl restart nginx