#!/bin/bash
#
# browse.sh
#
# Open file, url, or stdin on browser window.
#
# e.g. browse myfile.html
#      browse http://site.com
#      cat myfile.html | browse 
#

if [ $# -lt 1 ]; then
    tmp=`mktemp --tmpdir browse.XXXXXXXXXX`
    cat > "$tmp"
    url="file://$tmp"
elif echo "$1" | grep -q '^[[:alnum:]]\+://'; then
    url="$1"
else
    fp=`readlink -f "$1"`
    url="file://$fp"
fi

if [ -n "$BROWSER" ]; then
    browser="$BROWSER"
else
    browser="sensible-browser"
fi

exec "$browser" "$url"
