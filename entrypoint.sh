#!/bin/sh
#
# startup script for Render
#

# Si un fichier render.yaml existe, on est sur Render
if [ -f "/etc/render/config.yaml" ]; then
    echo "Démarrage de l'application sur Render..."
    
    # Assurez-vous que PHP et Nginx sont correctement configurés
    mkdir -p /var/log/nginx
    mkdir -p /run/nginx
    mkdir -p /var/log/supervisor
    
    # Démarrer supervisord qui va gérer PHP-FPM et Nginx
    exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
else
    # En développement local, nous utilisons la configuration standard
    echo "Démarrage de l'application en mode local..."
    exec php-fpm
fi