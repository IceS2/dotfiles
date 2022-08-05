#!/bin/bash
#
# Choose pulseaudio sink/source via rofi.
# Changes default sink/source and moves all streams to that device.
#
# based on:  https://gist.github.com/Nervengift/844a597104631c36513c
#

# set -euo pipefail

# readonly type="$1"
# if [[ ! "$type" =~ (sink|source) ]]; then
#     echo "error: unknown type: $type"
#     exit 1
# fi

formatlist() {
  awk "/^$type/ {s=\$1\" \"\$2;getline;gsub(/^ +/,\"\",\$0);print s\" \"\$0}" | rg -v 'Monitor' |sed -E "s/^($type \w+: )(.*)/\2<span alpha=\"1\">\1<\/span>/g"
}


select_device() {
  type=$1

  list=$(ponymix -t $type list | formatlist)
  default=$(ponymix defaults | formatlist)
  default_row=$(echo "$list" | grep -nr "$default" - | cut -f1 -d: | awk '{print $0-1}')

  if [[ "$type" == "sink" ]]; then
    placeholder='entry {placeholder: "Select Sink";}'
  else
    placeholder='entry {placeholder: "Select Source";}'
  fi

  device=$(
      echo "$list" \
        | rofi -theme $HOME/.config/rofi/themes/audio_control.rasi -theme-str  "$placeholder" -dmenu -p "pulseaudio $type:" -selected-row $default_row -markup-rows \
        | grep -Po '[0-9]+(?=:)'
  )

  [[ -z $device ]] && { return 0; }

  ponymix set-default -t $type -d $device
  case "$type" in
      sink)
          for input in $(ponymix list -t sink-input|grep -Po '[0-9]+(?=:)');do
              echo "moving stream sink $input -> $device"
              ponymix -t sink-input -d $input move $device
          done
          ;;

      source)
          for output in $(ponymix list -t source-output | rg -v '.* Peak detect.*' | rg -Po '[0-9]+(?=:)'); do
              echo "moving stream source $output <- $device"
              ponymix -t source-output -d $output move $device
          done
          ;;
  esac
}

select_device "sink"
select_device "source"
