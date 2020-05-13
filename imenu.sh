#!/bin/bash

################################################
## build menus and GUIs with just instantMENU ##
################################################

case "$1" in
-c) # confirmation dialog with prompt $2
    echo "yes
no" | instantmenu -c -l 100 -p "${2:-confirm}" >/tmp/isntantanswer
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
        echo "$PROMPT" | instantmenu -c -l 100 >/tmp/isntantanswer
        ANSWER="$(cat /tmp/isntantanswer)"
    done
    if grep -q "yes" <<<"${ANSWER}"; then
        exit 0
    else
        exit 1
    fi
    ;;
-P) # password dialog
    echo "" | instantmenu -p "${2:-enter password}" -P -c -w 800
    ;;
-i) # input dialog
    echo "" | instantmenu -p "${2:-enter text}" -c -w 800
    ;;
-m) # message
    PROMPT=$(sed 's/^/> /g' <<<$2)
    PROMPT="$PROMPT
OK"
    echo "$PROMPT" | instantmenu -l 20 -c
    ;;
-M) # message from stdin
    PROMPT="$(cat /dev/stdin | sed 's/^/> /g')"
    PROMPT="$PROMPT
OK"
    echo "$PROMPT" | instantmenu -l 20 -c
    ;;

-l) # choose item from list
    ASTDIN="$(cat /dev/stdin)"
    ANSWER=""

    while ! grep -q .. <<<"$ANSWER"; do
        ANSWER=$(echo "$ASTDIN" | instantmenu -p "${2:-choose}" -c -l 20)

        if grep -q "forcequit" <<<"$ANSWER"; then
            exit 1
        fi

        if ! grep -q "^$ANSWER$" <<<"$ASTDIN"; then
            ANSWER=""
        fi
    done

    echo "$ANSWER"
    ;;

esac
