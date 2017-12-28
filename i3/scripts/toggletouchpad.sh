#!/bin/bash
touchpad="DELL0782:00 06CB:7E92 Touchpad"
enabled=$(xinput list-props "${touchpad}" | grep -oP 'Device Enabled \(\d*\):.+(\d)' | awk '{print $4}')
if [ ${enabled} == 1 ]
then
	xinput --disable "DELL0782:00 06CB:7E92 Touchpad"
else
	xinput --enable "DELL0782:00 06CB:7E92 Touchpad"
fi
