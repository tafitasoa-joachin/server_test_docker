#!/bin/sh

# Afficher des informations de débogage
echo "Démarrage de l'application..."
echo "Variable PORT définie : $PORT"

# Création des répertoires nécessaires s'ils n'existent pas
mkdir -p /var/log/nginx
touch /var/log/nginx/access.log /var/log/nginx/error.log

# Ajustement du port Nginx selon la variable d'environnement de Render
if [ ! -z "$PORT" ]; then
  echo "Configuration du port Nginx sur $PORT"
  # Modifier la configuration nginx.conf au lieu de default.conf
  sed -i "s/listen 80/listen $PORT/g" /etc/nginx/nginx.conf
fi

# Vérifier que la configuration a bien été appliquée
echo "Configuration Nginx actuelle :"
cat /etc/nginx/nginx.conf

# Démarrage de PHP-FPM en arrière-plan
echo "Démarrage de PHP-FPM..."
php-fpm -D

# Vérifier que PHP-FPM est bien démarré
sleep 2
ps aux | grep php-fpm

# Démarrage de Nginx en premier plan pour garder le conteneur actif
echo "Démarrage de Nginx..."
nginx -g "daemon off;"