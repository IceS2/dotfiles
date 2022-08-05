#!/bin/bash

## Based on Aditya Shakya rofi repo
## Github  : https://github.com/adi1090x/rofi

dir="$HOME/.config/rofi/themes"
uptime=$(uptime -p | sed -e 's/up //g')

rofi_command="rofi -theme $dir/powermenu.rasi"

# Options
shutdown=""
reboot=""
lock=""
logout=""

yes="<span foreground=\"#75FF26\"></span>"
no="<span foreground=\"#FF4326\"></span>"

# Confirmation
confirm_exit() {
        options="$yes\n$no"
        echo "$(echo -e "$options" | rofi -theme $dir/confirm.rasi -p "Are you Sure?" -markup-rows -dmenu -selected-row 0)"
}

# Run polybar hook
polybar_hook() {
        polybar-msg action "#powermenu.hook.$1"
}

polybar_hook 1
# Variable passed to rofi
options="$lock\n$logout\n$reboot\n$shutdown"

chosen="$(echo -e "$options" | rofi -theme $dir/powermenu.rasi -p "Uptime: $uptime" -dmenu -selected-row 0)"
case $chosen in
    $shutdown)
		ans=$(confirm_exit &)
		if [[ $ans == "$yes" ]]; then
			systemctl poweroff
		elif [[ $ans == "$no" || -z $ans ]]; then
                        polybar_hook 0
			exit 0
        else
                        # TODO: Implement sending message
			echo "Send Message about error"
                        exit 1
        fi
        ;;
    $reboot)
		ans=$(confirm_exit &)
		if [[ $ans == "$yes" ]]; then
			systemctl reboot
		elif [[ $ans == "$no" || -z $ans ]]; then
                        polybar_hook 0
			exit 0
        else
                        # TODO: Implement sending message
			echo "Send Message about error"
                        exit 1
        fi
        ;;
    $lock)
                $HOME/.config/scripts/lock.sh
        ;;
    $logout)
		ans=$(confirm_exit &)
		if [[ $ans == "$yes" ]]; then
			if [[ "$DESKTOP_SESSION" == "Openbox" ]]; then
				openbox --exit
			elif [[ "$DESKTOP_SESSION" == "bspwm" ]]; then
				bspc quit
			elif [[ "$DESKTOP_SESSION" == "i3" ]]; then
				i3-msg exit
			fi
		elif [[ $ans == "$no" || -z $ans ]]; then
                        polybar_hook 0
			exit 0
        else
                        # TODO: Implement sending message
			echo "Send Message about error"
                        exit 1
        fi
        ;;
esac
polybar_hook 0
