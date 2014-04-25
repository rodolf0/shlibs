#!/usr/bin/env bash

# Creates a self-extracting shell archive containing all contents of
# a directory. When run it will extract to a temporary directory and
# execute a file named main.sh
function make_shar_ball {
  local sourcedir="$(readlink -f "$1")"
  local entrypoint="${2:-main.sh}"
  local outscript="${3:-"$sourcedir.shar"}"

  if [ $# -lt 1 ] || [ ! -d "$sourcedir" ]; then
    echo "usage: make_shar_ball <source-dir> [entrypoint-script:main.sh]"
    return 1
  elif [ ! -x "$sourcedir"/$entrypoint ]; then
    echo "make_shar_ball: entrypoint must be executable"
    return 1
  fi

  local tmpdir=$(mktemp -u)

  cp -a "$sourcedir" $tmpdir &&
  { cat <<EOF
#!/bin/sh
set -e
exedir=\$(mktemp -d)
tail -n +9 \$0 | tar zxf - -C \$exedir
\$exedir/$entrypoint "\$@"; ret=\$?
rm -rf \$exedir
exit \$ret
#===============================
EOF
    tar zcf - -C $tmpdir . && rm -rf $tmpdir; } \
  > "$outscript" &&
  chmod +x "$outscript" &&
  echo "$outscript created" >&2
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


# finds empty dirs and files that are older than maxdays and removes them
function remove_aged_files {
  local basepath="$1"
  local maxdays="$2"
  local realrun="$3"

  if [ $# -lt 2 ]; then
    echo "use: remove_aged_files <path> <maxdays> [doit]"
    return 1
  fi

  if [ -d "$basepath" ]; then
    if [ "$realrun" = doit ]; then
      find "$basepath" -xdev ! -type d -ctime +$maxdays -exec rm -f {} \;
      find "$basepath" -depth -xdev -type d -empty -exec rmdir {} \;
    else
      find "$basepath" -xdev ! -type d -ctime +$maxdays
      find "$basepath" -depth -xdev -type d -empty
    fi
  fi
}


# monitor a file until it changes or is deleted and execute an action
function watch_file {
  if [ $# -lt 2 -o ! -e "$1" ]; then
    echo "use: watch_file <path> action act-args..."
    return 1
  fi

  local fname="$1"; shift
  local ctime=$(stat -c %Z "$fname")
  local sha1s=$(sha1sum "$fname" | sed 's/ .*$//')
  local pollsecs=5

  echo "Watching $fname (last change: $ctime) sha1: $sha1s" >&2

  while sleep $pollsecs; do
    if [ ! -e "$fname" ]; then
        "$@"; break
    elif [ "$(stat -c %Z "$fname")" != "$ctime" ]; then
      if [ "$(sha1sum "$fname" | sed 's/ .*$//')" != "$sha1s" ]; then
        "$@"; break
      else
        ctime=$(stat -c %Z "$fname")
      fi
    fi
  done
}

# vim: set sw=2 sts=2 : #
