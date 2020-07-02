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

function update_core () { #update wordpress, only when there is a new version
    succes=$($wp core check-update 2>/dev/null| grep Success) #0 -> ok ,1 -> err in bash
    echo $?
    if [ -z "$succes" ]; then #1
        echo -e "\nProceed with Core Update? [y/n]"
        read answer
        echo -e "\n--------------"
        if [ "$answer" = "y" ]; then
            $wp core update
        else
            echo "Nothin to be done"
        fi
    fi
}
          
for site in "${sites[@]}"; do
    #only names
    seite=${site##"$dir"}
    seite=${site%/}
    echo -e "================================\n\t$seite\n================================"
    cd $site  &>/dev/null
    echo -e "---------------\nChecking Site\n---------------"
    # is wp-site working?
    error=$($wp core check-update ) #the result of command -> 0 ok, 1 error. string goes to variable
    #echo $?
    if [ ! -z "$error" ]; then
     #   echo "$error"
        echo "Everything OK"
    else
        echo "$error" 
        continue
   fi
    echo -e "---------------\nCheck Core Update\n---------------"
    $wp core check-update
    update_core
    echo -e "---------------\nCheck Plugins\n---------------"
    $wp plugin list
    sleep 1 
    echo -e "\nAll Plugins will be updated. Proceed? [y/n]"
    read answer
    echo -e "\n--------------"
    if [ "$answer" = "y" ]; then
        $wp plugin update --all
    else
        echo "Nothin done"
    fi
    cd -  &>/dev/null
done

