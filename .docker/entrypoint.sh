#!/bin/bash
set -e

composer install --no-interaction --prefer-dist --optimize-autoloader

# Run migrations
php artisan migrate --force
php artisan db:seed --force

exec docker-php-entrypoint "$@"