#!/bin/bash

################################################
## build menus and GUIs with just instantMENU ##
################################################

case "$1" in
-c) # confirmation dialog with prompt $2
    echo "yes
no" | instantmenu -c -w 600 -l 100 -p "${2:-confirm}" >/tmp/isntantanswer
    ANSWER="$(cat /tmp/isntantanswer)"
    if grep -q "yes" <<<"${ANSWER}"; then
        exit 0
    else
        exit 1
    fi
    ;;
-C) # confirmation dialog with prompt from stdin
    PROMPT="$(cat /dev/stdin | sed 's/^/> /g')"
    PROMPT="$PROMPT
yes
no"
    while ! grep -Eq '^(yes|no|forcequit)$' <<<"$ANSWER"; do
        echo "$PROMPT" | instantmenu -c -w 600 -l 100 >/tmp/isntantanswer
        ANSWER="$(cat /tmp/isntantanswer)"
    done
    if grep -q "yes" <<<"${ANSWER}"; then
        exit 0
    else
        exit 1
    fi
    ;;
-P) # password dialog
    echo "" | instantmenu -p "${2:-enter password}" -P -c -w 600
    ;;
esac
