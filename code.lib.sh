#!/usr/bin/env bash

function cgrep {
  if [ $# -lt 2 ]; then
    echo "usgage: cgrep <rootdir> <egrep-opts>..." >&2
    return 1
  fi
  local dir="$1"; shift
  find "$dir" \( \
      -iregex '.*\.c\|.*\.cc\|.*\.cpp\|.*\.cxx\|.*\.h\|.*\.hh\|.*\.hpp' -o \
      -iname '*.py' -o \
      -iname '*.sh' -o \
      -iregex '.*\.pm\|.*\.pl' -o \
      -iname '*.go' \
      \) -type f -print0 |
    xargs -0 egrep "$@"
}
