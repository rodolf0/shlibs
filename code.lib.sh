#!/usr/bin/env bash

function cgrep {
  find . \( \
      -iregex '.*\.c\|.*\.cc\|.*\.cpp\|.*\.cxx\|.*\.h\|.*\.hh\|.*\.hpp' -o \
      -iname '*.py' -o \
      -iname '*.sh' -o \
      -iregex '.*\.pm\|.*\.pl' -o \
      -iname '*.go' \
      \) -type f -print0 |
    xargs -0 -r egrep "$@"
}
