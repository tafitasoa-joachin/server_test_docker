FROM php:8.2-apache

# Installation des dépendances et extensions PHP
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    && docker-php-ext-install \
    pdo_mysql \
    intl \
    zip \
    opcache \
    gd \
    mbstring \
    bcmath \
    xml \
    exif \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

# Configuration PHP optimisée pour la production
RUN echo 'memory_limit = 256M\n\
    opcache.enable=1\n\
    opcache.memory_consumption=256\n\
    opcache.interned_strings_buffer=8\n\
    opcache.max_accelerated_files=20000\n\
    opcache.revalidate_freq=0\n\
    opcache.validate_timestamps=0\n\
    realpath_cache_size=4096K\n\
    realpath_cache_ttl=600\n\
    post_max_size = 16M\n\
    upload_max_filesize = 8M' > /usr/local/etc/php/conf.d/symfony.ini

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

# Configuration du répertoire de travail
WORKDIR /var/www/html

# Copie du code source
COPY . .

# Installation des dépendances
RUN composer install --optimize-autoloader --no-dev

# Configuration de l'environnement
ENV APP_ENV=prod

# Optimisations pour la production
RUN php bin/console cache:clear --env=prod \
    && php bin/console cache:warmup --env=prod \
    && php bin/console assets:install public --env=prod \
    && chown -R www-data:www-data var/

# Configuration d'Apache pour Symfony
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/www/html/public\n\
    <Directory /var/www/html/public>\n\
    AllowOverride None\n\
    Require all granted\n\
    FallbackResource /index.php\n\
    DirectoryIndex index.php\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
    </VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Préparation pour Render
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port 80
EXPOSE 80

# Commande de démarrage
CMD ["/usr/local/bin/start.sh"]