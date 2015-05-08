#!/usr/bin/env bash

# get a random number within limits
function random {
  if [[ "$@" =~ -h ]]; then
    echo "Usage: random [hight] [low]"
    return 1;
  fi

  local high="${1:-1073676289}" # RAND_MAX ^ 2
  local low="${2:-0}"

  echo $(( ($RANDOM * $RANDOM) % ($high - $low) + $low ))
}


# create bit strings
function bitfactory {
  if [ $# -lt 1 ]; then
    echo "usage: $0 word length"
    return 1
  fi

  local bits=
  for ((i=0;i<$1;i++));do
    bits+="{0..1}"
  done
  eval echo $bits
}

function sumrows {
  awk '{s=0; for (i=1; i<=NF; i++) s=s+$i; print s}'
}

function sumcol {
  local col="$1"
  awk "BEGIN{s=0} {s+=\$$col} END{print s}"
}

# show the x-th percentile row
function pX {
  if [ $# -lt 2 ]; then
    echo "usage: pX <percentile> <sort-field>"
    return 1
  fi
  local pct="${1:-95}"
  local field="$2"
  local tmpbuf=$(mktemp)
  if [ "$field" ]; then
    sort -k${field}n,${field}n
  else
    sort -n
  fi > "$tmpbuf"
  local pctline=$(wc -l "$tmpbuf" | sed 's/ .*$//')
  pctline=$(echo "($pctline*0.$pct-0.5)/1" | bc)
  sed -n "${pctline}p" "$tmpbuf"
  rm -f "$tmpbuf"
}
