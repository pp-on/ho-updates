#!/bin/env bash

git=0 #use git?
dir=./
wp="wp"         #where is wp-cli 
php_string=$(php -v |  head -n 1 | cut -d " " -f 2)
#php_string=$(php -r "echo substr(phpversion(),0,3);")
php=$(($php_string + 0)) #string to int
while [ $# -gt 0 ];do
    case $1 in
        -g)
            git=1
            ;;
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wpupdate.sh [-d targetDIR][-w path/to/wp][-g]"
            exit
            ;;
        -w)
            shift
            wp=${1}
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done
#only WP-Sites are to be processed
for site in $(ls -d $dir*/); do
    if [ -d "$site/wp-content/" ]; then
        seite=${site##"$dir"}
        echo "Found $seite"
        echo "Should it be processed? [y] "
        read answer
        echo -e "\n--------------"
        if [ "$answer" = "y" ]; then
            sites+=("$site")
        fi
    fi
done

function update_core () { #update wordpress, only when there is a new version
    succes=$($wp core check-update 2>/dev/null| grep Success) #0 -> ok ,1 -> err in bash
    #echo $?
    if [ -z "$succes" ]; then #1
        echo -e "\nProceed with Core Update? [y]"
        read answer
        echo -e "\n--------------"
        if [ "$answer" = "y" ]; then
            $wp core update
        else
            echo "Nothin to be done"
        fi
    fi
}

function gitwp(){
    local plugins
    i=0
    cd wp-content  &>/dev/null
    #avoid unnecessary merges
    echo "=============================="
    echo "updating repository..."
    sleep 1
    git pull 1>/dev/null
    for plugin in $($wp plugin list --update=available --field=name); do
        old_v=$($wp plugin get $plugin --field=version)
        echo "=============================="
        echo "Updating $plugin"
        sleep 1
        $wp plugin update $plugin 1>/dev/null
        #new version
        #new_v=$(cat wp-content/plugins/$plugin/$plugin.php | grep -Po "(?<=Version: )([0-9]|\.)*(?=\s|$)")
        new_v=$(wp plugin get $plugin --field=version)
        echo "version: $new_v"

        plugins[$i]="$plugin: $old_v --> $new_v"
        echo "------------------------------"
        echo "staging changes..."
        sleep 1
        git add -A plugins/$plugin 1>/dev/null 
        echo "------------------------------"
        echo "Writing Commit:"
        echo "chore: update plugin ${plugins[$i]}"
        echo "------------------------------"
        git commit -m "chore: update plugin ${plugins[$i]}" 1>/dev/null
        ((i++)) #increment c-style
    done
    echo "=============================="
    echo "Summary:"
    echo "=============================="
    echo "$i plugins updated"
    echo "------------------------------"
    for p in "${!plugins[@]}"; do #get  index of array -> !
        echo "${plugins[$p]}"
        echo "------------------------------"
    done
        echo "Push to Github? [y]"
        read a
        if [ "$a" = "y" ]; then
            git push 1>/dev/null
        else
            echo "Not pushing"
        fi
    sleep 2
    cd -  &>/dev/null
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
    $wp plugin list --update=available 
    sleep 1 
    echo -e "\nAll Plugins will be updated. Proceed? [y/n]"
    read answer
    echo -e "\n--------------"
    if [ "$answer" = "y" ]; then
        if [ "$git" -eq 1 ]; then
            gitwp
        else
            $wp plugin update --all
        fi
    else
        echo "Nothin done"
    fi
    cd -  &>/dev/null
done

