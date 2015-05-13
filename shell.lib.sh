#!/bin/bash

# kill a whole process group
function gkill {
  [ $# -eq 1 ] &&
  kill -TERM -$(ps -p "$1" -o pgid --no-headers)
}

# check if a pid is alive
function pid_alive {
  [ $# -eq 1 ] &&
  ps h -p $1 &> /dev/null
}

# exit a script with verbose output to stder
function die {
  echo "$0: $@" >&2
  exit 1
}

# attach to existing tmux session or create a new one
function tux {
  __tmuxsesid=$USER_$(hostname -s)
  tmux -2 -u new-session -AD -s $__tmuxsesid
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
    if ps -p $(cat "$lockfile") &> /dev/null; then
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
function cprint {
  if [ $# -lt 2 ]; then
    echo "usage: cprint <color> text..." >&2
    return 1
  fi
  local red=$'\e''[0;31m'
  local RED=$'\e''[1;31m'
  local green=$'\e''[0;32m'
  local GREEN=$'\e''[1;32m'
  local yellow=$'\e''[0;33m'
  local YELLOW=$'\e''[1;33m'
  local blue=$'\e''[0;34m'
  local BLUE=$'\e''[1;34m'
  local magenta=$'\e''[0;35m'
  local MAGENTA=$'\e''[1;35m'
  local cyan=$'\e''[0;36m'
  local CYAN=$'\e''[1;36m'
  local gray=$'\e''[0;37m'
  local GRAY=$'\e''[1;37m'
  local NC=$'\e''[0m'
  local color="$1"; shift
  echo -e "${!color}$@${NC}"
}

# highlight some regex within stdout
function highlight {
  local sede=()
  local i=1
  while [ "$1" ]; do
    local nexpr='s!\('$1'\)!'$'\e''['$((30+$i%8))'m\1'$'\e''[0m!g'
    sede=("${sede[@]}" "-e '$nexpr'")
    shift
    ((i++))
  done
  eval sed "${sede[@]}"
}

# print most frequently used n commands
function topcmd {
  local count="${1:-20}"; shift
  history |
    awk '{ freq[$2]++ } END { for (cmd in freq) print freq[cmd] ":" cmd }' |
    sort -t: -k1nr,1n |
    sed 's/^[0-9]*://' |
    head -"$count"
}

# clone stdout to a file
function logoutput {
  if [ $# -lt 1 ]; then
    echo "usage: logoutput <logfile>" >&2
    return 1
  fi
  local logfile="$1"; shift
  local fifo=$(mktemp -u)
  mkfifo "$fifo"
  exec 64>&1
  { tee "$logfile" < "$fifo" >&64; rm -f "$fifo"; } &
  local teepid=$!
  exec > "$fifo"

  function _stop_logging {
    exec >&64 64>&-
    wait $teepid
    unset _stop_logging
  }
  echo "run _stop_logging to end" >&2
}

# find file in current directory or parents recursively
function pfind {
  local sdir=.
  local fname=
  if [ $# -eq 1 ]; then
    fname="$1"
  elif [ $# -eq 2 ]; then
    sdir="$1"
    fname="$2"
  else
    echo "usage: pfind [start-dir] <fname>" >&2
    return 1
  fi

  (cd "$sdir"
    while [ "$PWD" != '/' ] && [ ! -e "$fname" ]; do cd ..; done
    if [ -e "$fname" ]; then
      echo "$PWD"
    fi)
}

function map {
  [[ "$1" =~ [0-9]+ ]] && { local atonce="$1"; shift; }
  if [ $# -ne 1 ]; then
    echo "usage: $0 [num-parallel] \"<cmd where __ is placeholder>\"" >&2
    return 1
  fi
  xargs -P "${atonce:-4}" -I __ sh -c "$1"
}

# vim: set sw=2 sts=2 : #
