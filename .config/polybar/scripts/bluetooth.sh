#!/bin/bash
icon_enabled=""
icon_disabled=""
status=$(systemctl is-active bluetooth.service)

if [ $status == "active" ]; then
	echo "%{F#3B5998}$icon_enabled%{F-}"
else
	echo "%{F#3B5998}$icon_disabled%{F-}"
fi
