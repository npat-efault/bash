#!/bin/bash

show_usage () {
  echo "Usage is: $1 [OPTIONS] <files>"
  echo "Options:"
  echo "  -d|--date <YYYY:MM:DD HH:MM:SS>  Set EXIF date-time"  
  echo "  -d|--date +<date-shift>          Shift date-time forward"  
  echo "  -d|--date -<date-shift>          Shift date-time back"           
  echo "  -d|--date                        Remove date tags"
  echo "  -c|--caption [<string>]          Set or remove caption"
  echo "  -a|--artist [<string>]           Set or remove artist"
  echo "  -r|--raname                      Rename files by date"
  echo "  -s|--show                        Show file tags"
  echo "  -h|--help                        This message"
  echo
}

PN=$(basename "$0")
TMP=$(getopt -o d:c:a:srh \
             --long date:,caption:,artist:,show,rename,help \
             -n "$PN" -- "$@")
[ $? -ne 0 ] && exit 1
eval set -- "$TMP"

# Tag initial values. 
#   "*" means: leave tag unchanged.
#   empty means: remove the tag.
#   for DATE '-<smth>' means shift backwards
#            '+<smth>' means shift forwards
DATE='*'
CAPTION='*'
ARTIST='*'

# Operation initial values
#   empty means: don't do operation.
SHOW=
RENAME=

while true; do
  case "$1" in
    -d|--date) DATE="$2"; shift 2 ;;
    -c|--caption) CAPTION="$2"; shift 2 ;;
    -a|--artist) ARTIST="$2"; shift 2 ;;
    -s|--show) SHOW=1; shift ;;
    -r|--rename) RENAME=1; shift ;;
    -h|--help) show_usage "$PN"; exit 0 ;;
    --) shift; break ;;
    *) echo "$PN: Internal Error!" 1>&2; exit 1 ;;
  esac 
done

cmd_do=
if [ x"$DATE" != x'*' ]; then
  case "$DATE" in
    +*) cmd_date="-AllDates+=${DATE:1}" ;;
    -*) cmd_date="-AllDates-=${DATE:1}" ;;
    *) cmd_date="-AllDates=$DATE" ;;
  esac
  cmd_do=1
else
  # actually, do nothing
  cmd_date="--AllDates"
fi
if [ x"$CAPTION" != x'*' ]; then
  cmd_caption="-exif:ImageDescription=$CAPTION"
  cmd_do=1
else
  # actually, do nothing
  cmd_caption="--exif:ImageDescription"
fi
if [ x"$ARTIST" != x'*' ]; then
  cmd_artist="-exif:Artist=$ARTIST"
  cmd_do=1
else
  # actually, do nothing
  cmd_artist="--exif:Artist"
fi

if [ -n "$cmd_do" ]; then
  echo "Manipulatig tags..."
  exiftool -overwrite_original \
           "$cmd_date" "$cmd_caption" "$cmd_artist" "$@" || exit 1
fi

if [ -n "$RENAME" ]; then
  echo "Renaming files..."
  exiftool -overwrite_original \
           '-FileName<${DateTimeOriginal}%-.3c.%e' \
           -d %Y-%m-%d-%H-%M-%S "$@" || exit 1
fi

if [ -n "$SHOW" ]; then
  echo
  exiftool -L \
           -AllDates -exif:ImageDescription -exif:Artist \
           "$@"
elif [ -z "$RENAME" ]; then
  echo
  exiftool -T -FileName -DateTimeOriginal "$@"
fi
