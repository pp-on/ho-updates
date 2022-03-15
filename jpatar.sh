#!/bin/env bash
name="$1.tar.gz"
sstring="$2"
split(){
    while [ "$sstring" != "$single" ];do
        single=${single%%,*}
        sstring=${sstring#$single}
        whole
        [ ! -z "$single" ] && whole+=("$single") #copy into array
    done

       for  i in $wh
    }
