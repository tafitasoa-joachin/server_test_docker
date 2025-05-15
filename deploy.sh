# Ce script facilite le déploiement de votre application Symfony sur Render

# Variables d'environnement
export DATABASE_URL="mysql://ue8t5vjaz1rhvrkj:sMaDfFPkUjKaO4RdAndk@bztk5ekzudeux7v5tznc-mysql.services.clever-cloud.com:3306/bztk5ekzudeux7v5tznc?serverVersion=8.0"
export APP_ENV="prod"
export APP_SECRET="your-app-secret"

# Mise à jour des dépendances
composer install --no-dev --optimize-autoloader

# Nettoyage et réchauffeage du cache
php bin/console cache:clear --env=prod
php bin/console cache:warmup --env=prod

# Migration de la base de données
php bin/console doctrine:migrations:migrate --no-interaction

# Installation des assets
php bin/console assets:install public --env=prod

# Si vous utilisez webpack encore
# yarn install
# yarn encore production

echo "Application prête pour le déploiement!"