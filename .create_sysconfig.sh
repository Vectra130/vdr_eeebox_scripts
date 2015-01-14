#!/bin/bash
# v1.1 all

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

#Einstellungen aus .config uebernehmen

CONF=/etc/vectra130/configs/sysconfig/.config
SYSCONF=/etc/vectra130/configs/sysconfig/.sysconfig

TMP="$(cat $SYSCONF | sed '/\#Aus config uebernommene/,$ d')"

echo "$TMP" > $SYSCONF
echo "" >> $SYSCONF
echo "#Aus config uebernommene Variablen" >> $SYSCONF

while read CONFIG; do
	if [ ! -z "$(echo $CONFIG | grep ^/null)" ]; then
		CONFNAME=$(echo $CONFIG | awk -F ":" '{ print $2 }')
		VALUE=$(echo $CONFIG | awk -F ":" '{ print $3 }')
		echo "        $CONFNAME=\"$VALUE\"" >> $SYSCONF
	fi
done < $CONF
