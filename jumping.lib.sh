#!/usr/bin/env bash

export __MARKPATH=$HOME/.marks

j() {
  cd -P $__MARKPATH/$1 2>/dev/null || echo "No such mark: $1"
}

mark() {
  mkdir -p $__MARKPATH; ln -s $(pwd) $__MARKPATH/$1
}

unmark() {
  rm -i $__MARKPATH/$1
}

marks() {
  ls -l $__MARKPATH | awk '/->/ {printf "%-15s -> %s\n", $9, $11}'
}

_jcompgen() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=()
  if [ $(ls -1 $__MARKPATH 2>/dev/null | sed "/^$cur/!d" | wc -l) -eq 1 ]; then
    COMPREPLY=($(ls -1 $__MARKPATH | sed "/^$cur/!d"))
    return
  fi
  while read l; do
    COMPREPLY=("${COMPREPLY[@]}" "$l")
  done < <(marks | sed "/^$cur/!d")
}

complete -o nospace -F _jcompgen j
