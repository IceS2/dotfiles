
#!/bin/sh

# ┌┬┐┬ ┬┌─┐┬┌─┐
# ││││ │└─┐││
# ┴ ┴└─┘└─┘┴└─┘

# author	Niraj
# github	niraj998

# ┌─┐┌─┐┌┐┌┌─┐┬┌─┐┬ ┬┬─┐┌─┐┌┬┐┬┌─┐┌┐┌┌─┐
# │  │ ││││├┤ ││ ┬│ │├┬┘├─┤ │ ││ ││││└─┐
# └─┘└─┘┘└┘└  ┴└─┘└─┘┴└─┴ ┴ ┴ ┴└─┘┘└┘└─┘

# Music Players
# this is how It'll work:
# if you uncomment more than one players this script will try to control players in reverse order. i.e. checks if strawberry is running and controls that if not then controls next available player like clementine if not looks for audacious and so on. reorder as per your liking.
# if you don't see your player you can replace name of the your player in any one of line below, just make sure that player works with playerctl

# why ?
# originally i wrote this script for status bar, and playerctl also treats browser as player so it would try to control youtube videos when I have them open. so this script just does what i want control spotify if it's open, go back to mpd if it's not. no need for mpdriss. you can find statusbar scrpit in my dotfiles repo.

# uncomment your music players below,
Control="MPD"
[ -n "$(pgrep spotify)" ] && Control="spotify"
# [ -n "$(pgrep rhythmbox)" ] && Control="rhythmbox"
# [ -n "$(pgrep audacious)" ] && Control="audacious"
# [ -n "$(pgrep clementine)" ] && Control="clementine"
# [ -n "$(pgrep strawberry)" ] && Control="strawberry"

# Saves Cover here for rofi
Cover=/tmp/cover.png
# mpd music directory (to get cover)
mpddir=~/media/Music
# if cover not found in metadata use this instead
bkpCover=~/.config/rofi/music/music.jpg
# Save Lyrics here
lyricsdir=/tmp/lyrics
# for ncmpcpp and echo lyrics
terminal=kitty
# Rofi
# roficonfig="$HOME/.config/rofi/music/config.rasi"
roficonfig="$HOME/.config/rofi/themes/spotify_player.rasi"

# ┌─┐┬  ┌─┐┬ ┬┌─┐┬─┐┌─┐┌┬┐┬    ┌─┐┌─┐┬─┐┬┌─┐┌┬┐┌─┐
# ├─┘│  ├─┤└┬┘├┤ ├┬┘│   │ │    └─┐│  ├┬┘│├─┘ │ └─┐
# ┴  ┴─┘┴ ┴ ┴ └─┘┴└─└─┘ ┴ ┴─┘  └─┘└─┘┴└─┴┴   ┴ └─┘

musicmetadata() {

player=""

albumart="$(playerctl --player=$Control metadata mpris:artUrl | sed -e 's/open.spotify.com/i.scdn.co/g')"
[ $(playerctl --player=$Control metadata mpris:artUrl) ] && curl -s "$albumart" --output $Cover || cp $bkpCover $Cover

title=$(playerctl --player=$Control metadata --format {{title}} | cut -c1-35)
title=${title:-Play Something}

artist=$(playerctl --player=$Control metadata --format {{artist}} | cut -c1-35)
artist=${artist:-Artist}

album=$(playerctl --player=$Control metadata --format {{album}} | cut -c1-35)
album=${album:-Album}

status=$(playerctl --player=$Control status)
status=${status:-Stopped}

icon=""
[ "$status" = "Playing" ] && icon=""
[ "$status" = "Paused" ] && icon=""

playlist=$(playerctl --player=$Control metadata xesam:trackNumber)
playlist=${playlist:-0}
}

## Lyrics
lyrics() {
Title=$(playerctl --player=$Control metadata --format {{title}})
Artist=$(playerctl --player=$Control metadata --format {{artist}})
URL="https://api.lyrics.ovh/v1/$Artist/$Title"
curl -s "$( echo "$URL" | sed s/" "/%20/g | sed s/"&"/%26/g | sed s/,/%2C/g | sed s/-/%2D/g)" | jq '.lyrics' > /tmp/lyrics
$terminal -e $HOME/.config/rofi/scripts/lyrics
}

## checks what player to control and runs playerctl / mpc scripts
case $Control in
	MPD)    mpdmetadata       ;;
	*)      musicmetadata     ;;
esac 2>/dev/null

## Rofi stuff
previous=""
next=""
lyrics=""


options="$player\n$previous\n$icon\n$next\n$lyrics"

rofi=$(printf $options | rofi -theme $roficonfig -dmenu -i -selected-row 2 -hover-select -markup-rows -p "<span weight=\"bold\" color=\"#B026FF\">Title - </span>$title
<span weight=\"bold\" color=\"#B026FF\">Album - </span>$album
<span weight=\"bold\" color=\"#B026FF\">Artist - </span>$artist")

## actions
case $Control in
	MPD)
	case $rofi in
		$player)	$terminal -e ncmpcpp      ;;
		$next)		mpc -q next               ;;
		$icon)		mpc -q toggle             ;;
		$previous)	mpc -q prev             ;;
		$lyrics)	mpclyrics                 ;;
	esac
	;;
	*)
	case $rofi in
		$player)	wmctrl -a $Control || $Control              ;;
		$next)		playerctl --player=$Control next            ;;
		$icon)		playerctl --player=$Control play-pause      ;;
		$previous)	playerctl --player=$Control previous      ;;
		$lyrics)	lyrics                                      ;;
	esac
esac 2>/dev/null
