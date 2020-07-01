#!/bin/bash

dir=./
wp="wp"         #where is wp-cli 
while [ $# -gt 0 ];do
    case $1 in
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wpupdate.sh [-d targetDIR][-w path/to/wp]"
            exit
            ;;
        -w)
            shift
            wp=$1
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done
#only WP-Sites are to be processed
for site in $(ls -d $dir*/); do
    if [ -d "$site/wp-content/" ]; then
        sites+=("$site")
    fi
done


          
for site in "${sites[@]}"; do
    #only names
    site=${site##"$dir"}
    site=${site%/}
    echo -e "================\n\t\t$site\n================"
    cd $site  &>/dev/null
    echo -e "---------------\nCheck Core Update\n---------------"
    $wp core check-update
    sleep 1 
    echo -e "\nProceed? [y/n]"
    read answer
    echo -e "\n--------------"
    if [ "$answer" = "y" ]; then
        $wp core update
    else
        echo "Nothin done"
    fi
    echo -e "---------------\nCheck Plugins\n---------------"
    $wp plugin list
    sleep 1 
    echo -e "\nProceed? [y/n]"
    read answer
    echo -e "\n--------------"
    if [ "$answer" = "y" ]; then
        $wp plugin update --all
    else
        echo "Nothin done"
    fi
    cd -  &>/dev/null
done

