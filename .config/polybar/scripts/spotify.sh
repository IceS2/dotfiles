#!/bin/bash
play_icon=""
pause_icon=""
player_status=$(playerctl status 2> /dev/null)

if [[ $player_status != "" ]]; then
	meta_artist=$(playerctl metadata xesam:artist 2> /dev/null)
	meta_title=$(playerctl metadata xesam:title 2> /dev/null)
fi

if [[ $player_status = "Playing" ]]; then
	echo "%{F#1DB954}$play_icon%{F-} $meta_artist - $meta_title"
elif [[ $player_status = "Paused" ]]; then
	echo "%{F#1DB953}$pause_icon%{F-} $meta_artist - $meta_title"
else
	echo ""
fi
