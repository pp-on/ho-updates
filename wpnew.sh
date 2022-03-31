#!/bin/env bash

#search for wp-sites
source ~/git/ho-updates/wphelpfuntions.sh
#wp  functions for installing
source ~/git/ho-updates/wpfunctionsinstall.sh

hostname=""     #host in DB
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
usage() { 
    echo -e "${Cyan}USAGE: $0 ${Green} ssh=1 or https=0, location of target dir(http://localhost/...) $Color_Off}"
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
    out_msg "${cOS}" "${url}" "$ssh"

}
main(){ #ssh
    os_process 
    sleep 1
    wp_dw
    wp_config 
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

[[ "$#" -eq 0 ]] && usage && exit
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
            usage
            exit
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done
colors
sleep 1
main
