#!/bin/bash
set -e

# Si le port est défini par Render, configurer Apache pour l'utiliser
if [ -n "$PORT" ]; then
    echo "PORT variable detected: $PORT"
    sed -i "s/Listen 80/Listen $PORT/g" /etc/apache2/ports.conf
    sed -i "s/*:80/*:$PORT/g" /etc/apache2/sites-available/000-default.conf
    echo "Apache configured to listen on port $PORT"
fi

# Vérification des ports configurés
echo "Apache ports.conf:"
cat /etc/apache2/ports.conf
echo "VirtualHost configuration:"
cat /etc/apache2/sites-available/000-default.conf

# Appliquer les permissions correctes
chown -R www-data:www-data /var/www/html/var

# Démarrer Apache en premier plan
echo "Starting Apache..."
exec apache2-foreground