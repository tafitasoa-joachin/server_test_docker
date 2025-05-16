#!/bin/sh
set -e

# Imprimer des informations de débogage
echo "Configuration du serveur..."
echo "Render PORT = $PORT"

# Si la variable PORT n'est pas définie, utiliser 10000 par défaut
if [ -z "$PORT" ]; then
  PORT=10000
  echo "Aucun PORT défini, utilisation de la valeur par défaut: $PORT"
fi

# Créer une configuration Nginx qui écoute sur le port spécifié
cat > /etc/nginx/nginx.conf << EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log debug;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    keepalive_timeout 65;
    
    server {
        listen ${PORT} default_server;
        server_name _;

        root /var/www/symfony/public;

        index index.php;
        
        # Configuration avancée pour le débogage des requêtes
        error_log /var/log/nginx/project_error.log debug;
        access_log /var/log/nginx/project_access.log main;
        
        # Configuration pour Symfony
        location / {
            try_files \$uri /index.php\$is_args\$args;
        }
        
        location ~ ^/index\.php(/|$) {
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_split_path_info ^(.+\.php)(/.*)$;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            fastcgi_param DOCUMENT_ROOT \$realpath_root;
            fastcgi_buffer_size 16k;
            fastcgi_buffers 4 16k;
            internal;
        }
        
        location ~ \.php$ {
            return 404;
        }
    }
}
EOF

# Configurer supervisord pour gérer les processus
cat > /etc/supervisor/conf.d/supervisord.conf << EOF
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
user=root

[program:php-fpm]
command=php-fpm
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
priority=10
startretries=5
startsecs=5

[program:check-ports]
command=sh -c "sleep 5 && echo 'Vérification des ports en écoute:' && netstat -tuln"
autostart=true
autorestart=false
startretries=0
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
priority=20
startsecs=0
EOF

# Configuration PHP pour la production
echo "date.timezone = UTC" > /usr/local/etc/php/conf.d/symfony.ini
echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/symfony.ini
echo "opcache.enable = 1" >> /usr/local/etc/php/conf.d/symfony.ini
echo "opcache.enable_cli = 1" >> /usr/local/etc/php/conf.d/symfony.ini
echo "opcache.memory_consumption = 256" >> /usr/local/etc/php/conf.d/symfony.ini

# Configuration de l'environnement Symfony
export APP_ENV=prod
export APP_DEBUG=0

# Optimisation pour la production
echo "Optimisation pour la production..."
php bin/console cache:clear --env=prod
php bin/console cache:warmup --env=prod
php bin/console assets:install public --env=prod

# Créer un fichier de test pour vérifier que le serveur fonctionne
echo "<html><body><h1>Symfony application is running!</h1></body></html>" > /var/www/symfony/public/test.html

# Afficher les informations système
echo "Informations système:"
echo "- Répertoire actuel: $(pwd)"
echo "- Configuration Nginx:"
cat /etc/nginx/nginx.conf | grep -A 5 "listen"

# Démarrer supervisord
echo "Démarrage des services..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf