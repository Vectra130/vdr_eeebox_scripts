#!/bin/bash
# v1.0 eeebox

#edid File mit aktuellen Monitor Daten erstellen

cp /etc/X11/xorg.conf /etc/X11/xorg.conf.bkp
[ -e /etc/X11/edid.bin ] && rm /etc/X11/edid.bin

X -verbose 6 > /tmp/xlog.txt 2>&1 &
sleep 5
kill $(pidof -x X | sed "s/ /\n/g" | sort -n | tail -1)

CONNECTED=$(cat /tmp/xlog.txt | grep ConnectedMonitor | cut -f2 -d\" | tail -1)

XCONFIG=$(nvidia-xconfig --extract-edids-from-file=/tmp/xlog.txt --extract-edids-output-file=/etc/X11/edid.bin)
MONTYP=$(echo $XCONFIG | sed -e 's/.*Wrote EDID for \"//' -e 's/\" to.*//' -e 's/ (DFP.*)//')
ERGEBNIS="$(echo $XCONFIG | grep Found | awk '{ print $2 }')"
if [ "$ERGEBNIS" == "0" ]; then
	echo "Keinen gueltigen Monitor erkannt!" > /etc/X11/edid.info
else
	echo "Monitor Typ: $MONTYP" > /etc/X11/edid.info
	echo "Monitor Verbunden an $CONNECTED" >> /etc/X11/edid.info
fi
cat /etc/X11/edid.info
exit 0
