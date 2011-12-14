#!/usr/bin/env bash

# search local download dirs for torrent files and push them to blacksmith
function push_torrents {
  local search_dirs=(~/tmp ~/Downloads ~/Descargas /tmp)
  local blacksmith_torrent_dir=/mnt/media/torrents/autoload

  for sdir in ${search_dirs[@]}; do
    ls "$sdir"/*.torrent &>/dev/null &&
    scp "$sdir"/*.torrent warzone3.com.ar:$blacksmith_torrent_dir/ &&
    rm -f "$sdir"/*.torrent
  done
}


# search for subtitles in local dirs and ship them to blacksmith
function push_subdivx_subtitles {
  local search_dirs=(~/tmp ~/Downloads ~/Descargas /tmp)
  local tmpdir=$(mktemp -d)

  for sdir in ${search_dirs[@]}; do
    for sf in $(shopt -s extglob; ls "$sdir"/+([0-9]).{zip,rar} 2>/dev/null); do
      local bn="$(basename "$sf")"
      if [[ $sf =~ .zip$ ]]; then
        mv "$sf" $tmpdir/ &&
          (cd $tmpdir; unzip -j "$bn"; rm -f "$bn") &>/dev/null &&
        rm -f "$sf"
      elif [[ $sf =~ .rar$  ]]; then
        mv "$sf" $tmpdir/ &&
          (cd $tmpdir; unrar e "$bn"; rm -f "$bn") &>/dev/null &&
        rm -f "$sf"
      fi
    done
  done
  if [ $(ls $tmpdir/*.{srt,sub} 2>/dev/null | wc -l) -gt 0 ]; then
    scp $tmpdir/*.{srt,sub} warzone3.com.ar:/tmp/
  fi
  rm -rf $tmpdir
}

# vim: set sw=2 sts=2 : #
