#!/usr/bin/env bash

function __file_filter {
  grep -v Picasa.ini
}

function calculate_shas {
  local base="$1"; shift
  find "$base" -type f -exec sha1sum {} \; |
    __file_filter |
    sort -t $'\x20' -k1,1
}

function find_uniques {
  local shafile="$1"; shift
  cat "$shafile" |
    sort -t $'\x20' -k 1,1 |
    funiq -d $'\x20' -f 1
}

function find_dups {
  local allshas="$1"; shift
  local uniqshas="$1"; shift
  filterkeys -f <(comm -32 "$allshas" "$uniqshas" | # dup shas
                  reorder -d $'\x20' -f 1) \
             -d $'\x20' -a 1 -b 1 "$allshas"
}

function suggest_remove {
  local allshas="$1"; shift
  local uniqshas="$1"; shift
  comm -32 "$allshas" "$uniqshas"
}

function suggest_mergedirs {
  local allshas="$1"; shift
  local dupshas="$1"; shift
  local prevsha=
  filterkeys -f <(reorder -d $'\x20' -f 1 "$dupshas") \
             -d $'\x20' -a 1 -b 1 "$allshas" |
    while read l; do
      local f=$(echo $l | cutfield -d $'\x20' -f 1);
      local sha=$(echo $l | reorder -d $'\x20' -f 1);
      if [ "$sha" != "$prevsha" ]; then
        prevsha=$sha;
        echo # newline
      fi
      echo -n "'$(dirname "$f")' "
    done |
    sort -u
}

# vim: set sw=2 sts=2 : #
