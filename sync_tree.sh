#!/bin/bash
#

do_subdir () {
  local cwd md sd e
  md="$1"
  sd="$2"
  if [ ! -d "$md" ]; then
    echo "** Not a dir: $md" 1>&2
    return 1
  fi
  if [ ! -d "$sd" ]; then
    echo "mkdir $sd"
    rm -rf "$sd"
    mkdir "$sd" || { echo "** Cannot mkdir: $sd" 1>&2; return 1; }
  fi

  cwd=`pwd`
  cd "$md" || { echo "** Cannot cd into: $md" 1>&2; return 1; }
  for e in *; do
    if [ -f "$e" ]; then
      if [ ! -f "$sd"/"$e" ]; then
        echo "cp $md/$e"
        rm -rf "$sd"/"$e"
        cp -p "$md"/"$e" "$sd"/"$e" \
          || { echo "** Cannot cp: $md/$e" 1>&2; }
      fi
    elif [ -d "$e" ]; then
      do_subdir "$md"/"$e" "$sd"/"$e" \
        || { cd "$cwd"; return 1; }
    else
      echo "Skipping: $md/$e"
    fi
  done
  cd "$cwd"

  return 0
}

do_subdir_clean () {
  local cwd md sd e
  md="$1"
  sd="$2"
  if [ ! -d "$sd" ]; then
    echo "** Not a dir: $md" 1>&2
    return 1
  fi
  cwd=`pwd`
  cd "$sd" || { echo "** Cannot cd into: $sd" 1>&2; return 1; }
  for e in *; do
    if [ ! -e "$md"/"$e" ]; then
      echo "rm $sd/$e"
      rm -rf "$sd"/"$e"
    elif [ -d "$sd"/"$e" ]; then
      do_subdir_clean "$md"/"$e" "$sd"/"$e" \
        || { cd "$cwd"; return 1; }
    fi
  done
  cd "$cwd"

  return 0
}

if [ $# -ne 2 ]; then
  echo "Usage is: $cmd <master root> <slave root>" 1>&2
  exit 1
fi;

if [ ! -d "$1" ]; then
    echo "Master root not a dir: $1" 1>&2
    exit 1;
fi
if [ ! -d "$2" ]; then
    echo "Slave root not a dir: $2" 1>&2
    exit 1;
fi

mr=$(readlink -f "$1")
sr=$(readlink -f "$2")

echo
echo "Syncing slave..."
do_subdir "$mr" "$sr" || exit 1
echo
echo "Cleaning slave..."
do_subdir_clean "$mr" "$sr" || exit 1
