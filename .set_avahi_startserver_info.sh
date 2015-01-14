#!/bin/bash
# v1.2 all clients

# avahi Info setzen das die Server suche aktiv ist

. /etc/vectra130/configs/sysconfig/.sysconfig

case $1 in
  set)
	if [ ! -e /etc/avahi/services/startserver.service ]; then
		cat > /etc/avahi/services/startserver.service << EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
<name replace-wildcards="yes">|StartServer|%h|${MACADRESS}|${IP}|</name>
<service>
       <type>_VDR-Streaming-Client._tcp</type>
</service>
</service-group>
EOF
	fi
	;;
  unset)
	[ -e /etc/avahi/services/startserver.service ] && rm /etc/avahi/services/startserver.service
	;;
esac
