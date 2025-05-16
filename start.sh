#!/bin/sh
set -e

# Afficher des informations de débogage
echo "=============== DÉMARRAGE DE L'APPLICATION ==============="
echo "PORT défini par Render: $PORT"

# Si le PORT n'est pas défini, utiliser 10000 par défaut (valeur souvent utilisée par Render)
if [ -z "$PORT" ]; then
    PORT=10000
    echo "PORT non défini, utilisation du port par défaut: $PORT"
fi

# Créer un fichier de configuration Nginx spécifique
cat > /etc/nginx/http.d/default.conf << EOF
server {
    listen $PORT default_server;
    server_name _;
    root /var/www/symfony/public;

    location / {
        try_files \$uri /index.php\$is_args\$args;
    }

    location ~ ^/index\.php(/|$) {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$document_root;
        internal;
    }

    location ~ \.php$ {
        return 404;
    }

    error_log /dev/stdout info;
    access_log /dev/stdout;
}
EOF

echo "Configuration Nginx générée avec le port $PORT :"
cat /etc/nginx/http.d/default.conf

echo "=============== DÉMARRAGE DES SERVICES ==============="

# Démarrer PHP-FPM en arrière-plan
echo "Démarrage de PHP-FPM..."
php-fpm -D

# Vérifier que PHP-FPM est en cours d'exécution
sleep 2
if pgrep -x "php-fpm" > /dev/null; then
    echo "PHP-FPM démarré avec succès."
else
    echo "ERREUR: PHP-FPM n'a pas démarré correctement."
    exit 1
fi

# Démarrer Nginx en premier plan
echo "Démarrage de Nginx sur le port $PORT..."
mkdir -p /run/nginx
nginx -g "daemon off;"