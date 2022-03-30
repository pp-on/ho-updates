#!/bin/env bash

#search for wp-sites
source ~/git/ho-updates/wphelpfuntions.sh
#wp  functions for installing
source ~/git/ho-updates/wpfunctionsinstall.sh

hostname=""     #host in DB
out_msg=0
dbuser="web"
dbpw="1234"
dir=$(basename "$PWD")
# replace "-" with "_" for database name 
dbname=${dir//[^a-zA-Z0-9]/_}
title="test${dir^^}"           #uppercase
url="localhost/arbeit/updates/repos/$dir"
wpuser="test"
wppw="secret"
wpemail="oswaldo.nickel@pfennigparade.de"
wp="wp"
ssh=0 # for git clone HTTPS(default)
#git="git@github.com-a"
gituser="pfennigparade" #github user
#repo="https://github.com/${gituser}/${dir}.git"
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
    echo "--out_msg: use this script in out_msg/windows -> mysql for creating DB,
    localhost 127.0.0.1 and url /mnt/c/xampp/htdocs/repos"
    echo --gitbash: since out_msg2 does not work with git, use this torun the script
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

out_msg (){ #what?, where? ssh
    local ssh
    ssh="$3"
    if [ $ssh -eq 1 ]; then
        git="git@github.com-a" 
    elif [ $ssh -eq 2 ]; then
        git="git@github.com" 
    else
        git="https://github.com"
    fi
    repo=${git}/${gituser}/${dir}.git    #default, it can be cchanged with -g

    url="$2"
            
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


os_process(){
    os_detection
    [[ "$cOS" == "WSL" ]]  && hostname="127.0.0.1" || hostname="localhost"
    out_msg "${cOS}/${OS}" "localhost/repos/${dir}" "$1"

}
setSSH(){
    #ssh=1
    #personal key
    #repo="git@github.com-a:${gituser}/${dir}.git"
    #[[ -n "$ssh" ]] && repo="git@github.com-a:${gituser}/${dir}.git" || repo="git@github.com:${gituser}/${dir}.git"
    echo "true"
}
main(){ #ssh

os_process "$ssh" 
sleep 1
wp_dw
wp_config $hostname
wp_db
wp_install
wp_debug
 htaccess
wp_git 
wp_key_acf_pro
}
####################################################
####+################################################
## MAIN

#[ $# -eq 0 ] && usage
while [[ "$#" -gt 0 ]];do
#for arg in "$@"; do
    case $1 in
    #case $arg in
        -u) #url
            url="$2"
            ;;
        -h) #hostname
            hostname="$2"
            ;;
        -w)
            wp="$2"
            ;;
        -g)
            repo="$2"
            ;;
        -s)
            ssh="$2"
            ;;
        -\?|--help)
            tldr
            usage
            exit
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done
colors
sleep 1
out "$ssh" 1
out "$hostname" 2
sleep 1
main
