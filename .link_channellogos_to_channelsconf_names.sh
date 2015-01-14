#!/bin/bash
# v1.1 all clients

LOGODIR=/nfs/vdrserver/channellogos
CHANCONF=/root/.vdr/channels.conf

while read name; do
	CHANNAME="$(echo $name | awk -F":" '{ print $1 }' | awk -F";" '{ print $1 }' | awk -F"," '{ print $1 }')".png
#echo "CHANNAME= $CHANNAME"
	ORIG="$LOGODIR/$CHANNAME"
	if [ ! -e "$ORIG" ]; then
#echo LOGO $LOGODIR/$CHANNAME.png
		SMALL="$(echo $CHANNAME | tr [A-Z] [a-z])"
		if [ -e "$LOGODIR/$SMALL" ]; then
#echo LINK $(echo $CHANNAME | tr [A-Z] [a-z])
			ln -sfv "$SMALL" "$LOGODIR/$CHANNAME"
		else
			echo  "Nicht gefunden $CHANNAME"
		fi
	fi
done < $CHANCONF
