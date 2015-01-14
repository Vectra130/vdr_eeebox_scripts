#!/bin/bash
# v1.0 eeebox

# Testen ob ein Ausgabegeraet am HDMI Anschluss erkannt wurde. Wenn nicht, warten bis es erkannt wird

. /etc/vectra130/configs/sysconfig/.sysconfig

if [[ "$(DISPLAY=:1.0 xrandr | grep HDMI | grep ' connected' | wc -l)" == "0" || "$(pidof -xs X | wc -w)" == "0" ]]; then
	logger -t HDMI "Kein Bildschirm erkannt, warte auf connect..."
	while [[ "$(DISPLAY=:1.0 xrandr | grep HDMI | grep ' connected' | wc -l)" == "0" || "$(pidof -xs X | wc -w)" == "0" ]]; do
		. $SCRIPTDIR/.startX8
		sleep 1
	done
fi
logger -t HDMI "Bildschirm an HDMI Anschluss erkannt, setze Frequenz auf ${HDMIFREQ}Hz"
$SCRIPTDIR/.reset_hdmi_port.sh
