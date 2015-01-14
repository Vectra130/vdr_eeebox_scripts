#!/bin/bash
# v1.3 eeebox

. /etc/vectra130/configs/sysconfig/.sysconfig
. $SCRIPTDIR/.killbootsplash

#exit 0
killall -9 -q feh
export DISPLAY=:1.0
TYPE="$2"
[ "$2" == "" ] && TYPE="png"

if [ -e $IMAGEDIR/screen_$1.$TYPE ]; then
        SHOWIMAGE=$IMAGEDIR/screen_$1.$TYPE
        SHOWINFO="Zeige User Grafik: $1"
else
        SHOWIMAGE=$VECTRADIR/sysimages/screen_$1.$TYPE
        SHOWINFO="Zeige Sys Grafik: $1"
fi
logger -t SHOWSCREENIMAGE $SHOWINFO
feh -F $SHOWIMAGE &>/dev/null

exit 0
