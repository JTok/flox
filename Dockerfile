# NOTE : This dockerfile uses a feature called docker multistage builds
# which would create two intermediate images that can be later removed
# if needed. This is done to keep the size of the final image smaller.
# Removal command : docker image prune (Please know what you're about to
# do while using this.
# Ref : https://docs.docker.com/develop/develop-images/multistage-build
#       https://docs.docker.com/engine/reference/commandline/image_prune

# Set env variables
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_USER_ID 33
ENV APACHE_RUN_GROUP www-data
ENV APACHE_RUN_GROUP_ID 33
ENV FLOX_DB_NAME flox
ENV FLOX_DB_USER flox_user
ENV FLOX_DB_PASS flox_pass
ENV FLOX_DB_HOST mysql 
ENV FLOX_DB_PORT 3306
ENV TMDB_API_KEY fce675de8abd8761b876b98554ac3254339
ENV FLOX_ADMIN_USER admin
ENV FLOX_ADMIN_PASS admin
ENV MYSQL_ROOT_PASSWORD password
ENV MYSQL_DATABASE: flox
ENV MYSQL_USER: flox_user
ENV MYSQL_PASSWORD: flox_pass

# start with the official node image and name it
FROM node:latest AS node
COPY ./client /flox/client
COPY ./public /flox/public
#RUN git clone https://github.com/devfake/flox.git \
RUN cd flox/client \
    && npm install \
    && npm run build


# build front end as named composer
FROM composer:latest AS composer
COPY ./backend /backend
WORKDIR /backend
RUN composer install


# continue with the official PHP image
FROM php:apache
# copy the built files from the previous images into the PHP image
COPY --from=node ./flox /var/www/html/
COPY --from=composer /backend /var/www/html/backend
COPY ./bin /var/www/html/bin
WORKDIR /var/www/html
# apache configs + document root
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
# mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin
RUN a2enmod rewrite headers
# install php modules
COPY ./entrypoint.sh /
COPY ./wait-for-it.sh /
COPY ./init-run.sh /
RUN apt-get update \
    && apt-get install -y curl wget libzip-dev \
    && apt-get clean \
    && docker-php-ext-configure zip \
    && docker-php-ext-install pdo_mysql zip \
    && chmod +x /wait-for-it.sh \
    && chmod +x /init-run.sh \
    && chmod +x /entrypoint.sh

# Launch the httpd in foreground
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
