#!/bin/bash

MYDIR="$(dirname "$0")"

#search for wp-sites
source "${MYDIR}/wphelpfuntions.sh" 
#wp  functions for installing
source "${MYDIR}/wpfunctionsinstall.sh"

hostname="localhost"     #host in DB
wsl=0
dbuser="web"
dbpw="Hola@1234"
wpemail="oswaldo.nickel@pfennigparade.de"
dir=$(basename $PWD)
# replace "-" with "_" for database name 
dbname=${dir//[^a-zA-Z0-9]/_}
title="test${dir^^}"           #uppercase
#url="localhost/arbeit/repos/$dir"
url="arbeit.local/repos/$dir"
php=$(php -v |  head -n 1 | cut -d " " -f 2)
wp="wp"
tdir="."
ssh=0 # for git clone HTTPS(default)
#git="git@github.com-a"
gituser="pfennigparade" #github user
repo="https://github.com/${gituser}/${dir}.git"
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

####################################################
####+################################################
## MAIN

#[ $# -eq 0 ] && usage
#while [ $# -gt 0 ];do
for arg in "$@"; do
    #case $1 in
    case $arg in
        -n)
            shift
            dbname="$dbname$1"
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
        -wm|--wp-migrate-db-pro)
            wp_key_migrate
            ;;
        -w)
            shift
            wp=${1}
            ;;
        -g)
            shift
            repo=${1}
            ;;
        -pk|--private-ssh)
            ssh=1 #use my ssh key
            ;;
        --ssh)
            ssh=2 #normal
            ;;
        --debug)
            wp_debug
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
colors
os_detection 0
os_process 
sleep 1
main
wp_license_plugins "WPMDB"
wp_rights
