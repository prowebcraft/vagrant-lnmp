#!/usr/bin/env bash

#== Import Common Scripts ==
source /app/vendor/prowebcraft/vagrant-lnmp/vagrant/provision/common.sh

#== Import script args ==
github_token=$(echo "$1")

#== Provision script ==

say "Provision-script user: `whoami`"

say "Configure composer"
composer config --global github-oauth.github.com ${github_token}
echo "Done!"

say "Install project dependencies"
cd /app || exit
composer --no-progress --prefer-dist install

say "Create bash-alias 'app' for vagrant user"
echo 'alias app="cd /app"' | tee ~/.bash_aliases

say "Enabling colorized prompt for guest console"
sed -i "s/#force_color_prompt=yes/force_color_prompt=yes/" /home/vagrant/.bashrc

say "Installing oh-my-zsh and change shell"
echo 'vagrant' | chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git config --global --add oh-my-zsh.hide-status 1
git config --global status.showuntrackedfiles no
git config --global --add oh-my-zsh.hide-dirty 1

say "Auto navigate to /app at login"
echo 'cd /app' | tee -a ~/.zshrc

say "Config MySQL Client"
cat > ~/.my.cnf << EOF
[client]
user = root
EOF