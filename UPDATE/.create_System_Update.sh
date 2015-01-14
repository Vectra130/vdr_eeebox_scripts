
#!/bin/bash
# v1.6 all

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

#echo "START --> $(date)"
. /etc/vectra130/configs/sysconfig/.sysconfig
start autofs > /dev/null

SOURCEDIR=/
OLDVERSIONDIR=/nfs/backup/VDR_System_Backups
NEWUPDATEDIR=/nfs/backup/VDR_System_Updates

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
info="Update benoetigt folgende Version? ("$TMP2$[ TMP-1 ]")"; info_white; read -p "--> " REQUIRED
if [[ "$REQUIRED" == "" || "$(echo $REQUIRED | grep ^[0-9][.][0-9].*[.][0-9] | wc -l)" == 0 ]]; then
	REQUIRED=$TMP2$[ TMP-1 ]
fi
info="Neue Version nach dem Update? ("$TMP2$[ TMP+1 ]")"; info_white; read -p "--> " NEWVERSION
if [[ "$NEWVERSION" == "" || "$(echo $NEWVERSION | grep ^[0-9][.][0-9].*[.][0-9] | wc -l)" == 0 ]]; then
	NEWVERSION=$TMP2$[ TMP+1 ]
fi
info="Firststart-Sequenz nach Update? (y/N)"; info_white; read -n1 -p "--> " TMP; echo
if [ "$TMP" == "y" ]; then
	SETFIRSTSTART="YES"
else
	SETFIRSTSTART="NO"
fi
DESTDIR="$OLDVERSIONDIR"/"$SYSTYP"_v"$REQUIRED"_backup_fuer_update_diff
if [ ! -d $DESTDIR ]; then
	info="\nVerzeichnis mit alter Version ($REQUIRED) nicht gefunden!!!\nBreche ab"; info_red
	exit 2
fi

UPDATEDIR=/etc/vectra130/update_"$SYSTYP"_"$VERSION"
CF_DIR=$UPDATEDIR/COPY_FILES
info="Erstelle Update in '$UPDATEDIR'"; info_yellow
FILELIST=/tmp/.rsync_filelist
FILELIST_RM=$UPDATEDIR/files_to_remove
FILELIST_CP=$FILELIST"_cp"
FILELIST_LN=$FILELIST"_ln"
FILELIST_MKDIR=$FILELIST"_mkdir"
FILELIST_DPKG=$UPDATEDIR/dpkg_list_new
FILELIST_HOLD=$UPDATEDIR/aptitude_hold

[ -e $FILELIST ] && rm $FILELIST
[ -e $FILELIST_CP ] && rm $FILELIST_CP
[ -e $FILELIST_LN ] && rm $FILELIST_LN
[ -e $FILELIST_MKDIR ] && rm $FILELIST_MKDIR
[ -d $UPDATEDIR ] && rm -r $UPDATEDIR && mkdir -p $CF_DIR
#create COPY_FILES folder
[ -e $CF_DIR ] && rm -r $CF_DIR
mkdir -p $CF_DIR

create_filelist() {
nice -18 rsync -avlu --checksum --exclude-from=$SCRIPTDIR/UPDATE/.create_update_excludes --numeric-ids --dry-run --delete --rsh="ssh" $SOURCEDIR $DESTDIR > $FILELIST
sed -i -e '/[.]\//d' -e '/sending incremental file list/d' -e '/^ /d' -e '/total size is/d' -e '/sent [0-9]* bytes/d' $FILELIST
}

sort_filelist() {
#links
cat "$FILELIST" | grep "[-]>" >> $FILELIST_LN
#deletions
cat "$FILELIST" | grep ^"deleting " | sed -e 's/^deleting //' >> $FILELIST_RM
cat "$FILELIST" | grep ^"cannot delete non-empty directory: " | sed 's/^cannot delete non-empty directory: //' >> $FILELIST_RM
#copies
cat "$FILELIST" | sed -e '/^deleting /d' -e '/^cannot delete non-empty directory/d' -e '/ -> /d' -e '/\/$/d' >> $FILELIST_CP
#folders
cat "$FILELIST" | grep "/"$ >> $FILELIST_MKDIR
#uebersicht
info="\n$(cat $FILELIST_CP | wc -l) Dateien werden kopiert"; info_yellow
info="\n$(cat $FILELIST_LN | wc -l) Dateien werden verlinkt"; info_yellow
info="\n$(cat $FILELIST_RM | wc -l) Dateien werden in die remove Liste eingetragen"; info_yellow
}

copy_files() {
cf=0
while read file; do
	if [ "x$file" != "x" ]; then
		cp -raf --parents /"$file" $CF_DIR/
		cf=$[ cf+1 ]
	fi
done < $FILELIST_CP
}

create_symlinks() {
cs=0
while read file; do
	[ -e "$(dirname $CF_DIR/$(echo $file | awk '{ print $1 }'))" ] || mkdir -p "$(dirname $CF_DIR/$(echo $file | awk '{ print $1 }'))"
	ln -sf "$(echo $file | awk '{ print $3 }')" $CF_DIR/"$(echo $file | awk '{ print $1 }')"
	cs=$[ cs+1 ]
done < $FILELIST_LN
}

create_filesystem() {
while read file; do
        [ -e "$(dirname $CF_DIR/$(echo $file | awk '{ print $1 }'))" ] || mkdir -p "$(dirname $CF_DIR/$(echo $file | awk '{ print $1 }'))"
done < $FILELIST_MKDIR
}

create_dpkg_list() {
dpkg -l > $FILELIST_DPKG
aptitude search "~ahold" > $FILELIST_HOLD
}

create_update_files() {
. $SCRIPTDIR/UPDATE/.update.sh_template
cp -a $SCRIPTDIR/UPDATE/screen_*.png $UPDATEDIR/
}

create_configs.diff() {
[ -e $UPDATEDIR/PATCHES ] || mkdir $UPDATEDIR/PATCHES
diff -ru --exclude-from=$SCRIPTDIR/UPDATE/.create_configs.diff_exclude $DESTDIR/etc/vectra130/configs /etc/vectra130/configs > $UPDATEDIR/PATCHES/configs.diff
}

create_tar() {
cd $UPDATEDIR/..
[ -e "$UPDATEDIR".tar.gz ] && rm "$UPDATEDIR".tar.gz
tar zcpf update_"$SYSTYP"_"$VERSION".tar.gz update_"$SYSTYP"_"$VERSION"
[ -d "$NEWUPDATEDIR" ] || mkdir -p "$NEWUPDATEDIR"
cp update_"$SYSTYP"_"$VERSION".tar.gz $NEWUPDATEDIR
}

create_new_backup() {
NEWBACKUPDIR="$OLDVERSIONDIR"/"$SYSTYP"_v"$VERSION"_backup_fuer_update_diff
if [ -d "$NEWBACKUPDIR" ]; then
	info="Backup-Verzeichnis $(basename $NEWBACKUPDIR) existiert bereits. Ueberschreiben? (Y/n)"; info_white
	read -n1 -p "--> " INPUT; echo
	[ "$INPUT" == "n" ] && exit 0
fi
[ -d "$NEWBACKUPDIR" ] || mkdir -p "$NEWBACKUPDIR"
nice -18 rsync -avlu --checksum --exclude-from=$SCRIPTDIR/UPDATE/.create_update_excludes --numeric-ids --delete --rsh="ssh" / $NEWBACKUPDIR > /dev/null
}

set_new_version(){
echo $NEWVERSION > /etc/vectra130/VERSION
sed -i -e 's/\(VERSION=\).*/\1'\"$NEWVERSION\"'/' $SYSCONFDIR/.sysconfig
}

#Ablauf

info="\n\ncreate filelist ... ("$(date)")"; info_yellow
create_filelist
info="sort filelist ... ("$(date)")"; info_yellow
sort_filelist
info="create filesystem ... ("$(date)")"; info_yellow
create_filesystem
info="copy files to COPY_FILES folder ... ("$(date)")"; info_yellow
copy_files
info="create symlinks ... ("$(date)")"; info_yellow
create_symlinks
info="create dpkg list ... ("$(date)")"; info_yellow
create_dpkg_list
info="create update files ... ("$(date)")"; info_yellow
create_update_files
info="create update tar archive ... ("$(date)")"; info_yellow
create_tar
info="create new backupdir ... ("$(date)")"; info_yellow
create_new_backup
info="set new version ... ("$(date)")"; info_yellow
set_new_version

echo -e "\n\n$cf Dateien kopiert"
echo -e "$cs Dateien verlinkt"
echo -e "$(cat $FILELIST_RM | wc -l) Dateien zum loeschen aufgelistet"
echo -e "Updateverzeichnis hat eine Groesse von $(du -hs $CF_DIR | awk '{ print $1 }')B"
echo -e "Update Archiv hat eine Groesse von $(ls -lh "$UPDATEDIR".tar.gz | awk '{ print $5 }')B"
info="\n\nFERTIG ("$(date)")"; info_blue
#echo "END --> $(date)"
exit 0
