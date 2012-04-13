#!/bin/bash

# do timezone conversions
function tz_calc {
  if [ $# -lt 1 ]; then
    echo "Usage: tz_calc <tz-dest> [<tm-str>] [<tz-orig>]"
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
