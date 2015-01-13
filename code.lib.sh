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


function build {
  # try to build Makefile based project
  local bdir=$(pfind build)
  if [ "$bdir" -a -f "$bdir/build/Makefile" ]; then
    make -C "$bdir/build"
    return
  fi

  echo "Don't know how" >&2
  return 1
}


function hgrep {
  if [ $# -lt 2 -o ! -f "$1" ]; then
    echo "usage: hgrep <file> <egrep args>"
    return 1
  fi
  local file="$1"; shift
  cat "$file" |
    { read _h; echo "$_h"; egrep "$@"; }
}


# like sort but will preserve header
function xhsort {
    local opts=("$@")
    local files=()
    local newopts=()
    for o in "${opts[@]}"; do
        if [ "${o:0:1}" != '-' ] || [ "${#o}" -eq 1 ]; then
            files=("${files[@]}" "$o")
        else
            newopts=("${newopts[@]}" "$o")
        fi
    done

    if [ "${#files[@]}" -eq 0 ] || [ "${#files[@]}" -eq 1 -a "$files" = '-' ]; then
        read h; echo "$h"; sort "${newopts[@]}"
    else
        cat "${files[@]}" |
            { read h; echo "$h"; sort "${newopts[@]}"; }
    fi
}
