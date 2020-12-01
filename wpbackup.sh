#!/bin/env bash

sql=""          #database dump to be used, instead db from website
verbose=0       #show files
dir=./
wp="wp"         #where is wp-cli 
cms="wp"        #specific for db dump
restore=0       #restoree site from file 
while [ $# -gt 0 ];do
    case $1 in
        -v)
            verbose=1
            ;;
        -db)
            shift
            sql=$1
            ;;
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wpbackup.sh [-v][-db DBDUMP][-d targetDIR][-w path/to/wp]"
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
        seite=${site##"$dir"}
        echo "Found $seite"
        echo "Should it be processed? [y/n] "
    cd $site  &>/dev/null
        read answer
        echo -e "\n--------------"
        if [ "$answer" = "y" ]; then
            echo "if name $site is wrong type in a new one"
            read name
            # when the name is corrected, put it inarray
            # if not, put the original one with path in the same array
            if [ ! -z "$name" ]; then
                names+=("$name")
            else
                name=${site##"$dir"}
                name=${name%/}
                names+=("$name")
            fi
            sites+=("$site") #this array must contain the path for every site 
                             # -> "cd $site"
        fi
    fi
done

root="${dir}backups"
#backups folders for every site
function folders () {
    if [ ! -d "$1" ]; then
        mkdir -p $1 #parent -> for structure!!
    fi
}

mkdir $root
datum=$(date "+%d.%m.%y")          
i=0
for site in "${sites[@]}"; do
    backup_dir=../backups/wp/${names[$i]}
    cd $site  &>/dev/null
    #only names
      echo -e "================================\n\t${names[$i]}\n================================"
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
   sleep 1
    echo -e "---------------\nDumping Database\n---------------"
    if [ -z "$sql"  ]; then
        $wp db export "${names[$i]}-${datum}.sql" --allow-root
    else
        echo "Using ${sql}"
    fi
    sleep 1
    echo -e "---------------\nBacking up files\n---------------"
    folders $backup_dir
    if [ "$verbose" -eq 1 ]; then
        tar cvzf "$backup_dir/${names[$i]}-${datum}.tar.gz" . 
    else
        tar czf "$backup_dir/${names[$i]}-${datum}.tar.gz" . 
    fi
   rm "${names[$i]}-${datum}.sql"    #CLEAN UP
    cd -  &>/dev/null
    ((i++))
done

