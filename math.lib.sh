#!/usr/bin/env bash

# get a random number within limits
random() {
  if [[ "$@" =~ -h ]]; then
    echo "Usage: random [hight] [low]"
    return 1;
  fi

  local high="${1:-1073676289}" # RAND_MAX ^ 2
  local low="${2:-0}"

  echo $(( ($RANDOM * $RANDOM) % ($high - $low) + $low ))
}

sumrows() {
  awk '{s=0; for (i=1; i<=NF; i++) s=s+$i; print s}'
}

sumcol() {
  local col="$1"
  awk "BEGIN{s=0} {s+=\$$col} END{print s}"
}

freq() {
  sort | uniq -c | sort -nr
}

# show the x-th percentile row
pX() {
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

stats() {
  [ "$1" = -h ] && echo "count avg min p1 p2 p5 p25 p50 p90 p95 p99 max"
  sort -n |
    awk 'BEGIN{ i=0; t=0; }
    NR == 1 {min=$1; max=$1}
    NR > 1 && $1 < min { min = $1 }
    NR > 1 && $1 > max { max = $1 }
    { t+=$1; s[i]=$1; i++; }
    END {
      print NR, t/NR, min,
      s[int(NR*0.01-0.5)],
      s[int(NR*0.02-0.5)],
      s[int(NR*0.05-0.5)],
      s[int(NR*0.25-0.5)],
      s[int(NR*0.50-0.5)],
      s[int(NR*0.90-0.5)],
      s[int(NR*0.95-0.5)],
      s[int(NR*0.99-0.5)],
      max
    }' 2>/dev/null
}
