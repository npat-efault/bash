#!/bin/bash

#
# img_resize.sh
#
# Resize pictures in a directory (converting them to jpeg) to satisfy 
# a target file-size
#
# by Nick Patavalis (npat@efault.net)
# 
# This script is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This script is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA
#

usage="\

Usage is: $(basename $0) <source dir> <target dir>

Parameter variables:

  SIZE: maximum allowable image size in bytes
  QUALITY: maximum (optimum) jpeg quality to start with
  QUALITY_MIN: minimum acceptable jpeg quality
  RESOLUTION: resolution to start with
  RESOLUTION_MIN: minimum acceptable resolution
  BORDER: add a border that-many pixels wide. 0 means no border
  BORDER_COLOR: 
  QUIET: if defined suppress progress messages

Examples:

  SIZE=262144 $(basename $0) ./pics ./small-pics

  Scale images found in direcotry \"./pics\" for maximum size of
  256KB. Put the resulting images in \"./small-pics\". Use default
  resolution and quality settings.

  SIZE=262144 QUALITY_MIN=78 $(basename $0) ./pics ./small-pics

  As above, but don't allow quality setting to drop below 78---decrease
  resolution instead.

  SIZE=102400 QUALITY_MIN=60 RESOLUTION=1024x768 \\
  $(basename $0) ./pics ./small-pics

  Scale images in \"./pics\" for maximum file-size of 100KB. Try to
  attain resolution of 1024x768. Allow quality to drop as low as 60,
  before reducing resulotion.

"

#######################################################################
# Parameter defaults

[ -z "$SIZE" ] && SIZE=102400
[ -z "$QUALITY" ] && QUALITY=95
[ -z "$QUALITY_MIN" ] && QUALITY_MIN=70
[ -z "$RESOLUTION" ] && RESOLUTION=640x480
[ -z "$RESOLUTION_MIN" ] && RESOLUTION_MIN=320x240
# QUIET not defined, by default

#######################################################################
# Command-line arguments and usage

if [ $# -ne 2 ]; then
  echo "$usage" 1>&2
  exit 1
fi

[ ! -d "$1" ] && { echo "$1: not a directory." 1>&2; exit 1; }
[ ! -d "$2" ] && { echo "$2: not a directory." 1>&2; exit 1; }

sdir="$1"
tdir="$2"

#######################################################################
# Parse params and check for validity

res_x=$(echo "$RESOLUTION" \
        | sed 's/^\([0-9]\+\)[xX*]\([0-9]\+\)$/\1/')
res_y=$(echo "$RESOLUTION" \
        | sed 's/^\([0-9]\+\)[xX*]\([0-9]\+\)$/\2/')
res_x_min=$(echo "$RESOLUTION_MIN" \
            | sed 's/^\([0-9]\+\)[xX*]\([0-9]\+\)$/\1/')
res_y_min=$(echo "$RESOLUTION_MIN" \
            | sed 's/^\([0-9]\+\)[xX*]\([0-9]\+\)$/\2/')
res_pix=$(expr $res_x \* $res_y)
res_pix_min=$(expr $res_x_min \* $res_y_min)

if ! test $res_pix -gt 10000 2> /dev/null; then
  echo "Invalid RESOLUTION: $RESOLUTION" 1>&2
  exit 1
fi

if ! test $res_pix_min -gt 1000 2> /dev/null; then
  echo "Invalid RESOLUTION_MIN: $RESOLUTION_MIN" 1>&2
  exit 1
fi

if ! test $SIZE -gt 1024 2> /dev/null; then
  echo "Invalid SIZE: $SIZE" 1>&2
  exit 1
fi

if ! test $QUALITY -gt 50 2> /dev/null; then
  echo "Invalid QUALITY: $QUALITY" 1>&2
  exit 1
fi

if ! test $QUALITY_MIN -gt 5 2> /dev/null; then
  echo "Invalid QUALITY_MIN: $QUALITY_MIN" 1>&2
  exit 1
fi

#######################################################################
# Print settings

if [ -z "$QUIET" ]; then
  echo "SIZE=$SIZE"
  echo "RESOLUTION=$RESOLUTION"
  echo "RESOLUTION_MIN=$RESOLUTION_MIN"
  echo "RESOLUTION_PIX=$res_pix"
  echo "RESOLUTION_PIX_MIN=$res_pix_min"
  echo "QUALITY=$QUALITY"
  echo "QUALITY_MIN=$QUALITY_MIN"
  echo "SOURCE_DIR=$sdir"
  echo "TARGET_DIR=$tdir"
fi;

#######################################################################
# Do the work

for spf in "$sdir"/*; do

  # check if "spf" is a file, and if it looks like an image
  [ ! -f "$spf" ] && continue;
  case "$spf" in
    *.gif | *.jpg | *.jpeg | *.png | *.tif | *.tiff | *.bmp )
      true
      ;;
    *.GIF | *.JPG | *.JPEG | *.PNG | *.TIF | *.TIFF | *.BMP )
      true
      ;;
    *)
      echo "$spf: not a picture" 1>&2
      continue;
  esac

  # calculate target picture filename
  base=$(basename "$spf")
  base=${base%.*}
  tpf="$tdir"/"$base".jpg

  # handle special case whereby image has good size already, 
  # and it's a JPEG file
  sz=$(find "$spf" -printf "%s")
  if [ $sz -lt $SIZE ]; then
    if file "$spf" | grep -q "JPEG" 2> /dev/null; then
      cp "$spf" "$tpf"
      if [ -z "$QUIET" ]; then
        echo "$spf: fits. just copy..."
      fi
      continue
    fi
  fi

  # iterate reducing first quality, then resolution, 
  # until size becomes good
  qual=$QUALITY
  pix=$res_pix
  first=1
  fin=
  while [ -z "$fin" ]; do

    anytopnm "$spf" 2> /dev/null \
    | pnmscale -pixels=$pix 2> /dev/null\
    | pnmmargin -black 4 2> /dev/null \
    | pnmtojpeg --quality=$qual --optimize 2> /dev/null \
    > "$tpf" 

    sz=$(find "$tpf" -printf "%s")

    if [ -z "$QUIET" ]; then
      if [ -n "$first" ]; then
        echo "$spf: "
        first=
      fi
      echo "  qual=$qual, pix=$pix, size=$sz"
    fi

    if [ $sz -gt $SIZE ]; then
      if [ $qual -gt $QUALITY_MIN ]; then
        qual=$(expr $qual - 1)
      elif [ $pix -gt $res_pix_min ]; then
        # try to estimate how much to decrease resolution
        bytes_per_kpixel=$(expr $sz \* 1000 / $pix)
        tpix=$(expr $SIZE \* 1000 / $bytes_per_kpixel)
        if [ $tpix -lt $pix ]; then
          pix=$tpix
        else
          pix=$(expr $pix - 1600)
        fi
      else
        echo "$spf: impossible to resize given constraints!" 1>&2
        rm -f "$tpf"
        fin=1
      fi
    else
      fin=1
    fi

  done

done
