#!/bin/env bash

usage (){
    echo "kickstart.sh [-u db-user][-p db-pass][-h db-host][-n db-name][-k
    KICKSTART.PHP][-f TARGET FILE]"
}
verbose=0
file=
ks="kickstart.php"
db=(localhost web 1234 dbname)
while [ $# -gt 0 ];do
    case $1 in
        -v)
            verbose=1
            ;;
        -f)
            shift
            file=$1
            ;;
        -k)
            shift
            ks=$1
            ;;
        -h)
            shift
            db[0]=$1
            ;;
        -u)
            shift
            db[1]=$1
            ;;
        -p)
            shift
            db[2]=$1
            ;;
        -n)
            shift
            db[3]=$1
            ;;
        "")
            usage
            exit
            ;;
        *)
            usage
            exit
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done
# extract jpa

#if file isn't given
if [ -z "$file" ]; then
    for jpa in $(ls *.jpa);do
        echo "$jpa -> y/n"
        read answer
        if [  "$answer" = "y" ]; then
            file="$jpa"
            break
        fi
    done
fi
