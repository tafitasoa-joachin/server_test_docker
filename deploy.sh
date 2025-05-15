#!/bin/bash

# Ce script facilite le déploiement de votre application Symfony sur Render

# Variables d'environnement
export DATABASE_URL="mysql://ue8t5vjaz1rhvrkj:sMaDfFPkUjKaO4RdAndk@bztk5ekzudeux7v5tznc-mysql.services.clever-cloud.com:3306/bztk5ekzudeux7v5tznc?serverVersion=8.0"
export APP_ENV="prod"
export APP_SECRET="your-app-secret"

export COMPOSER_MEMORY_LIMIT=-1

# Mise à jour des dépendances - Suppression de l'option --no-dev
composer install --optimize-autoloader

# Nettoyage et réchauffage du cache
php bin/console cache:clear --env=prod
php bin/console cache:warmup --env=prod

# Migration de la base de données
php bin/console doctrine:migrations:migrate --no-interaction

# Installation des assets
php bin/console assets:install public --env=prod

# Si vous utilisez webpack encore
# yarn install
# yarn encore production

# Vérifier que Nginx fonctionne
if ! ps aux | grep -q "[n]ginx"; then
    echo "Nginx ne fonctionne pas"
    exit 1
fi

# Vérifier que PHP-FPM fonctionne
if ! ps aux | grep -q "[p]hp-fpm"; then
    echo "PHP-FPM ne fonctionne pas"
    exit 1
fi

# Vérifier que le port 8080 est en écoute
if ! netstat -tulpn | grep -q ":8080"; then
    echo "Port 8080 non ouvert"
    exit 1
fi

echo "Application prête pour le déploiement!"
exit 0