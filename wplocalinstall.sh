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
wsl=0
dbuser="web"
dbpw="1234"
dir=$(basename $PWD)
# replace "-" with "_" for database name 
dbname=${dir//[^a-zA-Z0-9]/_}
title="test${dir^^}"           #uppercase
url="localhost/arbeit/updates/repos/$dir"
wpuser="test"
wppw="secret"
wpemail="oswaldo.nickel@pfennigparade.de"
#php_string=$(php -v |  head -n 1 | cut -d " " -f 2)
php_string=$(php -r "echo substr(phpversion(),0,3);")
php=$(($php_string + 0)) #string to int
#if [ "$php" -gt 7 ]; then
  #  wp="php7 /home/ossi/.local/bin/wp"         #where is wp-cli 
#else
    wp="wp"
#fi
tdir="."
hardcode="git@github.com-a:pfennigparade/" #first part of ssh repo for key arbeit
repo=${hardcode}${dir}.git    #default, it can be cchanged with -c or -r
gb=0     #is Git Bash been used?    
###########################
##     functions        ###
###########################
usage() { 
    echo "USAGE: $0 [-h hostname][-u dbuser][-p dbpassword][-n dbname] -t
    title[--url location][--wpu wpuser][--wpp wppassword][-d targetDIR][-w
    path/to/wp][-c repository ][-r repo.git]"
    echo -e "-n arg:  specify the name of the database (if not, current dir
    would be used)\n[WARNING] If it exists, it will be dropped"
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
    echo "-c arg: repository to be cloned from GitHub"
    echo "-r arg: second part of git repo (first part is hardcoded)"
    echo "--wsl: use this script in wsl/windows -> mysql for creating DB,
    localhost 127.0.0.1 and url /mnt/c/xampp/htdocs/repos"
    echo --gitbash: since wsl2 does not work with git, use this torun the script
    exit
}
# check if database exists. In order to work -> user has to be in mysql grroup

check_db(){ 
    echo "#########################################"
    echo "### checking database ###"
    echo "#########################################"
    checkdb=$(mysqlshow  -h $hostname -u web -p1234 -h $hostname $dbname | grep -v Wildcard | grep -o $dbname)
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
    out "Creating Database $dbname" 1
    sleep 1
    mysql -u $dbuser -p$dbpw -h $hostname -e "DROP DATABASE IF EXISTS $dbname;
    CREATE DATABASE $dbname"
}
wp_dw (){
    out "downloading core" 1
    sleep 1
    $wp core download --locale=de_DE
}
wp_config (){
    out "creating config" 1
    f="wp-config.php"
    if [ ! -f "$f" ]; then
        echo "$Yellow there is no $f $Color_Off"
    else
        rm $f
    fi
    sleep 1
    $wp config create --dbname="$dbname" --dbuser="$dbuser" --dbpass="$dbpw" --dbhost="$hostname" 

#    if [ "$wsl" -eq 1 ]; then
 #       echo "define('WP_USE_EXT_MYSQL', false);" >> wp-config.php
  #  fi

}
#alternative for creating DB with mysql using user and name of wp config
wp_db (){
    out "Creating Database $dbname" 1
    sleep 1
    #if there's  an error, exit -> || means exit status 1
    if [ $gb -eq 1 ]; then
        out "Dropping $dbname"
        sleep 2
        winpty mysql -u "$dbuser" -p"$dbpw" -h "$hostname" -e "DROP DATABASE IF EXISTS `$dbname`;" || echo -e "$Red Error $Color_Off dropping Database"
    else
        mysql -u "$dbuser" -p"$dbpw" -h "$hostname" -e "DROP DATABASE IF EXISTS `$dbname`;" || echo -e "$Red Error $Color_Off dropping Database"
    fi
    $wp db create
    
}
wp_install (){
    out "installing wp ${title}" 1
    sleep 1
    $wp core install --url="$url" --title="$title" --admin_user="$wpuser" --admin_password="$wppw" --admin_email="$wpemail"   || echo -e "${Red}Something went wrong"
}
wp_git (){
    if [ -z "$repo" ]; then
        echo "No repository specified"
        echo "please enter one"
        read repo
    fi

    out "cloning $repo" 1
    sleep 1
    rm ./wp-content/ -rf
    if [ $wsl -eq 1 ]; then
        gh repo clone $repo wp-content
    else
        git clone $repo wp-content
    fi
    out "activating plugins" 2
    $wp plugin activate --all
}
wp_key_acf_pro (){
    out "activating acf pro" 2 
    sleep 1
    $wp eval 'acf_pro_update_license("b3JkZXJfaWQ9NzQ3MzF8dHlwZT1kZXZlbG9wZXJ8ZGF0ZT0yMDE2LTAyLTEwIDE1OjE1OjI4");'
    $wp plugin list
}
# basic htaccess for SEO
htaccess() {
    out "creating .htaccess" 2
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

wsl (){ #what?, where?
    url=$2

    out $1 1
    sleep 1
    out "PHP: $php wp: $wp" 2
    sleep 1
    out "DB: $dbname" 2
    sleep 1
    out "hostname: $hostname" 2
    sleep 1
    out "Local: $url" 2
    sleep 1
    out " Repo: $repo" 2
    sleep 2
}

out () { #what? - or #
    local line #avoid extra lines between calls
    for ((i=0; i<30; i++)); do
        if [ $2 -eq 1  ]; then
            line+='#'
        else
            line+='-'
        fi

    done
    name="##        ${1}        "
    length=${#name}
    #echo $length
    echo $line
    #echo -e "$name${line:$length}" 
    echo "${1}"
    echo $line

}
####################################################
####+################################################
## MAIN

#[ $# -eq 0 ] && usage
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
            wp=${1}
            ;;
        -c)
            shift
            repo=$1
            ;;
        -r)
            shift
            repo=${hardcode}${1}
            ;;
        --wsl)
            wsl=1
            hostname="127.0.0.1"
            repo="pfennigparade/${dir}"
            wsl "WSL2/Windows" "localhost/repos/${dir}"
            wp_dw
            wp_config
            check_db
            ;;
        --gitbash)
            gb=1
            wsl "Git Bash/Windows" "localhost/repos/${dir}"
            wp_dw
            wp_config
            wp_db
            ;;

        --help)
            usage
            exit
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done

if [ "$wsl" -eq 0 -a "$gb" -eq 0  ]; then
    wsl "$(uname -a)/Linux" $url
    wp_dw
    wp_config
    wp_db
fi
wp_install
 htaccess
wp_git
wp_key_acf_pro
