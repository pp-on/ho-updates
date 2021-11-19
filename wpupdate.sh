#!/bin/env bash

git=0 #use git?
dir=./
wp="wp"         #where is wp-cli 
php_string=$(php -v |  head -n 1 | cut -d " " -f 2)
#php_string=$(php -r "echo substr(phpversion(),0,3);")
#php=$(($php_string + 0)) #string to int
argSites=0 
while [ $# -gt 0 ];do
    case $1 in
        -s)
            shift
            dirs="$1"
            argSites=1
            ;;
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

#split -s dirs with , in array sites
#reference
#${var#*SubStr}  # drops substring from start of string up to first occurrence of `SubStr`
#${var##*SubStr} # drops substring from start of string up to last occurrence of `SubStr`
#${var%SubStr*}  # drops substring from last occurrence of `SubStr` to end of string
#${var%%SubStr*} # drops substring from first occurrence of `SubStr` to end of string
process_dirs(){ #split directories -> a,b,c sites[0]=a, sites[1]=b, sites[2]=c
    local dirs="$1"
    local site
    if [ ! -z "$dirs" ]; then #if something did go wrong
        while [ "$dirs" != "$site" ]; do
            site=${dirs%%,*} #first element -> dirs=a,b,c site=a  
            dirs=${dirs#"$site",} #new string w/o first element -> b,c
            while [ ! -d "$dir$site" ]; do #it has to be a correct name
                echo "$dir$site not found! Tipe in [n]ew name or [c]ontinue..."
                read a
                if [ "$a" = "n" ]; then
                    echo "----------------"
                    echo "enter new name: "
                    read site
                    echo "----------------"
                elif [ "$a" = "c" ]; then
                    site="" #first element is empty
                    break #stop loop
                else
                    continue #startover
                    #break
                fi
            done
            [ ! -z "$site" ] && sites+=("$site") #copy into array
            

        done

        for i in ${sites[@]}; do
            echo $i
        done
    fi
}

#only WP-Sites are to be processed
process_sites(){
    if [ -z "$sites" ]; then #if no folders aka Websites were pass as argument
        for site in $(ls -d $dir*/); do
            if [ -d "$site/wp-content/" ]; then
                seite=${site##"$dir"}
                echo "Found $seite"
                echo "Should it be processed? [y] "
                read answer
                echo -e "\n--------------"
                if [ "$answer" = "y" ]; then
                    #only names
                    site=${site#"$dir"}
                    site=${site%%/}
                    sites+=("$site")
                fi
            fi
        done
        for i in "${sites[@]}"; do
            echo $i
        done

    fi
}

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

#is directories (-s) known?
if [ "$argSites" -eq 0 ]; then
    process_sites 
else 
    process_dirs "$dirs"
fi

for site in "${sites[@]}"; do
    echo -e "================================\n\t$site\n================================"
    cd "$dir$site"  &>/dev/null #change to root wp of site
    sleep 1
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

