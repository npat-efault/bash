#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage is: $(basename $0) <src-path-prefix> <dst-path-prefix>" 1>&2
  exit 1
fi

src=$(echo "$1" | sed 's/\./\\\./g')
dst=$2

echo "Fixing: [$src] -> [$dst]" 

sed -i.orig "s|\"$src|\"$dst|" $(grep -l "$src" --include='*.go' -r .)
