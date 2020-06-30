#!/bin/bash

dir=./
declare -a sites

while [ $# -gt 0 ];do
    case $1 in
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wpupdate.sh [-d TARGET DIR]"
            exit
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done
for site in $(ls -d $dir*/); do
    if [ -d "$site/wp-content/" ]; then
        sites+=("$site")
    fi
done
          
for site in "${sites[@]}"; do
    echo -e "------------\n$site\n--------------"
    cd $site
    wp core check-update
    sleep 1 
    echo -e "\nProceed? [y/n]"
    read answer
    echo -e "\n--------------"
    if [ "$answer" = "y" ]; then
        wp core update
    else
        echo "Nothin done"
    fi
    sleep 1
    wp plugin list
    sleep 1 
    echo -e "\nProceed? [y/n]"
    read answer
    echo -e "\n--------------"
    if [ "$answer" = "y" ]; then
        wp plugin update --all
    else
        echo "Nothin done"
    fi
    cd -
done

