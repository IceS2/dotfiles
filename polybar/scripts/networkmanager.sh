#!/bin/bash

connected_interface=$(nmcli d | grep '\bconnected' | awk '{print $1}')

if [[ $connected_interface = "wlp2s0" ]]; then
	signal=$(nmcli d wifi | grep '*' | awk '{print $8}')
	echo "%{F#08A1EC}%{F-} $signal%"
elif [[ $connected_interface = "enp3s0" ]]; then
	echo "%{F#08A1EC}%{F-}"
elif [[ $connected_interface = "" ]]; then
	echo "%{F#08A1EC}%{F-}"
else
	echo "Unknown Interface"
fi

