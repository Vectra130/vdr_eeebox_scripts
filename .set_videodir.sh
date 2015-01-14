#!/bin/bash

# v1.3 all clients

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

check_nfs_mount() {
	avahi-browse -tlk _VDR-Streaming-Mount._tcp --parsable --resolve | grep ^"=" | awk -F";" '{ print $10 }' | sed -e /^\s*$/d -e 's/\"//g' | tr " " "\n" > /tmp/.avahi_mount
	while read avahiMount; do
		avahiPath=$(echo $avahiMount | awk -F"|" '{ print $1 }')
		avahiIp=$(echo $avahiMount | awk -F"|" '{ print $2 }')
		avahiType=$(echo $avahiMount | awk -F"|" '{ print $3 }')
		avahiDir=$(echo $avahiMount | awk -F"|" '{ print $4 }')
		if [ $(cat /etc/auto.nas | grep "${avahiPath}.*-fstype=nfs,rw,soft,timeo=5,bg,nolock,retry=0,${avahiType},rsize=4096,wsize=4096 ${avahiIp}:${avahiDir}" | wc -l) != 1 ]; then
			touch /etc/auto.nas
		fi
	done < /tmp/.avahi_mount | sort
}

set_nfs_mount() {
	[ $(pidof -xs automount | wc -l) != 0 ] && stop autofs
	[ -e /etc/auto.nas ] && rm /etc/auto.nas
	touch /etc/auto.nas
	while read avahiMount; do
		avahiPath=$(echo $avahiMount | awk -F"|" '{ print $1 }')
		avahiIp=$(echo $avahiMount | awk -F"|" '{ print $2 }')
		avahiType=$(echo $avahiMount | awk -F"|" '{ print $3 }')
		avahiDir=$(echo $avahiMount | awk -F"|" '{ print $4 }')
	echo -e "${avahiPath}\t-fstype=nfs,rw,soft,timeo=5,bg,nolock,retry=0,${avahiType},rsize=4096,wsize=4096 ${avahiIp}:${avahiDir}" >> /etc/auto.nas
	done < /tmp/.avahi_mount | sort
}

mount_vdrvideo00() {
	[ $(pidof -xs automount | wc -l) == 0 ] && start autofs
	if [ $(mount | grep vdrvideo00 | wc -l) == 0 ]; then
		if [ $(cat /etc/auto.nas | wc -l) == 1 ]; then
			mount -o bind /vdrvideo01 /vdrvideo00
		fi
		if [ $(cat /etc/auto.nas | wc -l) -gt 1 ]; then
			DIRS=$(find /vdrvideo0[1-8] -maxdepth 0 | tr '\n' ',')
			mhddfs ${DIRS%%,} /vdrvideo00 -o rw,allow_other,mlimit=10240M
		fi
	fi
}

mountDiff=$(ls -la --time-style=full-iso /etc/auto.nas)

[ ! -e /vdrvideo00 ] && mkdir /vdrvideo00
[ $(mount | grep vdrvideo00 | wc -l) != 0 ] && umount -l /vdrvideo00

#warten bis ein Mount per avahi erkannt wurde
while [ $(avahi-browse -tlk _VDR-Streaming-Mount._tcp --parsable --resolve | grep ^"=" | awk -F";" '{ print $10 }' | sed -e /^\s*$/d -e 's/\"//g' | tr " " "\n" | wc -l) == 0 ]; do
	sleep 10
done

#pruefen ob neue mounts sich geaendert haben
check_nfs_mount

#wenn ne veraenderung erkannt, dann neu mounten
if [ "$mountDiff" != "$(ls -la --time-style=full-iso /etc/auto.nas)" ]; then
	set_nfs_mount
fi

#vdrvideo00 mounten
mount_vdrvideo00

exit 0

