#!/bin/bash
# v1.1 all clients

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

# avahi Info setzen das ein Frontend aktiv ist

. /etc/vectra130/configs/sysconfig/.sysconfig

case $1 in
  set)
	cat > /etc/avahi/services/frontend.service << EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
<name replace-wildcards="yes">|$2-Frontend|%h|${MACADRESS}|${IP}|</name>
<service>
       <type>_VDR-Streaming-Client._tcp</type>
</service>
</service-group>
EOF
	;;
  unset)
	[ -e /etc/avahi/services/frontend.service ] && rm /etc/avahi/services/frontend.service
	;;
esac
