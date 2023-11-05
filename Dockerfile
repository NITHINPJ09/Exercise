FROM nginx:alpine
COPY css /usr/share/nginx/html
COPY index.html /usr/share/nginx/html
