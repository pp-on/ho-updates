#!/bin/env bash

DB=( "DB_NAME", "DB_USER", "DB_PASSWORD", "DB_HOST" )
idDB=( "dbname", "web", "1234", "localhost" )
wpcli=1         #when falsee, use mysql to search and replace
verbose=0       #show files
file="*.sql"
bdiir="backups/" #where the BACKUPS IS
dir="./"        #where am i
wp="wp"         #where is wp-cli 
while [ $# -gt 0 ];do
    case $1 in
        -n)
            shift
            idDB[0]=$1
            ;;
        -u)
            shift
            idDB[1]=$1
            ;;
        -p)
            shift
            idDB[2]=$1
            ;;
        --host | -l)
            shift
            idDB[3]=$1
            ;;
        -v)
            verbose=1
            ;;
        -b)
            shift
            bdir=$1
            ;;
        -c)
            wpcli=0
            ;;
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wprestore.sh [-b BackupDir][-u DBUSER[-p DBPW][--host | -l DBHOST][-n
            DBNAME][-d targetDIR][-w path/to/wp][-c][-v][-h]"
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
################################################
# Preparatins                                  #
################################################

function extract() { #dir where the backup is, trget
    for tar in $(ls $1/*.tr.gz); do
       echo "Found $tar"
        echo "Should it be processed? [y/n] "
        read answer
        echo -e "\n--------------"
        if [ "$answer" = "y" ]; then
            tar xvzf $tar
            continue
        fi

    done
}
# import db.sql
function sql() {
for sql in $(ls *.sql); do
    echo "Found $sql"
    echo "Should it be processed? [y/n] "
    read answer
    echo -e "\n--------------"
    if [ "$answer" = "y" ]; then
        if [ -z "$wpcli" ]; then
            $wp db import "$sql"
        else
            mysql -u $user -p"$pw" -h "$lh" < "$sql"
        fi
        continue
    fi
done
}

#replacements for using db
function config () {
    # replace all DB (array) with  dbname, user, pw, host  in wp_config
    for i in ${!DB[@]}; do
        # regex explanation: all characters  * between ' til ^''
        sed -i "s/'$DB[$i]',\ '[^']*'/'DB[$i]',\ 'idDB[$i]'/g" $dir/wp-config.php
    done
}

#search and replace in db
function sar () {

}
##################
# main           #
##################
cd $dir
extract  $bdir
config
sql
cd -

