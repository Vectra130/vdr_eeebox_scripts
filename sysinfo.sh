#!/bin/bash

. /etc/vectra130/configs/sysconfig/.sysconfig

[ -z "$1" ] && clear
[ -z "$1" ] && echo "Sammle Informationen ..."
while true; do

VDR_CLIENT=""
VDR_LOKAL=""
DAEMONS=""
SUSPEND=""
#CPU_USAGE_IDLE=$(top -n5 -d1 | grep Cpu\(s\)\: | grep -v grep | awk '{ print $8 }' | sed -e 's/,[0-9]//')
#CPU_USAGE_IDLE=$(echo $CPU_USAGE_IDLE | sed -e 's/.* //')
#CPU_USAGE=$[ 100-CPU_USAGE_IDLE ]
#CPU_USAGE=$((100 - $CPU_USAGE_IDLE))
CPU_USAGE=$(cat /proc/stat | grep "^cpu " | awk '{ print 100 - 100/($2 + $3 + $4 + $5) * $5 }')
CPU_FREQ=$(vcgencmd measure_clock arm | cut -d "=" -f 2)
CORE_FREQ=$(vcgencmd measure_clock core | cut -d "=" -f 2)
CORE_V=$(vcgencmd measure_volts core | cut -d "=" -f 2)
CORE_T=$(vcgencmd measure_temp | cut -d "=" -f 2)
MEM_USAGE_TOTAL=$(free -m | grep Mem\: | grep -v grep | awk '{ print $2 }') 
MEM_USAGE_FREE=$(free -m | grep Mem\: | grep -v grep | awk '{ print $3 }')
#MEM_USAGE=$((($MEM_USAGE_FREE * 100 / $MEM_USAGE_TOTAL )))
MEM_USAGE=$[ MEM_USAGE_FREE*100/MEM_USAGE_TOTAL ]
#SWAP_USAGE_TOTAL=$(free -m | grep Swap\: | grep -v grep | awk '{ print $2 }')
#SWAP_USAGE_FREE=$(free -m | grep Swap\: | grep -v grep | awk '{ print $3 }')
#SWAP_USAGE=$((($SWAP_USAGE_FREE * 100 / $SWAP_USAGE_TOTAL )))
CODEC_H264=$(vcgencmd codec_enabled H264)
CODEC_MPG2=$(vcgencmd codec_enabled MPG2)
CODEC_WVC1=$(vcgencmd codec_enabled WVC1)
BROADCOM=$(vcgencmd version | grep [0-9][0-9]:[0-9][0-9]:[0-9][0-9])
UNAME=$(uname -r)
VDR_VERSION=$(/usr/bin/vdr-$VDRVERS -V -L/usr/bin/vdr-$VDRVERS 2>/dev/null | sed 's/.*(\(.*\)\/.*/\1/')
[ -e /tmp/.powersave ] && SUSPEND="*** System ist im StandBy ***"
if [ "$SERVERIP" != "127.0.0.1" ]; then
	VDR_LOKAL=" Client"
	if [ "$(echo QUIT | nc -w 1 $SERVERIP 2004 | grep '220')" != "" ];
		then DAEMONS+="\nVDR Server ($SERVERIP) laeuft"
	fi
fi
if pidof -xs vdr-$VDRVERS > /dev/null; then
	DAEMONS+="\nVDR$VDR_LOKAL (v$VDR_VERSION) laeuft"
	PLUGINS=$(svdrpsend PLUG | grep 214- | grep -v Available | sed -e 's/214-/\* /g' -e 's/[ ]-.*//g')
fi
if pidof -xs vdr-fbfe > /dev/null; then DAEMONS+="\nVDR-FBFE Frontend laeuft"; fi
if pidof -xs vompclient > /dev/null; then DAEMONS+="\nVompClient laeuft"; fi
if pidof -xs kodi.bin > /dev/null; then DAEMONS+="\nKODI laeuft"; fi
if pidof -xs lircd > /dev/null; then DAEMONS+="\nLirc laeuft"; fi
if pidof -xs irexec > /dev/null; then DAEMONS+="\nirexec laeuft"; fi
if pidof -xs lighttpd > /dev/null; then DAEMONS+="\nLightTpd laeuft"; fi
if pidof -xs smbd > /dev/null; then DAEMONS+="\nSamba laeuft"; fi
if pidof -xs .watchdog.sh > /dev/null; then DAEMONS+="\nWatchdog laeuft"; fi

[ -z "$1" ] && clear
[ -z "$1" ] && echo -e "\n#####################################################"
echo "#         RASPBERRY PI SYSTEM INFORMATIONEN         #"
[ -z "$1" ] && echo "#####################################################"

echo -e "\nCPU Frequenz       : $[ CPU_FREQ/1000000 ] Mhz"
echo "CORE Frequenz      : $[ CORE_FREQ/1000000 ] Mhz"
echo "CORE Spannung      : $CORE_V"
echo "CPU Temperatur     : $CORE_T"

echo -e "\nCPU Auslastung     : $CPU_USAGE"%
echo "Speicher Nutzung   : $MEM_USAGE"%
#echo "SWAP Nutzung       : $SWAP_USAGE"%

echo -e "\nFirmware Version   : $BROADCOM"
echo -e "Linux Kernel       : $UNAME\n"

echo -e "Codecs Status:"
echo $CODEC_H264
echo $CODEC_MPG2
echo $CODEC_WVC1

[ "$SUSPEND" ] && echo "$SUSPEND"
[ "$DAEMONS" ] && echo -e $DAEMONS

echo

[ "$PLUGINS" ] && echo "Aktivierte Plugins:"
[ "$PLUGINS" ] && echo -e "$PLUGINS"

[ ! -z "$1" ] && exit 0
sleep 1
done
