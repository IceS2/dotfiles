#!/bin/bash

connected_interface=$(nmcli d | grep '\bconnected' | awk '{print $1}')

if [[ $connected_interface = "wlp3s0" ]]; then
	signal=$(nmcli d wifi | grep '*' | awk '{print $8}')
	echo "%{F#08A1EC}%{F-} $signal%"
elif [[ $connected_interface = "enp2s0" ]]; then
	echo "%{F#08A1EC}%{F-}"
elif [[ $connected_interface = "" ]]; then
	echo "%{F#08A1EC}%{F-}"
elif [[ $(echo "$connected_interface" | wc -l) == 2 ]]; then
	echo "%{F#08A1EC}VPN%{F-}"
else
	echo "Unknown Interface"
fi

