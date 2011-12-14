#!/bin/bash


# kill a whole process group
function gkill {
  [ $# -eq 1 ] &&
  kill -TERM -$(ps -p $1 -o pgid --no-headers)
}


# check how many days since the data last changed
function file_data_age {
  if [ $# -lt 1 ]; then
    echo "Usage: data_age <filename> (days since the data was last modified)"
    return 1
  fi
  for f in "$@"; do
    echo $f:$(( ($(date +%s) - $(stat -c %Y "$f")) / 86400 ))
  done
}


# check if a pid is alive
function pid_is_alive {
  [ $# -eq 1 ] &&
  ps h -p $1 &> /dev/null
}


# exit a script with verbose output to stder
function die {
  echo "$0: $@" >&2
  exit 1
}


# check that only one script executes with a user chosen lock-file
# if the file exists but the pid is no longer alive the script may run
# returns 0 on success, 1 on failure
function assert_single_instance {
  if [ $# -lt 1 ]; then
    echo "Usage: assert_single_instance <lock-file> [remove-stale]"
    return 1
  fi

  local lockfile="$1"
  local remove="$2"

  if [ -f "$lockfile" ]; then
    if ps -p $(cat "$lockfile") --no-headers &> /dev/null; then
      echo "assert_single_instance: process already running" >&2
      return 1
    elif [ "$remove" != remove-stale ]; then
      echo "assert_single_instance: stale lock exists... aborting" >&2
      return 1
    else
      rm -f "$lockfile"
    fi
  fi

  if (set -o noclobber; echo $$ > "$lockfile") &>/dev/null; then
    return 0
  fi
  echo "assert_single_instance: another process got the lock" >&2
  return 1
}


# print something in color (first arg indicates color)
function color_print {
  local red='\e[0;31m'
  local RED='\e[1;31m'
  local green='\e[0;32m'
  local GREEN='\e[1;32m'
  local blue='\e[0;34m'
  local BLUE='\e[1;34m'
  local cyan='\e[0;36m'
  local CYAN='\e[1;36m'
  local NC='\e[0m'
  local color="$1"; shift
  echo -e "${!color}$@${NC}"
}
