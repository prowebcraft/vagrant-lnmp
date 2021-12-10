#!/usr/bin/env bash

#== Import Common Scripts ==
source ./common.sh

#== Provision script ==
say "Provision-script user: `whoami`"

say "Restart web-stack"
service php8.0-fpm restart
service nginx restart
service mysql restart