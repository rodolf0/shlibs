#!/bin/bash

# kill a whole process group
gkill() {
  [ $# -eq 1 ] &&
  kill -TERM -$(ps -p "$1" -o pgid --no-headers)
}

# attach to existing tmux session or create a new one
tux() {
  local __tmuxsesid="$USER_$(hostname -s)"
  TERM=screen-256color tmux -2 -u new-session -AD -s "$__tmuxsesid"
}

# build a tmux session with notes, jupyter, etc...
ctx() {
  # terminal control: http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
  if ! tmux has-session -t context; then
    tmux new-session -d -s context -n notes \
                    'nvim ~/notes/weekly.log.md'
    tmux new-window -d -t context: -n jupyter \
                    -c ~/Source/notebooks \
                    'jupyter-lab --no-browser'
    tmux new-window -d -t context: -n ujarvis \
                    -c ~/Source/ujarvis \
                    'while sleep 1; do cargo build && ./target/debug/ujarvis; done'
  fi
  # gain control of the session
  tmux -u -2 attach-session -d -t context
}

# highlight some regex within stdout
hl() {
  local sede=()
  local i=1
  while [ "$1" ]; do
    local nexpr='s!\('$1'\)!'$'\e''['$((30+$i%8))'m\1'$'\e''[0m!g'
    sede=("${sede[@]}" "-e '$nexpr'")
    shift
    ((i++))
  done
  eval sed "${sede[@]}"
}

# history search
hist() {
  local filter=
  for f in "$@"; do
    filter="$filter | grep '$f'"
  done
  eval history "$filter"
}

# add splits every 3 digits
thousands() {
  sed ':a;s!\B[0-9]\{3\}\>!,&!; ta'
}

# print most frequently used n commands
topcmd() {
  local count="${1:-20}"; shift
  history |
    awk '{ freq[$2]++ } END { for (cmd in freq) print freq[cmd] ":" cmd }' |
    sort -t: -k1nr,1n |
    sed 's/^[0-9]*://' |
    head -"$count"
}

# encrypt a file
encrypt() {
  if [ $# -lt 1 ]; then
    echo "usage: encrypt <infile>" >&2
    return 1
  fi
  local infile="$1"
  DISPLAY= \
  gpg2 --cipher-algo AES256 \
       --compress-algo zlib \
       --pinentry-mode loopback \
       --output "${infile}.gpg" --symmetric "$infile"
}

# find files I've edited in last x months
my_hg_files() {
  hg log --user "$USER" \
    --date ">$(date -d '3 month ago' +%F)" \
    --template '{files}\n' \
    | tr ' ' '\n' \
    | sort -u
}

# get frequency of input
freq() {
  sort | uniq -c | sort -nr
}

# get some stats of input
stats() {
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
    }' 2>/dev/null |
    if [ "$1" = -h ]; then
      { echo "count avg min p1 p2 p5 p25 p50 p90 p95 p99 max"; cat -; } |
      column -t
    else
      cat -
    fi
}

g() {
  if ! [ -f "$HOME/.dirtree_cache" ]; then
    echo "Missing ~/.dirtree_cache" >&2
    echo "Add crontab:
46 */2 * * * /bin/find <paths> -type d \
-a \( \( -path '*/.*' -o -name buck-out \) -prune -o -print \) \
2>/dev/null > ~/.dirtree_cache.tmp && \
/bin/mv ~/.dirtree_cache.tmp ~/.dirtree_cache"
    return 1
  fi
  local dest_path=$(cat "$HOME/.dirtree_cache" | fzf +m -q "$*")
  [ -d "$dest_path" ] && cd "$dest_path" || cd "$(dirname "$dest_path")"
}
