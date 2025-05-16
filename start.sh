#!/bin/sh

# Ajustement du port Nginx selon la variable d'environnement de Render
if [ ! -z "$PORT" ]; then
  sed -i "s/listen 80/listen $PORT/g" /etc/nginx/http.d/default.conf
fi

# S'assurer que les répertoires de log existent
mkdir -p /var/log/nginx
touch /var/log/nginx/project_error.log /var/log/nginx/project_access.log

# Correction de la configuration fastcgi
sed -i "s/fastcgi_pass php:9000/fastcgi_pass 127.0.0.1:9000/g" /etc/nginx/http.d/default.conf

# Copie du fichier autoload si nécessaire (pour Symfony 7)
if [ -f /var/www/project/vendor/autoload.php ] && [ ! -f /var/www/project/vendor/autoload_runtime.php ]; then
    cp /var/www/project/vendor/autoload.php /var/www/project/vendor/autoload_runtime.php
elif [ -f /var/www/project/vendor/symfony/runtime/autoload_runtime.php ] && [ ! -f /var/www/project/vendor/autoload_runtime.php ]; then
    mkdir -p $(dirname /var/www/project/vendor/autoload_runtime.php)
    cp /var/www/project/vendor/symfony/runtime/autoload_runtime.php /var/www/project/vendor/autoload_runtime.php
fi

# debogage en ligne
php bin/console debug:router --env=prod

# Démarrage de PHP-FPM en arrière-plan
php-fpm -D

# Démarrage de Nginx en premier plan
nginx -g "daemon off;"