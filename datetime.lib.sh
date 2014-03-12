#!/bin/bash

# do timezone conversions
function tz_calc {
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
function months_first_day {
  date -d "-$(date +%d) days +1 day" "$@"
}

# get the last day of the current month (a format string can be appended)
function months_last_day {
  date -d "-$(date +%d) days +1 month" "$@"
}

# check if timestring is between 2 date-times
function tbetween {
  [ $# -lt 2 ] && {
  echo "usage: tbetween <start-date> <end-date> [timestr (defaults to now)]" >&2
    return 1; }
  local s=$(date +%s)
  local strt="$1"; shift
  local endt="$1"; shift
  [ "$1" ] && s=$(date -d "$1" +%s)
  [ $(date -d "$strt" +%s) -le $s -a $(date -d "$endt" +%s) -gt $s ]
}
