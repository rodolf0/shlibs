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


# highlight some regex within stdout
function highlight {
  local expr1="${1:-$RANDOM$RANDOM}"; shift
  local expr2="${1:-$RANDOM$RANDOM}"; shift
  local expr3="${1:-$RANDOM$RANDOM}"; shift
  local expr4="${1:-$RANDOM$RANDOM}"; shift
  sed -e 's!\('${expr1}'\)!'$'\e''[31m\1'$'\e''[0m!g' \
      -e 's!\('${expr2}'\)!'$'\e''[32m\1'$'\e''[0m!g' \
      -e 's!\('${expr3}'\)!'$'\e''[33m\1'$'\e''[0m!g' \
      -e 's!\('${expr4}'\)!'$'\e''[34m\1'$'\e''[0m!g'
}


export __MARKPATH=$HOME/.marks
function jump {
  cd -P $__MARKPATH/$1 2>/dev/null || echo "No such mark: $1"
}
function mark {
  mkdir -p $__MARKPATH; ln -s $(pwd) $__MARKPATH/$1
}
function unmark {
  rm -i $__MARKPATH/$1
}
function marks {
  ls -l $__MARKPATH | sed 's/  / /g' | cut -d' ' -f9- | sed 's/ -/\t-/g' && echo
}

# vim: set sw=2 sts=2 : #
