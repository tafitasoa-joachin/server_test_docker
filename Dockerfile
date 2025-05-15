FROM php:8.2-fpm

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libicu-dev \
    libzip-dev \
    zip \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-install \
    pdo_mysql \
    intl \
    zip \
    opcache \
    gd \
    mbstring \
    exif \
    pcntl \
    bcmath \
    xml \
    && rm -rf /var/lib/apt/lists/*

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Définir le répertoire de travail
WORKDIR /var/www/symfony

# Autoriser Composer à s'exécuter en tant que root
ENV COMPOSER_ALLOW_SUPERUSER=1

# Copie de l'application
COPY . /var/www/symfony

# Configuration PHP pour la production
COPY docker/php/symfony.ini /usr/local/etc/php/conf.d/symfony.ini

# Installation des dépendances via Composer
RUN composer install --optimize-autoloader

# Environnement de production
ENV APP_ENV=prod

# Optimisation pour la production
RUN php bin/console cache:clear --env=prod \
    && php bin/console cache:warmup --env=prod \
    && php bin/console assets:install public --env=prod

# Exposition du port pour PHP-FPM
EXPOSE 80 
# EXPOSE 9000

CMD ["php-fpm"]