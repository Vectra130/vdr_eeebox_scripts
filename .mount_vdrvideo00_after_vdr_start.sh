#!/bin/bash
# v1.1 all clients

#Script wartet bis der VDR gestartet ist und mounted anschließend das vdrvideo00 Verzeichnis

. /etc/vectra130/configs/sysconfig/.sysconfig

while [ $(pidof -xs vdr | wc -l) == 0 ]; do
	sleep 1
done

logger -t MOUNTVIDEO "Mount VDR Videoverzeichnis ..."
#mount /vdrvideo00 && logger -t MOUNTVIDEO "VDR Videoverzeichnis gemounted" \
#		  || logger -t MOUNTVIDEO "VDR Videoverzeichnis konnte nicht gemounted werden!!!"
. $SCRIPTDIR/.set_videodir

