#!/bin/env bash

sql=""          #database dump to be used, instead db from website
verbose=0       #show files
dir=./
wp="wp"         #where is wp-cli 
cms="wp"        #specific for db dump
bdir="/var/www/localhost/htdocs/arbeit/backups"   #where is the backup
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
        -b)
            shift
            bdir=$1
            ;;
        -h)
            echo "wpbackup.sh [-v][-db DBDUMP][-d targetDIR][-b outputDir][-w path/to/wp]"
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

#list evt. dirs to be used for backup
function listBU () {
    #is there anything?
    count=$(ls -d $bdir/wp/* | wc -l)
    #if true, start the count and print the list
    if [ $count -gt 0 ]; then
        i=1
         for dir in $(ls -d $bdir/wp/*); do
             dir=${dir##"$bdir/wp/"} #strip before
             dir=${dir%/} #strip after
             echo "$i. $dir"
             ((i++))
             dirsb+=("$dir")
         done
         echo "Select directory number (0 to ($count -1)):"
        read r
        echo "${dirsb[$r]} Correct [y/n]"
        read answer
        echo -e "\n--------------"
        #if [ "$answer" = "y" ]; then
        #    name=${dirsb[$r]}
        #else
        #    echo ""
        #fi
    fi
}
for site in $(ls -d $dir*/); do
    if [ -d "$site/wp-content/" ]; then
        seite=${site##"$dir"}
        echo "Found $seite"
        echo "Should it be processed? [y/n] "
        ad answer
        echo -e "\n--------------"
        if [ "$answer" = "y" ]; then
            echo "Selec t dir"
            listBU
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

#sql dump
function sqldump () {
    for dump in $(ls *.sql); do
        echo "$dump"
        echo  "Should it be used?"
        read answer
        echo -e "\n--------------"
        if [ "$answer" = "y" ]; then
            sql="$dump"
        fi
    done
}

#backups folders for every site
function folders () {
    if [ ! -d "$1" ]; then
        mkdir -p $1 #parent -> for structure!!
    fi
}

datum=$(date "+%d.%m.%y-%H:%M")
i=0
#create backups dir
#folders "$bdir/backups"
for site in "${sites[@]}"; do
    #it has to be absol. dir
    backup_dir=${bdir}/backups/${names[$i]}
    folders $backup_dir
    cd $site  &>/dev/null
    #only names
      echo -e "================================\n\t${names[$i]}\n================================"
    ## is wp-site working?
    #error=$($wp core check-update ) #the result of command -> 0 ok, 1 error. string goes to variable
    ##echo $?
    #if [ ! -z "$error" ]; then
    # #   echo "$error"
    #    echo "Everything OK"
    #else
    #    echo "$error" 
    #    continue
    #fi
   sleep 1
    echo -e "---------------\nDumping Database\n---------------"
    sqldump
    #if not sql file
    if [ -z "$sql" ]; then
        echo "Exporting db with WP-CLI..."
        $wp db export "${names[$i]}-${datum}.sql" --allow-root
    else
        echo "Using $sql"
    fi
    sleep 1
    echo -e "---------------\nBacking up files\n---------------"
    if [ "$verbose" -eq 1 ]; then
        tar cvzf "$backup_dir/${names[$i]}-${datum}.tar.gz" . 
    else
        tar czf "$backup_dir/${names[$i]}-${datum}.tar.gz" . 
    fi
   #rm "${names[$i]}-${datum}.sql"    #CLEAN UP
    cd -  &>/dev/null
    ((i++))
done

