#!/bin/bash

# group items based on a portion of it's name
groupby() {
  if [ $# -lt 3 ]; then
    echo "usage: $0 <rgx-to-make-key> <callback> item [ item ... ]"
    return 1
  fi
  local keymaker="$1"; shift;
  local callback="$1"; shift;
  local items="$@"
  local _keys=""
  for i in $items; do
    local _idx=_cluster_$(echo "$i" | sed -e "$keymaker" -e 's:[^0-9a-zA-Z_]:_:g')
    # register new key (no associative arrays yet :-(
    [[ "${_keys}" =~ $_idx ]] || _keys="${_keys} $_idx"
    # add the entry to the cluster
    eval local ${_idx}=\"\${!_idx} $i\"
  done
  for key in ${_keys}; do
    "$callback" ${!key}
  done
}


# cluster a list of files by extension
by_extension() {
  if [ $# -lt 2 ]; then
    echo "usage: $0 <callback> file [ file ... ]"
    return 1
  fi
  local callback="$1"; shift
  groupby 's/^\(.*/\)\?[^.]*\.//' "$callback" "$@"
}
