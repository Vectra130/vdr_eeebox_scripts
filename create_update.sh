
#!/bin/bash
# v1.5 all

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

#echo "START --> $(date)"
. /etc/vectra130/configs/sysconfig/.sysconfig
start autofs > /dev/null

UPDATEFILES=$SCRIPTDIR/UPDATE_neu
SOURCEDIR=/
MAKEUPDATEDIR=/nfs/backup/VDR_System_Backups_fuer_Stick
NEWUPDATEDIR=/nfs/backup/VDR_System_Updates_fuer_Stick

SYSTYP="Server"
[ "$SYSTEMTYP" == "CLIENT" ] && SYSTYP="$CLIENTTYP"

#infos
info_yellow() {
echo -e "\e[33m$info\e[0m"
}
info_blue() {
echo -e "\e[34m$info\e[0m"
}
info_red() {
echo -e "\e[31m$info\e[0m"
}
info_green() {
echo -e "\e[32m$info\e[0m"
}
info_white() {
echo -e "\e[37m$info\e[0m"
}

info="\n\nErstelle Dateisystem fuer Systemupdate ... ("$(date)")"; info_blue
sync
info="\n$SYSTYP Updateversion: $VERSION"; info_yellow
TMP=$(echo $VERSION | awk -F. '{ print $3 }')
TMP2=$(echo $VERSION | awk -F. '{ print $1 }')"."$(echo $VERSION | awk -F. '{ print $2 }')"."
info="Swap-File Groesse? (MB) [$(( $(ls -l /etc/vectra130/data/swapfile | awk '{ print $5 }')/1024/1024 ))]"; info_white; read -p "--> " SWAP
if [ x$SWAP == x ]; then
	SWAP=$(( $(ls -l /etc/vectra130/data/swapfile | awk '{ print $5 }')/1024/1024 ))
fi
info="Simulation? (0/1)[0] "; info_white; read -n 1 -p "--> " SIMU
if [[ x$SIMU == x || x$SIMU != x1 ]]; then
	SIMU=0
fi
info="Testsystem? (0/1)[0] "; info_white; read -n 1 -p "--> " TESTSYSTEM
if [[ x$TESTSYSTEM == x || x$TESTSYSTEM != x1 ]]; then
	TESTSYSTEM=0
fi

echo -e "\nSwap-File=$(($SWAP*1024))\nSimulation=$SIMU\nTestsystem=$TESTSYSTEM\n"

UPDATEDIR="$MAKEUPDATEDIR/update_"$SYSTYP"_v"$VERSION
[ ! -d $UPDATEDIR/NEWFILES ] && mkdir -p $UPDATEDIR/NEWFILES

create_filesystem() {
nice -18 rsync -avlu --exclude-from=$UPDATEFILES/.create_update_excludes.rsync --numeric-ids --delete --delete-excluded --rsh="ssh" / $UPDATEDIR/NEWFILES
}

copy_update_files() {
cp $UPDATEFILES/.exec_update_backup.rsync $UPDATEDIR/
echo -n "" > /tmp/dirs
while read dirs; do
	[ -d /"$dirs" ] && echo "$dirs" >> /tmp/dirs
done < $UPDATEFILES/.exec_update_backup.rsync
while read dirs; do
	[ -d /"$dirs" ] && echo "$dirs" >> /tmp/dirs
done < $UPDATEFILES/.create_update_excludes.rsync
cat /tmp/dirs | sort | uniq > $UPDATEDIR/.exec_update_dirs.rsync
. $UPDATEFILES/.update.sh_template
}

#Ablauf

info="\n\ncreate filesystem ... ("$(date)")"; info_yellow
create_filesystem
info="copy updatefiles ... ("$(date)")"; info_yellow
copy_update_files

info="\n\nFERTIG ("$(date)")"; info_blue
exit 0
