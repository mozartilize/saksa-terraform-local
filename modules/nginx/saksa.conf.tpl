upstream saksa {
        server ${server1}:8000;
}

map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
}

server {
        listen 80;
        listen [::]:80;

        server_name localhost;

        location / {
                proxy_pass http://saksa;
                proxy_set_header Host $http_host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
        location /socket.io {
                proxy_pass http://saksa;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
                proxy_set_header Host $http_host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
}