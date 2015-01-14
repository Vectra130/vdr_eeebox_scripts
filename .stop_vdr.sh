#!/bin/bash
# v1.1 all clients

. /etc/vectra130/configs/sysconfig/.sysconfig

i="vdr"
        if [ $(pidof -xs $i | wc -l) != "0" ]; then
                logger -t STOPALLMULTIMEDIA "beende .frontend.sh und $i"
		killall -q .frontend.sh
                killall -q $i &
                WAIT=0
                while true; do
                        [ $(pidof -xs $i | wc -l) == "0" ] && break
                        WAIT=$[ WAIT+1 ]
                        sleep 0.5
                done
        fi

