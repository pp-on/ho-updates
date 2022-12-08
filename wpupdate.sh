#!/bin/bash

MYDIR="$(dirname "$0")"

#search for wp-sites
source "${MYDIR}/wphelpfuntions.sh" 

git=0 #use git?
yes_up="" #plugins
core_up="" #wp core
dir=./
wp="wp"         #where is wp-cli 
exclude=""      #plugins mot be updated
#argSites=0 
while [ $# -gt 0 ];do
    case $1 in
        -a|--all-sites)
            process_sites
            ;;
        #-s)
            #shift
            #dirs="$1"
            #argSites=1
            #;;
        -s|--sites)
            shift
            process_dirs "$1"
            ;;
        -y|--yes-update)
            specify
            yes_up="true"
            ;;
        -c|--colors)
            colors
            ;;
        -g)
            git=1
            ;;
        -d)
            shift
            dir=$1
            ;;
        -h|--help)
            echo "wpupdate.sh [-a][-s sites][-d targetDIR][-w path/to/wp][-g]"
            exit
            ;;
        -w)
            shift
            wp=${1}
            ;;
        -x|--exclude-plugins)
            shift
            exclude="$1"
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done


function update_core () { #update wordpress, only when there is a new version
    succes=$($wp core check-update 2>/dev/null| grep Success) #0 -> ok ,1 -> err in bash
    #echo $?
    if [ -z "$succes" ]; then #1
        echo -e "\nProceed with Core Update? [y]"

        echo -e "\n--------------"
        if [ "$answer" = "y" ]; then
            $wp core update
        else
            echo -e "${Blue}Nothin to be done${Color_Off}"
        fi
    fi
}

function gitwp(){
    local plugins
    local i
    i=0
    cd wp-content  &>/dev/null
    #avoid unnecessary merges
    out "updating repository..." 1
    sleep 1
    git pull 1>/dev/null
    for plugin in $($wp plugin list --update=available --field=name); do
        old_v=$($wp plugin get $plugin --field=version)
        out "Updating $plugin" 4
        sleep 1
        $wp plugin update $plugin 1>/dev/null
        #new version
        #new_v=$(cat wp-content/plugins/$plugin/$plugin.php | grep -Po "(?<=Version: )([0-9]|\.)*(?=\s|$)")
        new_v=$(wp plugin get $plugin --field=version)
        out "version: $old_v" 4

        if [ "$old_v" != "$new_v" ]; then
            plugins[$i]="$plugin: $old_v --> $new_v"
            out "staging changes..." 2
            sleep 1
            git add -A plugins/$plugin 1>/dev/null 
            out "Writing Commit:" 2
            out "chore: update plugin ${plugins[$i]}" 4
            git commit -m "chore: update plugin ${plugins[$i]}" 1>/dev/null
            ((i++)) #increment c-style
        fi
    done
    out "Summary:" 1
    out "$i plugins updated" 2
    for p in "${!plugins[@]}"; do #get  index of array -> !
        echo "${plugins[$p]}"
        echo "------------------------------"
    done
        if [ -z "$yes_up" ]; then
            echo "Push to Github? [y]"
            read a
        #a="y"
            if [ "$a" = "y" ]; then
                git push 1>/dev/null
            else
                echo "Not pushing"
            fi
        else
            git push 1>/dev/null
        fi

    sleep 2
    cd -  &>/dev/null
}

#is directories (-s) known?
#if [ "$argSites" -eq 0 ]; then
    #process_sites 
###else 
    #process_dirs "$dirs"
#fi

for site in "${sites[@]}"; do
    echo -e "${Cyan}================================\n\t$site\n================================"
    echo "entering $dir$site"
    cd "$dir$site"  &>/dev/null #change to root wp of site
    sleep 1
    echo -e "${Green}---------------\nChecking Site\n---------------"
    # is wp-site working?
    error=$($wp core check-update ) #the result of command -> 0 ok, 1 error. string goes to variable
    #echo $?
    if [ ! -z "$error" ]; then
     #   echo "$error"
        echo -e "${Green}Everything OK"
    else
        echo -e ${Red}"$error" 
        continue
   fi
    echo -e "${Yellow}---------------\nCheck Core  Update\n---------------${Color_Off}"
    #$wp core check-update
    update_core
    echo -e "${Yellow}---------------\nCheck Plugins\n---------------${Color_Off}"

   #upd_avail=$($wp core check-update 2>/dev/null| grep Success) #0 -> ok ,1 -> err in bash
   #plugins_up=$($wp plugin list --update=available > /dev/null 2>&1) #dont print anything
   plugins_up=$($wp plugin list --update=available >/dev/null  2>&1 ) #dont print anything
   if [ -z "$plugins_up" ]; then
       echo "Nothing to be updated!"
   else
       if [ -z "$yes_up" ]; then
    $wp plugin list --update=available
           echo -e "\nAll Plugins will be updated. Proceed? [y/n]"
           read answer
           echo -e "\n--------------"
           if [ "$answer" = "y" ]; then
               #-g? -> git else update all but check -x
             [ "$git" -eq 1 ] && gitwp || [ -z "$exclude" ] && $wp plugin update --all --exclude=$exclude ||  $wp plugin update --all
           else
               echo "Nothin done"
           fi
        else
            [ "$git" -eq 1 ] && gitwp || [ -z "$exclude" ] && $wp plugin update --all --exclude=$exclude ||  $wp plugin update --all
        fi
    fi
    echo "back to $dir"
    cd -  &>/dev/null
done

