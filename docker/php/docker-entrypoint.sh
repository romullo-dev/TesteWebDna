#!/bin/sh
set -e

cd /var/www

if [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
fi

if [ ! -f vendor/autoload.php ]; then
    composer install --no-interaction --prefer-dist --optimize-autoloader
fi

APP_KEY_LINE=$(grep '^APP_KEY=' .env 2>/dev/null || true)
if [ -z "$APP_KEY_LINE" ] || [ "${APP_KEY_LINE#APP_KEY=}" = "" ]; then
    php artisan key:generate --force
fi

exec "$@"
