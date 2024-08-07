#!/bin/bash

MYDIR="$(dirname "$0")"

#search for wp-sites
source "${MYDIR}/wphelpfuntions.sh" 

#search for wp-sites
#source ~/git/ho-updates/wphelpfuntions.sh

wpuser="test"
wppw="secret"
wpemail="oswaldo.nickel@pfennigparade.de"

dir=./
proc_sites=0    #is -a or -s been used? if not site is pwd
wp="wp"         #where is wp-cli 
while [ $# -gt -0 ];do
#for arg in "$@"; do
#while getopts 'd:w:gh' arg; do
    #case $1 in
    case $1 in
        --git) #run subcommand
            shift
            git_wp "$1"
            ;;
        -gl|--git-pull)
            update_repo
            ;;
        -g)
            git=1
            ;;
        -d|--orignal-dir)
            shift
            dir="$1"
            ;;
        -o|--os-detection)
            os_detection 1
            ;;
        -a|--all-sites)
            process_sites
            proc_sites=1
            ;;
        -p|--print)
            print_sites
            ;;
        -c|--colors)
            colors
            ;;
        -l|--list)
            list_wp_plugins
            ;;
        -s|--sites)
            shift
            process_dirs "$1"
            proc_sites=1
            ;;
        -up|--update)
            shift
            wp_update "$1"
            ;;
        -t|--htaccess)
            htaccess
            ;;
        -x|--enable-debug)
            # Use find to search for wp-config.php starting from the given directory
    wp_config_path=$(find "$dir" -name "wp-config.php" 2>/dev/null | head -n 1)
            wp_debug "$wp_config_path"
            ;;
        -z|--hide-errors)
            wp_hide_errors
            shift
            remove_plugins "$1" "$2"
            shift
            ;;
        -f|--acf-pro-lk)
            #wp_key_acf_pro
            wp_license_plugins "ACF_PRO"
            ;;
        -m|--wp-migrate-db-pro)
            #wp_key_migrate
            wp_license_plugins "WPMDB"
            ;;
        -i|--install-plugin)
            shift
            install_plugins "$1"
            ;;
        -y|--copy-plugins)
            shift
            copy_plugins "$1"
            ;;
        -n|--new-user)
            out "creating user ${wpuser} with password ${wppw}" 1
            wp_new_user $wpuser $wppw $wpemail
            ;;
        -wu|--wp-user)
            shift
            wpuser=$1
            ;;
        -wp|--wp-password)
            shift
            wppw=$1
            ;;
        -we|--wp-email)
            shift
            wpemail=$1
            ;;
        -w|--location-wp)
            shift
            wp=$1
            ;;
        -h|--help)
            echo "wpmod.sh [--print][-p][-c][-l][-o][-s SEL,DIRS,...][--copy_plugins FROM][-d targetDIR][-w path/to/wp][-g]"
            exit
            ;;
        *)
            echo "hhh"
            exit
    esac
    shift
done #only WP-Sites are to be processed
verbose=1
#searchwp
[ $proc_sites -eq 0 ] && sites+=("$dir") #current site to array
