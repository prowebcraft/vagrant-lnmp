#!/usr/bin/env bash

#== Import Common Scripts ==
source ./common.sh

#== Import script args ==

timezone=$(echo "$1")
extra_hostname=$(echo "$2")
xdebug_ide_key=$(echo "$3")
xdebug_port=$(echo "$4")

#== Provision script ==

say "Provision-script user: `whoami`"

export DEBIAN_FRONTEND=noninteractive

say "Configure timezone"
timedatectl set-timezone "${timezone}" --no-ask-password

say "Prepare root password for MySQL"
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password \"''\""
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password \"''\""
echo "Done!"

#say "Set Google Dns"
sudo apt install resolvconf
sudo systemctl enable --now resolvconf.service
echo "nameserver 8.8.8.8" | sudo tee /etc/resolvconf/resolv.conf.d/base > /dev/null

say "Install npm packages"
npm i -g less

say "Install Midnight Commander"
apt install -y mc

say "Configure MySQL"
cat > /root/.my.cnf << EOF
[client]
user = root
password = secret
EOF
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
mysql -uroot <<< "CREATE USER 'root'@'%' IDENTIFIED BY 'secret'"
mysql -uroot <<< "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'"
#mysql -uroot <<< "DROP USER 'root'@'localhost'"
mysql -uroot <<< "FLUSH PRIVILEGES"
echo "Done!"

say "Configure php.ini for CLI"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/8.0/cli/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/8.0/cli/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.0/cli/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/8.0/cli/php.ini

say "Configure Xdebug"
echo "xdebug.mode = debug" >> /etc/php/8.0/mods-available/xdebug.ini
echo "xdebug.discover_client_host = true" >> /etc/php/8.0/mods-available/xdebug.ini
echo "xdebug.client_port = $xdebug_port" >> /etc/php/8.0/mods-available/xdebug.ini
echo "xdebug.idekey = $xdebug_ide_key" >> /etc/php/8.0/mods-available/xdebug.ini
echo "xdebug.max_nesting_level = 512" >> /etc/php/8.0/mods-available/xdebug.ini
echo "opcache.revalidate_freq = 0" >> /etc/php/8.0/mods-available/opcache.ini

say "Configure php.ini for FPM"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/8.0/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/8.0/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.0/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.0/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/8.0/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/8.0/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/8.0/fpm/php.ini

printf "[openssl]\n" | tee -a /etc/php/8.0/fpm/php.ini
printf "openssl.cainfo = /etc/ssl/certs/ca-certificates.crt\n" | tee -a /etc/php/8.0/fpm/php.ini
printf "[curl]\n" | tee -a /etc/php/8.0/fpm/php.ini
printf "curl.cainfo = /etc/ssl/certs/ca-certificates.crt\n" | tee -a /etc/php/8.0/fpm/php.ini

say "Enabling PHP8"
update-alternatives --set php /usr/bin/php8.0
update-alternatives --set php-config /usr/bin/php-config8.0
update-alternatives --set phpize /usr/bin/phpize8.0
phpenmod -s cli xdebug

say "Configure PHP & FPM"
sed -i "s/user = www-data/user = vagrant/" /etc/php/8.0/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = vagrant/" /etc/php/8.0/fpm/pool.d/www.conf
sed -i "s/listen\.owner.*/listen.owner = vagrant/" /etc/php/8.0/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = vagrant/" /etc/php/8.0/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/8.0/fpm/pool.d/www.conf

systemctl enable php8.0-fpm
service php8.0-fpm restart

say "Configure NGINX"
sed -i 's/user www-data/user vagrant/g' /etc/nginx/nginx.conf
echo "Done!"

say "Enabling site configuration"
cp /app/vagrant/nginx/yii2_loc.conf /etc/nginx/yii2_loc.conf
cp /app/vagrant/nginx/app.conf /etc/nginx/sites-enabled/app.conf
sed -i "s/extra_hostname/$extra_hostname/g" /etc/nginx/sites-enabled/app.conf

echo "Done!"

say "Initailize databases for MySQL"
mysql -uroot <<< "CREATE DATABASE wts CHARACTER SET utf8 COLLATE utf8_general_ci"
echo "Done!"

say "Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

say "Install zsh"
sudo apt -y install zsh