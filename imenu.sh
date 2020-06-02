#!/bin/bash

################################################
## build menus and GUIs with just instantMENU ##
################################################

# needs instantmenu, fzf and dialog

climenu() {
    [ -e /tmp/climenu ]
}

case "$1" in
-c) # confirmation dialog with prompt $2
    if ! climenu; then
        if ! [ ${#2} -ge 30 ]; then
            echo "yes
no" | instantmenu -w 300 -bw 4 -c -l 100 -p "${2:-confirm} " >/tmp/instantanswer
        else
            echo "yes
no" | instantmenu -bw 4 -c -l 100 -p "${2:-confirm} " >/tmp/instantanswer
        fi
    else
        #dialog confirm promt that returns exit status
        confirm() {
            DIATEXT=${1:-are you sure about that?}
            dialog --yesno "$DIATEXT" 700 600
        }
        if confirm "$2"; then
            echo "yes" >/tmp/instantanswer
        else
            echo "no" >/tmp/instantanswer
        fi
    fi

    ANSWER="$(cat /tmp/instantanswer)"
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
    if ! climenu; then
        while ! grep -Eq '^(yes|no|forcequit)$' <<<"$ANSWER"; do
            echo "$PROMPT" | instantmenu -bw 4 -c -l 100 >/tmp/instantanswer
            ANSWER="$(cat /tmp/instantanswer)"
        done
    else
        while ! grep -Eq '^(yes|no|forcequit)$' <<<"$ANSWER"; do
            echo "$PROMPT" | tac | fzf --prompt "? " >/tmp/instantanswer
            ANSWER="$(cat /tmp/instantanswer)"
        done
    fi

    if grep -q "yes" <<<"${ANSWER}"; then
        exit 0
    else
        exit 1
    fi

    ;;
-P) # password dialog
    if ! climenu; then
        echo "" | instantmenu -bw 4 -p "${2:-enter password}" -P -c -w 800
    else
        passwordbox() {
            unset user_input
            while [ -z "$user_input" ]; do
                #statements
                user_input=$(
                    dialog --passwordbox "${1:-enter password}" 700 700 \
                        3>&1 1>&2 2>&3 3>&-
                )
            done
            echo "$user_input"
        }
        passwordbox "${2:-enter password}"
    fi
    ;;
-i) # input dialog
    if ! climenu; then
        echo "" | instantmenu -bw 4 -p "${2:-enter text}" -c -w 800
    else
        textbox() {
            unset user_input
            while [ -z "$user_input" ]; do
                #statements
                user_input=$(
                    dialog --inputbox "${1:-enter text}" 700 700 \
                        3>&1 1>&2 2>&3 3>&-
                )
            done
            echo "$user_input"
        }
        textbox "${2:-enter text}"
    fi
    ;;
-m) # message
    PROMPT=$(sed 's/^/> /g' <<<$2)
    PROMPT="$PROMPT

OK"

    if ! climenu; then
        echo "$PROMPT" | instantmenu -bw 4 -l 20 -c
    else
        echo "$PROMPT" | tac | fzf --prompt "- "
    fi
    ;;
-M) # message from stdin
    PROMPT="$(cat /dev/stdin | sed 's/^/> /g')"
    PROMPT="$PROMPT

OK"
    if ! climenu; then
        echo "$PROMPT" | instantmenu -bw 4 -l 20 -c
    else
        echo "$PROMPT" | tac | fzf
    fi
    ;;

-l) # choose item from list
    ASTDIN="$(cat /dev/stdin)"
    ANSWER=""

    while ! grep -q .. <<<"$ANSWER"; do
        if ! climenu; then
            ANSWER=$(echo "$ASTDIN" | instantmenu -bw 4 -p "${2:-choose}" -c -l 20)
        else
            ANSWER=$(echo "$ASTDIN" | tac | fzf --prompt "${2:-choose}")
        fi
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
