FROM php:8.2-fpm

# Arguments définis dans docker-compose.yml
ARG USER
ARG USER_ID
ARG GROUP_ID

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

# Création d'un utilisateur non-root pour exécuter l'application
RUN groupadd -g ${GROUP_ID} ${USER} \
    && useradd -u ${USER_ID} -g ${USER} -s /bin/bash ${USER}

# Copie des fichiers composer avant l'installation des dépendances
COPY --chown=${USER}:${USER} composer.json composer.lock symfony.lock ./

# Copie de la configuration PHP pour la production
COPY --chown=${USER}:${USER} docker/php/symfony.ini /usr/local/etc/php/conf.d/symfony.ini

# Configuration des permissions
RUN mkdir -p var/cache var/log vendor \
    && chown -R ${USER}:${USER} var vendor

# Passage à l'utilisateur non-root
USER ${USER}

# Installation des dépendances via Composer
RUN composer install --prefer-dist --no-scripts --no-progress --no-interaction

# Copie du reste de l'application après l'installation des dépendances
USER root
COPY --chown=${USER}:${USER} . .
USER ${USER}

# Exécution des scripts Composer et optimisation pour la production
RUN composer dump-autoload --optimize \
    && composer run-script post-install-cmd \
    && php bin/console cache:clear --no-warmup \
    && php bin/console cache:warmup

# Nettoyage pour la production
RUN if [ "$APP_ENV" = "prod" ]; then \
    composer install --prefer-dist --no-dev --no-scripts --no-progress --no-interaction; \
    composer dump-autoload --optimize --no-dev --classmap-authoritative; \
    php bin/console cache:clear --env=prod --no-debug; \
    fi

# Exposition du port pour PHP-FPM
EXPOSE 9000

CMD ["php-fpm"]