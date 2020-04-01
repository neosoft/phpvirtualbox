FROM php:7-apache

RUN apt-get update && \
    apt-get install -y \
        libxml2 \
        libxml2-dev && \
    docker-php-ext-install soap

WORKDIR /var/www/html

COPY . /var/www/html
