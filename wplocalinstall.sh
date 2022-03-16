#!/bin/env bash

# Reset
Color_Off="\e[0m"       # Text Reset

# Regular Colors
Black="\e[30m"        # Black
Red="\e[31m"          # Red
Green="\e[32m"        # Green
Yellow="\e[33m"       # Yellow
Blue="\e[34m"         # Blue
Purple="\e[35m"       # Purple
Cyan="\e[36m"         # Cyan
White="\e[37m"        # White

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
php=$(php -v |  head -n 1 | cut -d " " -f 2)
#php_string=$(php -v |  head -n 1 | cut -d " " -f 2)
#php=$(php -r "echo substr(phpversion(),0,3);")
#php=$(($php_string + 0)) #string to int
#if [ "$php" -gt 7 ]; then
  #  wp="php7 /home/ossi/.local/bin/wp"         #where is wp-cli 
#else
    wp="wp"
#fi
tdir="."
ssh=0 # for git clone HTTPS(default)
#pk_ssh=0 #my personal key (not set)
#git="git@github.com-a"
gituser="pfennigparade" #github user
gb=0     #is Git Bash been used?    
###########################
##     functions        ###
###########################
tldr() {
    echo -e $Green"This script will install a new fresh WordPress in the actual
    directory.\nIt will used its name and create a db. Then download andninstall
    WordPress. Then it will clone and activate all the
    plugins.\n${Purple}Default will be cloned with https\nRequirements ar e that Xampp (or any webserver) is set up and running. Wp cli must be installed also"$Color_Off
}
usage() { 
    echo -e "${Cyan}USAGE: $0 [-h hostname][-u dbuser][-p dbpassword][-n dbname] -t
    title[--url location][--wpu wpuser][--wpp wppassword][-d targetDIR][-w
    path/to/wp][-g repository ][--ssh user@host for github]${Color_Off}"
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
    echo "-g arg: repository to be cloned from GitHub"
    echo "--wsl: use this script in wsl/windows -> mysql for creating DB,
    localhost 127.0.0.1 and url /mnt/c/xampp/htdocs/repos"
    echo --gitbash: since wsl2 does not work with git, use this torun the script
    echo "--ssh arg: host in github to used to clone (default: git@github.com)"
    exit
}
# check if database exists. In order to work -> user has to be in mysql grroup

check_db(){ 
    echo "#########################################"
    echo "### checking database ###"
    echo "#########################################"
    checkdb=$(mysqlshow  -h $hostname -u web -p1234 -h $hostname $dbname | grep -v Wildcard | grep -o $dbname)
    if [ -z "$checkdb" ]; then
        echo -e "${Red}found no Database with the name $dbname. Moving
        on${Color_Off}"
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
        echo -e "$Yellow there is no $f $Color_Off"
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
#    if [ $gb -eq 1 ]; then
#        winpty mysql -u "$dbuser" -p"$dbpw" -h "$hostname" -e "DROP DATABASE IF EXISTS `$dbname`;" || echo -e "$Red Error $Color_Off dropping Database"
#    else
#        mysql -u "$dbuser" -p"$dbpw" -h "$hostname" -e "DROP DATABASE IF EXISTS `$dbname`;" || echo -e "$Red Error $Color_Off dropping Database"
#    fi
    out "Dropping $dbname" 2
    sleep 1
    $wp db drop --yes
    out "Creating new $dbname" 2
    sleep 1
    $wp db create
    
}
wp_install (){
    out "installing wp ${title}" 1
    sleep 1
    $wp core install --url="$url" --title="$title" --admin_user="$wpuser" --admin_password="$wppw" --admin_email="$wpemail"   || echo -e "${Red}Something went wrong${Color_Off}"
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
#activate debug
wp_debug(){
    out "adding WP DEBUG to wp-config" 2
    cat <<EOF >> wp-config.php
    // Enable WP_DEBUG mode
define( 'WP_DEBUG', true );

// Enable Debug logging to the /wp-content/debug.log file
define( 'WP_DEBUG_LOG', true );

// Disable display of errors and warnings
define( 'WP_DEBUG_DISPLAY', false );
@ini_set( 'display_errors', 0 );

// Use dev versions of core JS and CSS files (only needed if you are modifying these core files)
define( 'SCRIPT_DEBUG', true );
EOF

     
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
sleep 1
echo "Done"
}

wsl (){ #what?, where?
    if [ $ssh -eq 1 ]; then
        git="git@github.com-a" 
    elif [ $ssh -eq 2 ]; then
        git="git@github.com" 
    else
        git="https://github.com"
    fi
    repo=${git}/${gituser}/${dir}.git    #default, it can be cchanged with -g

    #personal key
#    [[ -n "$pk_ssh" ]] && repo="git@github.com-a:${gituser}/${dir}.git"
    #normal key
 #   [[ -n "$ssh" ]] && repo="git@github.com:${gituser}/${dir}.git"
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
        if [[ "$2" -eq 1 ]]; then
            line+='#'
        else
            line+='-'
        fi

    done
    name="##        ${1}        "
    length=${#name}
    #echo $length
    if [[ "$2" -eq 1 ]]; then
        line=${Yellow}${line}
   else
        line=${Cyan}${line}
   fi
    #echo -e "$name${line:$length}" 
    #echo -e ${line}\n${1}\n$line${Color_Off}
echo -e ${line}
echo -e ${1}
echo -e $line${Color_Off}

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
        -g)
            shift
            repo=${1}
            ;;
        --private-ssh)
            ssh=1 #use my ssh key
            ;;
        --ssh)
            ssh=2 #use default ssh key
            ;;
        --wsl)
            wsl=1
            hostname="127.0.0.1"
            #repo="pfennigparade/${dir}"
            wsl "WSL2/Windows" "localhost/repos/${dir}"
            wp_dw
            wp_config
            check_db
            ;;
        --gitbash)
            gb=1
            wsl "Git_Bash/Windows" "localhost/repos/${dir}"

            wp_dw
            wp_config
            wp_db
            ;;

        --help)
            tldr
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
wp_debug
 htaccess
wp_git
wp_key_acf_pro
