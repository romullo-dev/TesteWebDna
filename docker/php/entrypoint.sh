#!/bin/sh
set -e

cd /var/www

if [ -f .env.docker ] && [ ! -f .env ]; then
  cp .env.docker .env
elif [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi

composer install --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader

if [ -f artisan ]; then
  APP_KEY_VALUE=$(sed -n 's/^APP_KEY=//p' .env | head -n 1)
  if [ -z "$APP_KEY_VALUE" ]; then
    php artisan key:generate --force --no-ansi
    APP_KEY_VALUE=$(sed -n 's/^APP_KEY=//p' .env | head -n 1)
  fi
  if [ -n "$APP_KEY_VALUE" ]; then
    export APP_KEY="$APP_KEY_VALUE"
  fi

  if [ -n "$DB_HOST" ]; then
    echo "Aguardando o banco de dados em ${DB_HOST}:${DB_PORT:-3306}..."
    until php -r "exit(@fsockopen(getenv('DB_HOST'), getenv('DB_PORT') ?: 3306) ? 0 : 1);"; do
      sleep 2
    done
  fi

  php artisan migrate --force --no-ansi || echo "Falha ao executar migrations (continuando)."
  php artisan storage:link --no-ansi || echo "Falha ao criar link de storage (pode já existir)."
  php artisan optimize --no-ansi
fi

mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

exec "$@"
