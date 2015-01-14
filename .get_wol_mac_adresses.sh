#!/bin/bash
# v1.1 all

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

tmpFile=/tmp/.get_wol_mac_adresses.tmp
adressFile=/etc/vectra130/configs/userconfig/wol-adressen

avahi-browse -tlk _workstation._tcp | grep "\[[0-9a-Z][0-9a-Z]:[0-9a-Z][0-9a-Z]:[0-9a-Z][0-9a-Z]:[0-9a-Z][0-9a-Z]:[0-9a-Z][0-9a-Z]:[0-9a-Z][0-9a-Z]\]" | awk '{ print $4 " " $5 }'  | sed -e 's/\[//' -e 's/\]//' > $tmpFile

while read adresses; do
	if [ $(cat $adressFile | grep ^"$(echo $adresses | awk '{ print $1 }') " | wc -l) == 1 ]; then
		sed -i -e "s/^$(echo $adresses | awk '{ print $1 }').*/$adresses AVAHI/" $adressFile
	else
		echo $adresses >> $adressFile
	fi
done < $tmpFile
