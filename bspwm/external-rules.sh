#!/bin/sh
#
# external_rules_command
#
# Absolute path to the command used to retrieve rule consequences.
# The command will receive the following arguments: window ID, class
# name, instance name, and intermediate consequences. The output of
# that command must have the following format: key1=value1
# key2=value2 ...  (the valid key/value pairs are given in the
# description of the rule command).
#
#
# Rule
#    General Syntax
# 	   rule COMMANDS
#
#    Commands
# 	   -a, --add (<class_name>|*)[:(<instance_name>|*)] [-o|--one-shot]
# 	   [monitor=MONITOR_SEL|desktop=DESKTOP_SEL|node=NODE_SEL]
# 	   [state=STATE] [layer=LAYER] [split_dir=DIR] [split_ratio=RATIO]
# 	   [(hidden|sticky|private|locked|marked|center|follow|manage|focus|border)=(on|off)]
# 	   [rectangle=WxH+X+Y]
# 		   Create a new rule.
#
# 	   -r, --remove
# 	   ^<n>|head|tail|(<class_name>|*)[:(<instance_name>|*)]...
# 		   Remove the given rules.
#
# 	   -l, --list
# 		   List the rules.

border='' \
center='' \
class=$2 \
desktop='' \
focus='' \
follow='' \
hidden='' \
id=${1?} \
instance=$3 \
layer='' \
locked='' \
manage='' \
marked='' \
misc=$4 \
monitor='' \
node='' \
private='' \
rectangle='' \
split_dir='' \
split_ratio='' \
state='' \
sticky='' \
urgent=

# chromium() { desktop=^2; }
# emacs() { state=tiled; }
# firefox() { desktop=^2; }
# gimp() { follow=on; }
# gitk() { state=floating layer=normal; }
# jetbrains_idea() {
#     local name

#     read -r _ _ name <<-IN
# 		$(xprop -id "$id" _NET_WM_NAME)
# 	IN

#     case $name in
#         '"Project - '*'"')
#             split_ratio=0.25
#             split_dir=west
#             ;;
#         '"Structure - '*'"')
#             split_ratio=0.75
#             split_dir=east
#             ;;
#     esac

#     desktop=^3
# }
# libreoffice() { state=tiled layer=normal; }
# mplayer() { state=floating layer=normal; }
# mpv() { state=floating layer=normal; }
# pidgin() { desktop=^3; }
# pinentry_gtk_2() { state=floating layer=above; }
# remmina() { desktop=^4; }
# signal() { desktop=^3; }
spotify() { desktop=^10; }
# stj1() { state=floating layer=above sticky=on; }
# surf() { desktop=^2; }
# telegram_desktop() { desktop=^3; }
# thunderbird() { desktop=^6; }
# tigervnc() { desktop=^1; }
# vmrc() { desktop=^2; }
# weechat() { desktop=^3; }
# xcalc() { state=floating layer=normal; }
# xmessage() { state=floating layer=normal; }
slack() { desktop=^3; }
zoom() {
#   local name

#   read -r _ _ name <<- IN
#     $(xprop -id "$id" _NET_WM_NAME)
# IN

  # case $name in
  #   '"Zoom - Licensed Account"') desktop=^9 ;;
  #   '"Zoom Cloud Meetings"') desktop=^9 ;;
  #   '"zoom "') desktop=^9 ;;
  #   '"Zoom"') desktop=^9 ;;
  #   '"Zoom Meeting"') ;;
  #   '"Zoom Webinar"') ;;
  #   *)
  #     state=floating
  #     center=on
  #     border=off
  #     ;;
  # esac
  state=floating
  center=on
  manage=on
}

case $instance.$class in
    # *.Chromium) chromium ;;
    # *.Emacs) emacs ;;
    # *.Gimp) gimp ;;
    # *.Gitk) gitk ;;
    # *.Pidgin) pidgin ;;
    # *.Pinentry-gtk-2) pinentry_gtk_2 ;;
    # *.Signal) signal ;;
    *.Spotify) spotify ;;
    # *.TelegramDesktop) telegram_desktop ;;
    # *.TigerVNC*) tigervnc ;;
    # *.XCalc) xcalc ;;
    # *.Xmessage) xmessage ;;
    # *.[Ff]irefox) firefox ;;
    # *.mpv) mpv ;;
    # *.thunderbird) thunderbird ;;
    *.Slack) slack ;;
    *.zoom*) zoom ;;
        # if [[ -z $instance || "$instance" == "zoom "]]; then
        #   zoom
        # fi
    # *org.remmina.Remmina) remmina ;;
    # [lL]ibre[oO]ffice*) libreoffice ;;
    # jetbrains-idea.jetbrains-idea) jetbrains_idea ;;
    # stj*.st) stj1 ;;
    # vmrc.Vmrc) vmrc ;;
    # weechatw.*) weechat ;;
    .)
        case $(exec ps -p "$(exec xdo pid "$id")" -o comm= 2>/dev/null) in
            spotify) spotify ;;
            *) exit 0 ;;
        esac
        ;;
esac

printf '%s ' \
    ${border:+"border=$border"} \
    ${center:+"center=$center"} \
    ${desktop:+"desktop=$desktop"} \
    ${focus:+"focus=$focus"} \
    ${follow:+"follow=$follow"} \
    ${hidden:+"hidden=$hidden"} \
    ${layer:+"layer=$layer"} \
    ${locked:+"locked=$locked"} \
    ${manage:+"manage=$manage"} \
    ${marked:+"marked=$marked"} \
    ${monitor:+"monitor=$monitor"} \
    ${node:+"node=$node"} \
    ${private:+"private=$private"} \
    ${rectangle:+"rectangle=$rectangle"} \
    ${split_dir:+"split_dir=$split_dir"} \
    ${split_ratio:+"split_ratio=$split_ratio"} \
    ${state:+"state=$state"} \
    ${sticky:+"sticky=$sticky"} \
    ${urgent:+"urgent=$urgent"}

# vim: set ft=sh :
