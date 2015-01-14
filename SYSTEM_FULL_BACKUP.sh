#!/bin/bash
#komplettes System Backup erstellen

if [ "$1" != "" ]; then
	BACKUPDIR=$1
else
	BACKUPDIR=/nfs/backup
fi
BACKUPFILE=$BACKUPDIR/Full_Backup_$(cat /etc/hostname)_v$(cat /etc/vectra130/VERSION)_$(date +%x).tar.gz

if [ -e $BACKUPFILE ]; then
	echo -e "\e[33m"
	read -n 1 -p "'$BACKUPFILE' existiert bereits! Datei überschreiben? (y/N) " INPUT
	echo -e "\e[0m"
	[ "$INPUT" != "y" ] && exit 0
fi

echo -e "\e[34mErstelle Backup nach: $BACKUPFILE ...\e[0m\n"

tar -zcpf $BACKUPFILE --directory=/ \
--exclude=dev --exclude=media --exclude=mnt --exclude=nfs --exclude=proc --exclude=run --exclude=srv --exclude=sys --exclude=tmp --exclude=usr/local/src --exclude=video00 --exclude=var/mail --exclude=var/log --exclude=var/cache/apt/archives --exclude=etc/vectra130/vdrserver --exclude=var/lib/mysql . > /dev/null

case $? in
 0|1)
	echo -e "\e[32m\nBackup erstellt.\nDateigröße des Backup: $(ls -lh $BACKUPFILE | awk '{ print $5 }')B\e[0m"
 	;;
 2)
	echo -e "\e[31m\nFehler beim erstellen des Backups!!!\e[0m"
	;;
esac
