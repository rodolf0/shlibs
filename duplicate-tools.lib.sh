#!/usr/bin/env bash

function __file_filter {
  grep -v Picasa.ini
}

function calculate_shas {
  if [ $# -lt 1 ]; then
    echo "usage: calculate_shas <base-dir>" >&2
    return 1
  fi
  local base="$1"; shift
  find "$base" -type f -exec sha1sum {} \; |
    __file_filter |
    sort -t $'\x20' -k1,1
}

function find_dups {
  if [ $# -lt 1 ]; then
    echo "usage: find_dups <base-dir>" >&2
    return 1
  fi
  local base="$1"; shift
  local all=$(mktemp /tmp/tmp.XXXXX)
  local dups=$(mktemp /tmp/tmp.XXXXX)

  calculate_shas "$base" > "$all"
  cat "$all" |
    awk '{shas[$1] += 1} END{for(s in shas) print s "," shas[s]}' |
    grep -v ',1$' |
    cut -d, -f 1 \
    > "$dups"

  fgrep -f "$dups" < "$all"

  rm -f "$all" "$dups"
}

# vim: set sw=2 sts=2 : #
