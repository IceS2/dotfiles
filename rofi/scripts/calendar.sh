#!/bin/bash

# Based on rofi-calendar (https://github.com/vivien/i3blocks-contrib/tree/master/rofi-calendar)

###### Variables ######
DATEFTM="${DATEFTM:-+%b %Y}"
PREV_MONTH_TEXT="${PREV_MONTH_TEXT:-}"
NEXT_MONTH_TEXT="${NEXT_MONTH_TEXT:-}"
HOTKEYS="HOTKEYS"
NOCHANGE="NOCHANGE"
WEEK_START="${WEEK_START:-monday}"
###### Variables ######


###### Functions ######
# get current date and set today header
get_current_date() {
  CURRENT_YEAR=$(date '+%Y')
  CURRENT_MONTH=$(date '+%m')
  CURRENT_DAY=$(date '+%d')
}
# print the selected month
print_month() {
  local month=$1
  local year=$2
  calendar=$(cal --$WEEK_START $month $year \
    | tail -n +2)
  calendar=$(echo $calendar | sed -E "s/(Mo Tu We Th Fr Sa Su)(.*)/<span color=\"#26FFB0\" style=\"italic\" weight=\"bold\">\1<\/span>\2/1")

  if [[ "$month" == "$CURRENT_MONTH" && "$year" == "$CURRENT_YEAR" ]]; then
    current_day_formatted=$(echo "$CURRENT_DAY" | sed -E 's/^0*(\w+)$/\1/g')
    calendar=$(echo $calendar | sed -E "s/(^|\W)($current_day_formatted)(\W|$)/ <span color=\"#B026FF\" weight=\"bold\" underline=\"single\">\2<\/span> /g")
  fi
  echo $calendar
  IFS='-' read -r prev_month prev_year <<< "$(increment_month $month $year -1)"
  IFS='-' read -r next_month next_year <<< "$(increment_month $month $year +1)"
  prev_month_header=$(printf "%-14s" $(cal $prev_month $prev_year | sed -n '1s/^ *\(.*[^ ]\) *$/\1/p'))
  next_month_header=$(printf "%-14s" $(cal $next_month $next_year | sed -n '1s/^ *\(.*[^ ]\) *$/\1/p'))
  echo "$PREV_MONTH_TEXT $prev_month_header"
  echo "$NEXT_MONTH_TEXT $next_month_header"
}
# increment year and/or month appropriately based on month increment
increment_month() {
  # pick increment and define/update delta
  local month=$1
  local year=$2
  incr=$3
  # for non-current month
  if (( incr != 0 )); then
    # add the increment
    month=$(( 10#$month + incr ))
    # normalize month and compute year
    if (( month > 0 )); then
      (( month -= 1 ))
      (( year += month/12 ))
      (( month %= 12 ))
      (( month += 1 ))
    else
      (( year += month/12 - 1 ))
      (( month %= 12 ))
      (( month += 12 ))
    fi
    month=$(printf %02d $month)
  fi
  echo "$month-$year"
}

launch_rofi() {
  header=$1
  month_page=$2
  selected_row=$3

  selected="$(echo $2 \
    | rofi \
        -dmenu \
        -markup-rows \
        -kb-move-char-back "Control+b" \
        -kb-move-char-forward "Control+f" \
        -kb-row-up "Control+p" \
        -kb-row-down "Control+n" \
        -kb-custom-1 "Left" \
        -kb-custom-2 "Up" \
        -kb-custom-3 "Right" \
        -kb-custom-4 "Down" \
        -kb-custom-5 "c,C" \
        -kb-custom-6 "h,H" \
        -no-hover-select \
        -theme $HOME/.config/rofi/themes/calendar.rasi \
        -selected-row "$3" \
        -p "$1")"

  exit_code=$(echo $?)

  if [[ "$exit_code" =~ ("10"|"11") ]]; then
    echo "$PREV_MONTH_TEXT"
  elif [[ "$exit_code" =~ ("12"|"13") ]]; then
    echo "$NEXT_MONTH_TEXT"
  elif [[ "$exit_code" = "14" ]]; then
    echo "$CURRENT_MONTH"
  elif [[ "$exit_code" = "15" ]]; then
    echo "$HOTKEYS"
  else
    echo "$selected"
  fi
}
###### Functions ######


###### Main body ######
get_current_date
month=$CURRENT_MONTH
year=$CURRENT_YEAR
header=$(date "$DATEFTM")
INITIAL="INITIALSTATUS"
selected=$INITIAL
highlighted_row=8

get_hotkeys() {
  echo "<span weight=\"bold\" size=\"14pt\">C         </span> -> <span rise=\"3pt\" size=\"10pt\" style=\"italic\">Current   </span>"
  echo "                "
  echo "<span weight=\"bold\" size=\"14pt\">Left/Up   </span> -> <span rise=\"3pt\" size=\"10pt\" style=\"italic\">Prev Month</span>"
  echo "                "
  echo "<span weight=\"bold\" size=\"14pt\">Right/Down</span> -> <span rise=\"3pt\" size=\"10pt\" style=\"italic\">Next Month</span>"
}

while [[ "${selected}" =~ ($PREV_MONTH_TEXT|$NEXT_MONTH_TEXT|$INITIAL|$CURRENT_MONTH|$HOTKEYS|$NOCHANGE)  ]]; do
  IFS=
  month_page=$(print_month $month $year)
  selected=$(launch_rofi $header $month_page $highlighted_row)
  if [[ $selected =~ $PREV_MONTH_TEXT ]]; then
    IFS='-' read -r month year <<< "$(increment_month $month $year -1)"
    highlighted_row=7
  elif [[ $selected =~ $NEXT_MONTH_TEXT ]]; then
    IFS='-' read -r month year <<< "$(increment_month $month $year +1)"
    highlighted_row=8
  elif [[ $selected =~ $CURRENT_MONTH ]]; then
    month=$CURRENT_MONTH
    year=$CURRENT_YEAR
    highlighted_row=8
  elif [[ $selected =~ $HOTKEYS ]]; then
    hotkeys=$(get_hotkeys)
    launch_rofi "Hotkeys" $hotkeys 1
    selected=$NOCHANGE
  fi
  header=$(cal $month $year | sed -n '1s/^ *\(.*[^ ]\) *$/\1/p')
done
