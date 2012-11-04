#!/bin/bash
#
# This script has been adapted from the drush wrapper script + WP base install scratch
# and credits should go to the authors of those projects:
# http://drupal.org/project/drush
# https://gist.github.com/3157720

# Get the absolute path of this executable
ORIGDIR=$(pwd)
SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P) && SELF_PATH=$SELF_PATH/$(basename -- "$0")

# Resolve symlinks - this is the equivalent of "readlink -f", but also works with non-standard OS X readlink.
while [ -h "$SELF_PATH" ]; do
	# 1) cd to directory of the symlink
	# 2) cd to the directory of where the symlink points
	# 3) Get the pwd
	# 4) Append the basename
	DIR=$(dirname -- "$SELF_PATH")
	SYM=$(readlink $SELF_PATH)
	SELF_PATH=$(cd $DIR && cd $(dirname -- "$SYM") && pwd)/$(basename -- "$SYM")
done
cd "$ORIGDIR"
echo "Working in $ORIGDIR"
HTTPDOCS="$ORIGDIR/httpdocs"
CNF="$ORIGDIR/cnf"

# http://sterlinghamilton.com/2010/12/23/unix-shell-adding-color-to-your-bash-script/
# Example usage:
# echo -e ${RedF}This text will be red!${Reset}

Colors() {
	Escape="\033";
	BlackF="${Escape}[30m";   RedF="${Escape}[31m";   GreenF="${Escape}[32m"; YellowF="${Escape}[33m";  BlueF="${Escape}[34m";  Purplef="${Escape}[35m"; CyanF="${Escape}[36m";  WhiteF="${Escape}[37m"; 
	Reset="${Escape}[0m";
}
Colors;

# PROJECT init
echo -e ${YellowF}"Project name (lowercase):"${Reset}
read -e PROJECT
#cd /var/www
#mkdir $PROJECT && cd $_


# CNF
echo "Creating cnf directory..."


if [ -d $CNF ] ; then
	echo "Removing existing cnf directory...";
	rm -rf $CNF;
fi
mkdir "$CNF"
echo -e ${GreenF}"cnf dir created"${Reset}

# MySQL DB
echo -e ${YellowF}"Creating MySQL DB"${Reset}

echo -e ${YellowF}"Asking for database credentials..."${Reset}
echo "Database Name: "
read -e DBNAME
echo "Database User: "
read -e DBUSER
echo "Database Password: "
read -s DBPASS

Q1="CREATE DATABASE IF NOT EXISTS $DBNAME;"
Q2="GRANT ALL ON *.* TO '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASS';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"

echo -e ${YellowF}"Running SQL statement"${Reset}

MYSQL=`which mysql`
$MYSQL -uroot -p$DBPASS -e "$SQL"

echo -e ${GreenF}"$DBNAME DB created"${Reset}

# Settings.php && wp-config.php
#Dont need wp core config, use or own wp-config from a gist ? –quiet ?

## Write vhost.conf

echo -e ${YellowF}"Editing http.conf..."${Reset}
cd $CNF
wget -P $CNF https://gist.github.com/raw/4012197/892032910d3742b11014176d53cd966cea228e23/httpd.conf
sed -i 's/%PROJECT%/'$PROJECT'/g' ./httpd.conf
sed -i 's/%DOCROOT%/'$HTTPDOCS'/g' ./httpd.conf
echo -e ${GreenF}"http.conf edited"${Reset}

# HTTPDOCS
echo -e ${YellowF}"Creating httpdocs..."${Reset}
mkdir $HTTPDOCS
echo -e ${GreenF}"httpdocs created"${Reset}

## Get WordPress
echo -e ${YellowF}"Running wp core download in httpdocs..."${Reset}
cd "$HTTPDOCS"
wp core download
echo -e ${GreenF}"WordPress Core downloaded"${Reset}

echo -e ${YellowF}"Getting settings.php..."${Reset}
wget -P "$CNF" https://gist.github.com/raw/4009181/4dfcbf074ccc4b5f0b1c8bea1c04de2789a9ae76/settings.php

echo -e ${YellowF}"Editing settings.php..."${Reset}
cd $CNF
sed -i 's/%DBNAME%/'$DBNAME'/g' ./settings.php
sed -i 's/%DBUSER%/'$DBUSER'/g' ./settings.php
sed -i 's/%DBPASS%/'$DBPASS'/g' ./settings.php
echo -e ${GreenF}"settings edited"${Reset}

#ToDo load settings in wp-config.php meanwhile use default wp-config.php
echo -e ${YellowF}"Editing wp-config.php..."${Reset}
cd $HTTPDOCS
mv wp-config-sample.php wp-config.php 
sed -i 's/database_name_here/'$DBNAME'/g' ./wp-config.php
sed -i 's/username_here/'$DBUSER'/g' ./wp-config.php
sed -i 's/password_here/'$DBPASS'/g' ./wp-config.php
echo -e ${YellowF}"wp-config.php written"${Reset}



# Install site
echo -e ${YellowF}"Installing WordPress..."${Reset}

echo "Url: "
read -e SITEURL #could use "$PROJECT.local"
echo "Title: "
read -e SITETITLE
echo "E-mail: "
read -e SITEMAIL
echo "Site Password: "
read -s SITEPASS

echo "Install site? (y/n)"
read -e SITERUN
if [ "$SITERUN" != "y" ] ; then
  exit
fi

sed -i 's/%SITEURL%/'$SITEURL'/g' "$CNF/settings.php"

echo "wp core install..."
cd "$HTTPDOCS"
wp core install --url=$SITEURL --title=$SITETITLE --admin_email=$SITEMAIL --admin_password=$SITEPASS
echo -e ${GreenF}"wp core installed"${Reset}


## Install theme
#cd wp-content/themes && wget https://github.com/eddiemachado/bones/zipball/master && unzip master && mv eddie* $PROJECT && rm master && cd /var/www/$PROJECT
#wp theme activate bones

### Sass support

#git clone git://github.com/sanchothefat/wp-sass.git wp-content/plugins/wp-sass
#cd wp-content/plugins/wp-sass && git submodule update --init --recursive && cd /var/www/$PROJECT

### Semantic.gs

#cd wp-content/themes/bones/library/scss
#wget https://raw.github.com/twigkit/semantic.gs/master/stylesheets/scss/grid.scss -O _grid.scss
#cd "$ORIGDIR/httpdocs"

## Install plugins

#wp plugin install backwpup 
#wp plugin install google-analytics-for-wordpress
#wp plugin install w3-total-cache
#wp plugin install all-in-one-seo-pack
#wp plugin install rewrite-rules-inspector

wp plugin delete hello-dolly

# Server user and group
#chown www-data * -R
#chgrp www-data * -R