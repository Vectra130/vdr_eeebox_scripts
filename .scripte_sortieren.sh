#!/bin/bash
# v1.14 all

#nur einmal ausfuehren!
sleep 1
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0
if [ $(avahi-browse -ltk _VDR-Streaming-Bash._tcp | awk -F"|" '{ print $2 }' | grep scriptupdate | wc -l) != 0 ]; then
	echo -e "\n\nEin anderes System aktualisiert gerade seine Skripte ... breche ab"
	[ -e /etc/avahi/services/scriptupdate.service ] && rm /etc/avahi/services/scriptupdate.service
	exit 2
fi

cat > /etc/avahi/services/scriptupdate.service <<EOF
<?xml version="1.0" standalone='no'?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">


<service-group>
  <name replace-wildcards="yes">|scriptupdate|%h|</name>

  <service>
    <type>_VDR-Streaming-Bash._tcp</type>
  </service>
</service-group>
EOF

. /etc/vectra130/configs/sysconfig/.sysconfig

workDir=/nfs/vdr_files/VDR-script-versions
versionDir=$workDir/$HOSTNAME
scriptDir=/nfs/vdr_files/VDR-scripts
scriptBkpDir=$scriptDir/$HOSTNAME
if [ "$SYSTEMTYP" == "CLIENT" ]; then
	TMP="$CLIENTTYP"
	TMP2="SERVER"
	if [ $(pidof -xs automount | wc -l) == 0 ]; then
		. $SCRIPTDIR/.set_videodir
	fi
else
	TMP="$SYSTEMTYP"
	TMP2="CLIENT"
	if [ $(pidof -xs automount | wc -l) == 0 ]; then
		start autofs
	fi
fi

cd $SCRIPTDIR

writeVersions() {

tmpVers=$(cat $1 | grep -i "#.*v[0-9].[0-9].*$3" | grep -i -v "$4" | awk '{ print $2 }' | sed -e 's/^v//')
tmpVers1=$(echo $tmpVers | awk -F"." '{ print $1 }')
tmpVers2=$(echo $tmpVers | awk -F"." '{ print $2 }')
tmpVers3=$(echo $tmpVers | awk -F"." '{ print $3 }')
tmpVers=$[ tmpVers1*1000000 + tmpVers2*1000 + tmpVers3 ]
tmp=$(echo -n $1"|"; echo $tmpVers)
echo $tmp >> $versionDir/"$2"
[ ! -d ./"$2"/"$(dirname $1)" ] && mkdir -p ./"$2"/"$(dirname $1)"
[ ! -e ./"$2"/"$1" ] && ln -s ../"$1" ./"$2"/"$1"

}

copy_new_scripts() {

while read cpfile; do
	cp $scriptDir/$cpfile $SCRIPTDIR/
	cp $scriptDir/$cpfile $scriptBkpDir/
done < /tmp/.copy_changed_scripts
while read cpfile; do
	cp $scriptDir/$cpfile $SCRIPTDIR/
	cp $scriptDir/$cpfile $scriptBkpDir/
done < /tmp/.copy_new_scripts
#[ -e /etc/avahi/services/scriptupdate.service ] && rm /etc/avahi/services/scriptupdate.service
#exit 0

}

summary() {

echo -e "\n\n\n*** Zusammenfassung:"
if [ $(cat /tmp/.copy_new_scripts | wc -l) -gt 0 ]; then
	echo -e "\n\nDiese Dateien sind neu und werden kopiert:"
	while read tmp; do
		echo "     "$tmp
	done < /tmp/.copy_new_scripts
fi
if [ $(cat /tmp/.copy_changed_scripts | wc -l) -gt 0 ]; then
	echo -e "\n\nDiese Dateien haben eine neuere Version und werden kopiert:"
	while read tmp; do
	echo "     "$tmp
	done < /tmp/.copy_changed_scripts
fi
if [ $(cat /tmp/.diff_scripts | wc -l) -gt 0 ]; then
	echo -e "\n\nDiese Dateien haben die selbe Version, sind aber unterschiedlich:"
	while read tmp; do
		echo "     "$tmp
	done < /tmp/.diff_scripts
fi
echo -e "\n\n"

}

list_script_versions() {
[ ! -e $versionDir ] && mkdir -p $versionDir
[ $(ls -a $versionDir/ | wc -w) -gt 2 ] && rm $versionDir/*

for rm in all_clients all_VDR test_scripts only_$TMP; do
	[ -e ./"$rm" ] && rm -r ./"$rm"
done


echo -e "\n\tScripte werden katalogisiert ...\n"
for i in $(find ./ -type f | sed -e 's!^[.]/!!' | tr "\n" " "); do
echo -n "."
	if [ $(grep -i "# v[0-9].[0-9].*all client" $i | wc -l) == 1 ]; then
echo -n "+"
		writeVersions $i "all_clients" "all client" "NONE"
	fi
	if [ $(grep -i "# v[0-9].[0-9].*all" $i | grep -i -v client | wc -l) == 1 ]; then
echo -n "+"
		writeVersions $i "all_VDR" "all" "client"
	fi
	if [ $(grep -i "# v[0-9].[0-9].*$TMP" $i | wc -l) == 1 ]; then
echo -n "+"
		writeVersions $i only_$TMP $TMP "NONE"
	fi
	if [ $(grep -i "# v[0-9].[0-9].*test" $i | wc -l) == 1 ]; then
echo -n "+"
		writeVersions $i "test_scripts" "test" "NONE"
	fi
done

echo -e "\n----- unsortiert"
for i in $(find ./.* -maxdepth 0 -type f | sed -e 's![.]/!!' | tr "\n" " "); do
	if [[ ! -e all_clients/$i && ! -e all_VDR/$i && ! -e only_$TMP/$i && ! -e test_scripts/$i ]]; then
		echo $i
		echo $i >> $versionDir/unsortiert
	fi
done

}

save_scripts() {

[ -e $scriptBkpDir ] && rm -r $scriptBkpDir
mkdir -p $scriptBkpDir

echo -e "\n\tScripte werden gesichert ...\n"
cp -ra $SCRIPTDIR/* $scriptBkpDir/
cp -ra $SCRIPTDIR/.[a-zA-Z]* $scriptBkpDir/

}

check_versions() {

echo -e "\n\tVersionen abgleichen ...\n\n"
[ $(ls -a /tmp/ | grep ".diff" | wc -l) -gt 0 ] && rm /tmp/.*.diff
[ -e /tmp/.copy_new_scripts.tmp ] && rm /tmp/.copy_new_scripts.tmp
[ -e /tmp/.copy_changed_scripts ] && rm /tmp/.copy_changed_scripts
[ -e /tmp/.diff_scripts ] && rm /tmp/.diff_scripts
touch /tmp/.copy_changed_scripts
touch /tmp/.diff_scripts
touch /tmp/.copy_new_scripts.tmp

for otherDir in $(ls $workDir/ | grep -v "$HOSTNAME"); do
echo -en "\n[$(basename $otherDir)]"
#echo "--- otherDir: $otherDir"
	for thisFile in $(ls $versionDir/ | grep -i -v unsortiert); do
#echo "--- thisFile: $thisFile"
		while read this; do
			thisName=$(echo $this | awk -F"|" '{ print $1 }')
			thisVersion=$(echo $this | awk -F"|" '{ print $2 }')
			thisVersion=$[ thisVersion+1-1 ]
			for otherFile in $(ls $workDir/$otherDir/ | grep -v unsortiert | grep -v "$TMP2"); do
#echo "--- otherFile: $otherFile"
				while read other; do
echo -en "."
					neScript="0"
					otherName=$(echo $other | awk -F"|" '{ print $1 }')
					otherVersion=$(echo $other | awk -F"|" '{ print $2 }')
					otherVersion=$[ otherVersion+1-1 ]
					otherTestFile=$workDir/$otherDir/$otherFile/$otherName
					otherScriptFile=$scriptDir/$otherDir/$otherName
					thisTestFile=$versionDir/$thisFile/$thisName
					thisScriptFile=$scriptBkpDir/$thisName
					#identische Script Namen?
					if [ "$thisName" == "$otherName" ]; then
						#fremdes Script geeignet?
						if ( [ $(cat $otherScriptFile | grep "# v[0-9].[0-9]" | wc -w) == 3 ] && [ $(cat $otherScriptFile | grep "# v[0-9].[0-9]" | awk '{ print $3 }' | grep -i -E "(all|$TMP|test)" | wc -l) == 1 ] ) || ( [ $(cat $otherScriptFile | grep "# v[0-9].[0-9]" | wc -w) == 4 ] && [ $(cat $otherScriptFile | grep "# v[0-9].[0-9]" | awk '{ print $4 }' | grep -i "$SYSTEMTYP" | wc -l) == 1 ] ); then
							#fremdes Script neuer?
							if [ $thisVersion -lt $otherVersion ]; then
echo -en "\e[33m<\e[0m"
								diff -u $thisScriptFile $otherScriptFile > /tmp/.scripte_diff.tmp
								cp /tmp/.scripte_diff.tmp /tmp/$(echo $thisName | sed 's/\//_/g')-${otherDir}.diff
								diffPlus=$(cat /tmp/.scripte_diff.tmp | grep "^+" | grep -v "++" | wc -l)
								diffMinus=$(cat /tmp/.scripte_diff.tmp | grep "^\-" | grep -v "\-\-" | wc -l)
#								echo -e "\nGefunden:\t\t$thisName\nIst Version:\t\t$thisVersion\nVergleichVersion:\t$otherVersion\nVergleichsSystem:\t$otherDir\nKriterium:\t\t$(cat $otherScriptFile | grep '# v[0-9].[0-9]' | awk '{ print $3 " " $4 }')\nDifferenzen (+):\t$diffPlus\nDifferenzen (-):\t$diffMinus\n"
								echo "$otherDir/$otherName" >> /tmp/.copy_changed_scripts
							fi
							if [ $thisVersion -gt $otherVersion ]; then
echo -en ">"
							fi
							if [ $thisVersion == $otherVersion ]; then
echo -en "\e[32m=\e[0m"
							fi
							#fremdes Script unterschiedlich?
							if [[ "$thisName" == "$otherName" && $[ otherVersion - thisVersion ] == 0 ]]; then
								diff -u $thisScriptFile $otherScriptFile > /tmp/.scripte_diff.tmp
								diffPlus=$(cat /tmp/.scripte_diff.tmp | grep "^+" | grep -v "++" | wc -l)
								diffMinus=$(cat /tmp/.scripte_diff.tmp | grep "^\-" | grep -v "\-\-" | wc -l)
								if [ $(cat /tmp/.scripte_diff.tmp | wc -l) -gt 0 ]; then
echo -en "\e[31mx\e[0m"
#									echo -e "\n***\nDifferenz gefunden:\t$thisName\nDifferenz System:\t$otherDir\nKriterium:\t\t$(cat $otherScriptFile | grep '# v[0-9].[0-9]' | awk '{ print $3 " " $4 }')\nDifferenzen (+):\t$diffPlus\nDifferenzen (-):\t$diffMinus\n"
									cp /tmp/.scripte_diff.tmp /tmp/$(echo $thisName | sed 's/\//_/g')-${otherDir}.diff
									echo -e "$otherDir/$otherName\t +${diffPlus}/-${diffMinus}" >> /tmp/.diff_scripts
								fi
							fi
						fi
break
					fi
					#neues Script?
					if [[ ! -e $SCRIPTDIR/$otherName && $(cat /tmp/.copy_new_scripts.tmp | grep "$otherName" | wc -l) == 0 ]]; then
#echo "[ ! -e $SCRIPTDIR/$otherName ] && cat $otherScriptFile | grep '# v[0-9].[0-9]'"
						if ( [ $(cat $otherScriptFile | grep "# v[0-9].[0-9]" | wc -w) == 3 ] && [ $(cat $otherScriptFile | grep "# v[0-9].[0-9]" | awk '{ print $3 }' | grep -i -E "(all|$TMP|test)" | wc -l) == 1 ] ) || ( [ $(cat $otherScriptFile | grep "# v[0-9].[0-9]" | wc -w) == 4 ] && [ $(cat $otherScriptFile | grep "# v[0-9].[0-9]" | awk '{ print $4 }' | grep -i "$SYSTEMTYP" | wc -l) == 1 ] ); then
echo -en "\e[34m+\e[0m"
							echo "$otherDir/$otherName" >> /tmp/.copy_new_scripts.tmp
break
						fi
					fi
				done < $workDir/$otherDir/$otherFile
			done
		done < $versionDir/$thisFile
	done
done
cat /tmp/.copy_new_scripts.tmp | sort | uniq > /tmp/.copy_new_scripts
summary
copy_new_scripts

}

case $1 in

  step1)
	list_script_versions
	save_scripts
	;;
  step2)
	check_versions
	/etc/vectra130/scripts/.scripte_sortieren.sh step1 &
	;;
  list)
	list_script_versions
	;;
  save)
	save_scripts
	;;
  check)
	check_versions
	;;
  all)
	list_script_versions
	save_scripts
	check_versions
	/etc/vectra130/scripts/.scripte_sortieren.sh step1 &
	;;
  *)
	echo -e "\nusage: step1|step2|list|save|check|all"
	;;
esac
echo -e "\n"
[ -e /etc/avahi/services/scriptupdate.service ] && rm /etc/avahi/services/scriptupdate.service
exit 0
