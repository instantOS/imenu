#!/bin/bash

################################################
## build menus and GUIs with just instantMENU ##
################################################

# needs instantmenu, fzf and dialog

if [ "$1" = "cli" ]; then
    shift 1
    USECLIMENU="True"
fi

climenu() {
    [ -e /tmp/climenu ] || [ -n "$USECLIMENU" ]
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
    rm /tmp/instantanswer
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
            PROMPTHEIGHT=$(wc -l <<<"$PROMPT")
            echo "$PROMPT" | fzf --header-lines "$(expr $PROMPTHEIGHT - 2)" --layout reverse --prompt "? " >/tmp/instantanswer
            ANSWER="$(cat /tmp/instantanswer)"
        done
    fi
    rm /tmp/instantanswer
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
    PROMPTHEIGHT=$(wc -l <<<"$PROMPT")

    if ! climenu; then
        echo "$PROMPT" | instantmenu -bw 4 -l 20 -c
    else
        echo "$PROMPT" | fzf --layout reverse --header-lines "$(expr $PROMPTHEIGHT - 1)" --prompt "- "
    fi
    ;;
-M) # message from stdin
    PROMPT="$(cat /dev/stdin | sed 's/^/> /g')"
    PROMPT="$PROMPT

OK"
    PROMPTHEIGHT=$(wc -l <<<"$PROMPT")

    if ! climenu; then
        echo "$PROMPT" | instantmenu -bw 4 -l 20 -c
    else
        echo "$PROMPT" | fzf --layout reverse --header-lines "$(expr $PROMPTHEIGHT - 1)" --prompt "- "
    fi
    ;;

-l) # choose item from list
    ASTDIN="$(cat /dev/stdin)"
    ANSWER=""

    while ! grep -q .. <<<"$ANSWER"; do
        if ! climenu; then
            ANSWER=$(echo "$ASTDIN" | instantmenu -i -bw 4 -p "${2:-choose}" -c -l 20)
        else
            if grep -q '^>' <<<"$ASTDIN"; then
                HEADERLINES=$(echo "$ASTDIN" | grep '^>' | wc -l)
                ANSWER=$(echo "$ASTDIN" | fzf --layout reverse --header-lines "$HEADERLINES" --prompt "${2:-choose}")
            else
                ANSWER=$(echo "$ASTDIN" | tac | fzf --prompt "${2:-choose}")
            fi
        fi
        if grep -q "forcequit" <<<"$ANSWER"; then
            exit 1
        fi

        if ! grep -q "^$ANSWER$" <<<"$ASTDIN" || grep '^>' <<<"$ANSWER"; then
            ANSWER=""
        fi
    done

    echo "$ANSWER"
    ;;

esac
