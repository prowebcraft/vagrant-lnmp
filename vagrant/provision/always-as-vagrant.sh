#!/usr/bin/env bash

#== Import Common Scripts ==
source ./common.sh

say "Install project dependencies"
cd /app || exit
composer --no-progress --prefer-dist install

say "Init project"
php ./init --env=Development --overwrite=n

say "Apply migrations"
php ./yii migrate --interactive=0