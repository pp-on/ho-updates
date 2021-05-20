#!/bin/env bash

# Reset
Color_Off="\[\033[0m\]"       # Text Reset

# Regular Colors
Black="\[\033[0;30m\]"        # Black
Red="\[\033[0;31m\]"          # Red
Green="\[\033[0;32m\]"        # Green
Yellow="\[\033[0;33m\]"       # Yellow
Blue="\[\033[0;34m\]"         # Blue
Purple="\[\033[0;35m\]"       # Purple
Cyan="\[\033[0;36m\]"         # Cyan
White="\[\033[0;37m\]"        # White

hostname="localhost"     #host in DB
dbname=""                #must
dbuser="web"
dbpw="1234"
title=""
dir=$(bas ename $PWD)
url="localhost/arbeit/updates/$dir"
wpuser="test"
wppw="secret"
wpemail="oswaldo.nickel@pfennigparade.de"
wp="wp"         #where is wp-cli 
tdir="."
    
###########################
##     functions        ###
###########################
usage() { 
    echo "USAGE: $0 [-h hostname][-u dbuser][-p dbpassword][-n dbname][-t
    title][--url location][--wpu wpuser][--wpp wppassword][-d targetDIR][-w
    path/to/wp]"
    echo -e "-n arg: [MANDATORY] specify the name of the database\n[WARNING] If it exists, it
    will be dropped"
    echo "-h arg: specify the hostname for the database (default localhost)"
    echo "-u arg: specify the user for the DBMS (default web)"
    echo "-p arg: specify the password for the DBMS (default 1234)"
    echo "-t arg: [MANDATORY] set the the title for the Website"
    echo "--url arg: set the location/address inn the webserver (defauLt
    localhost/arbeit/updates/CURRENT_DIR)"
    echo "--wpu|--wpp arg: user credentials for this WP site (default "test",
    "secret")"
    echo "--wpe arg: specify the email address for this WP site (default
    oswaldo.nickel@pfennigparade.de)"
    echo "-d arg: use this director for the installation (default CURRENT_DIR)"
    echo "-w arg: specify location of wp-cli"
}
# check if database exists. In order to work -> user has to be in mysql grroup

check_db(){ 
    echo "#########################"
    echo "### checking database ###"
    checkdb=$(mysqlshow -u web -p1234 $dbname | grep -v Wildcard | grep -o $dbname)
    if [ -z "$checkdb" ]; then
        echo "found no Database with the name $dbname. Moving on"
        create_db
    else
        echo "found Database $dbname"
        echo "By continuiing all its data will be erased"
        echo "Proceed [y/n]"
        read a
        if [ "$a" = "y" ]; then
            create_db
        elif [ "$a" = "n" ]; then
            echo "aborting..."
            exit
        fi
    fi

}
create_db (){
    echo ""
    echo "##########################\n# Creating Database $dbname\n"
    mysql -u $dbuser -p$dbpw -h $hostname -e "DROP DATABASE IF EXISTS $dbname;
    CREATE DATABASE $dbname"
}
wp_dw (){
    echo "#########################"
    echo "### downloading core  ###"
    sleep 1
    $wp core download --locale=de_DE
}
wp_config (){
    echo "#########################"
    echo "###  creating config  ###"
    f="wp-config.php"
    if [ ! -f "$f" ]; then
        echo "there is no $f"
    else
        rm $f
    fi
    sleep 1
    $wp config create --dbname="$dbname" --dbuser="$dbuser" --dbpass="$dbpw" 
}
#alternative for creating DB with mysql using user and name of wp config
wp_db (){
    echo "#########################"
    echo "### creating database ###"
    sleep 1
    #if there's  an error, exit -> || means exit status 1
    mysql -u "$dbuser" -p"$dbpw" -h "$hostname" -e "DROP DATABASE IF EXISTS $dbname;" || echo -e "$Red Error dropping Database"
    $wp db create
    
}
wp_install (){
    echo "#########################"
    echo "### installing wp     ###"
    sleep 1
    wp core install --url="$url" --title="$title" --admin_user="$wpuser" --admin_password="$wppw" --admin_email="$wpemail"   || echo -e "${Red}Something went wrong"
}
wp_git (){
    if [ -z "$repo" ]; then
        echo "No repository specified"
        echo "please enter one"
        read repo
    fi

    rm ./wp-content/ -rf
    git clone $repo wp-content
    echo "activating plugins"
    $wp plugin activate --all
    $wp plugin list
}
# basic htaccess for SEO
htaccess() {

cat  << EOF > .htaccess
# BEGIN WordPress
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
# END WordPress
EOF

}
####################################################
####+################################################
## MAIN

[ $# -eq 0 ] && usage
while [ $# -gt 0 ];do
    case $1 in
        -n)
            shift
            dbname=$1
            ;;
        -u)
            shift
            dbuser=$1
            ;;
        -p)
            shift
            dbpw=$1
            ;;
        -t)
             shift
             title=$1
             ;;
        --url)
            shift
             url=$1
            ;;
        --wpu)
            shift
            wpuser=$1
            ;;
        --wpp)
            shift
            wppw=$1
            ;;
        --wpe)
            shift
            wpemail=$1
            ;;
        -d)
            shift
            tdir=$1
            ;;
        -h)
            shift
            hostname=$1
            ;;
        -w)
            shift
            wp=$1
            ;;
        -c)
            shift
            repo=$1
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done

wp_dw
wp_config
wp_db
wp_install
 htaccess
wp_git
