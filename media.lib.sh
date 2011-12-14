#!/usr/bin/env bash

# compress/encode a raw avi file into divx
function encode_avi2divx {
  # http://web.njit.edu/all_topics/Prog_Lang_Docs/html/mplayer/encoding.html
  local infile="$1"; shift
  local outfile="$1"; shift

  if [ -z "$infile" -o -z "$outfile" ]; then
    echo "usage: $0 <infile> <outfile>" >&2
    return 1
  fi
  mencoder -oac mp3lame -ovc lavc -lavcopts vhq:vqmin=2:vcodec=mpeg4:threads=3 \
    -o "$outfile" "$infile"
}
