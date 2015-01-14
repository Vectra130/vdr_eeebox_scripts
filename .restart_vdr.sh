#!/bin/bash
# v1.2 all

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

. /etc/vectra130/configs/sysconfig/.sysconfig

i="vdr"
        if [ $(pidof -xs $i | wc -l) != "0" ]; then
                logger -t STOPALLMULTIMEDIA "beende $i"
                killall -q $i &
                WAIT=0
                while true; do
                        [ $(pidof -xs $i | wc -l) == "0" ] && break
                        WAIT=$[ WAIT+1 ]
                        sleep 0.5
                done
        fi

