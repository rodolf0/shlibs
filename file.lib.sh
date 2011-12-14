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
\$exedir/$entrypoint; ret=\$?
rm -rf \$exedir
exit \$ret
#===============================
EOF
    tar zcf - -C $tmpdir . && rm -rf $tmpdir; } \
  > "$outscript" &&
  chmod +x "$outscript" &&
  echo "$outscript created" >&2
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

# vim: set sw=2 sts=2 : #
