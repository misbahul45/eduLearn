FROM nginx:alpine

RUN mkdir -p /etc/nginx/snippets

COPY default.conf /etc/nginx/conf.d/default.conf
COPY snippets/ws.conf /etc/nginx/snippets/ws.conf