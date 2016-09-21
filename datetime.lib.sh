#!/bin/bash

# do timezone conversions
tz_calc() {
  if [ $# -lt 1 ]; then
    echo "Usage: tz_calc <tz-dest> [<tm-str>] [<tz-orig>]" >&2
    return 1
  fi
  local tz_dest="$1"; shift
  local tm="${1:-now}"; shift
  local tz_orig="${1:-:/etc/localtime}"; shift
  # Override timezone in tm-str if we're specifying origin
  [ "$tz_orig" != ':/etc/localtime' ] && tm=$(date -d "$tm" "+%F %T")
   TZ="$tz_dest" date -d "$(TZ="$tz_orig" date -d "$tm" "+%F %T %z")" "$@"
}

# get the first day of the current month (a format string can be appended)
months_first_day() {
  date -d "-$(date +%d) days +1 day" "$@"
}

# get the last day of the current month (a format string can be appended)
months_last_day() {
  date -d "-$(date +%d) days +1 month" "$@"
}

# check if timestring is between 2 date-times
tbetween() {
  [ $# -lt 2 ] && {
  echo "usage: tbetween <start-date> <end-date> [timestr (defaults to now)]" >&2
    return 1; }
  local s=$(date +%s)
  local strt="$1"; shift
  local endt="$1"; shift
  [ "$1" ] && s=$(date -d "$1" +%s)
  [ $(date -d "$strt" +%s) -le $s -a $(date -d "$endt" +%s) -gt $s ]
}

tz() {
  local tm="${1:-now}"
  echo "raw time --- $(date -d "$tm" "+%F %T")"
  echo
  echo "** London"
  echo "   mpk  -> [$(tz_calc US/Pacific "$tm" Europe/London)]"
  echo "   nyc  -> [$(tz_calc America/New_York "$tm" Europe/London)]"
  echo "   arg  -> [$(tz_calc America/Buenos_Aires "$tm" Europe/London)]"
  echo
  echo "** MPK"
  echo "   london -> [$(tz_calc Europe/London "$tm" US/Pacific)]"
  echo "   nyc    -> [$(tz_calc America/New_York "$tm" US/Pacific)]"
  echo "   arg    -> [$(tz_calc America/Buenos_Aires "$tm" US/Pacific)]"
  echo
  echo "** NYC"
  echo "   london -> [$(tz_calc Europe/London "$tm" America/New_York)]"
  echo "   mpk    -> [$(tz_calc US/Pacific "$tm" America/New_York)]"
  echo "   arg    -> [$(tz_calc America/Buenos_Aires "$tm" America/New_York)]"
}
