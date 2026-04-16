#!/bin/bash
set -e

composer install --no-interaction --prefer-dist --optimize-autoloader

# Run migrations
php artisan key:generate
php artisan migrate --force
php artisan db:seed --force
php artisan storage:link

exec docker-php-entrypoint "$@"