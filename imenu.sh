#!/bin/bash

################################################
## build menus and GUIs with just instantMENU ##
################################################

# needs instantmenu, fzf and gum

if [ "$1" = "cli" ] || [ "$1" = "--cli" ]; then
    shift 1
    USECLIMENU="True"
fi

climenu() {
    [ -e /tmp/climenu ] || [ -n "$USECLIMENU" ]
}

echoerr() {
    echo "$@" 1>&2
}

echohelp() {
    echo "imenu: instantmenu/fzf wrapper to quickly create simple interfaces
usage: imenu [OPTION]
        --cli
           use cli version instead of gui
        -c <title> [-i]
           confirmation prompt, pass -i to invert the result
        -C <title>
           multi line confirmation prompt with message from stdin
        -P <prompt name>
           password prompt
        -w <message>
           display loading message
        -e <message>
           display error message
        -i <title>
           ask user for a single line of input
        -m <message>
           display message
        -M
           display multi line message from stdin
        -t
           display toast message
        -l
           choose item from stdin
        -b
           checkbox list to choose multiple items from stdin
        -E <addcommand>
           edit list from stdin, adding an item executes <addcommand>
"
}

case "$1" in
-c) # confirmation dialog with prompt $2
    if [ "$2" = "-i" ]; then
        shift 1
        YESCOLOR="{red} yes"
        NOCOLOR="{green} no"
    else
        YESCOLOR="{green} yes"
        NOCOLOR="{red} no"
    fi

    unset ANSWER
    while [ -z "$ANSWER" ]; do
        if ! climenu; then
            if ! [ ${#2} -ge 30 ]; then
                ANSWER=$(echo "$YESCOLOR
$NOCOLOR" | instantmenu \
                    --width 300 \
                    --border-width 4 \
                    --position center \
                    --lines 100 \
                    --prompt "${2:-confirm} ")
            else
                ANSWER=$(echo "$YESCOLOR
$NOCOLOR" | instantmenu \
                    --border-width 4 \
                    --position center \
                    --lines 100 \
                    --prompt "${2:-confirm} ")
            fi
        else

            #gum confirm promt that returns exit status
            confirm() {
                DIATEXT=${1:-are you sure about that?}
                gum confirm "$DIATEXT"
            }

            if confirm "$2"; then
                ANSWER="yes"
            else
                ANSWER="no"
            fi
        fi

        if [ -z "$ANSWER" ] && [ -n "$IMENUACCEPTEMPTY" ]; then
            echo "empty"
            exit 2
        fi

    done

    if grep -q "yes" <<<"${ANSWER}"; then
        exit 0
    else
        exit 1
    fi
    ;;
-C) # confirmation dialog with prompt from stdin
    PROMPT="$(sed 's/^/{heading} /g' </dev/stdin)"
    PROMPT="$PROMPT
{heading} 
{green} yes
{red} no"

    PSITEM="$(($(wc -l <<<"$PROMPT") - 2))"

    checkexit() {
        if [ -z "$ANSWER" ] && [ -n "$IMENUACCEPTEMPTY" ]; then
            echo "empty"
            exit 2
        fi
    }
    echo "$PSITEM"
    unset ANSWER
    while [ -z "$ANSWER" ]; do
        if ! climenu; then
            while ! grep -Eq '^(yes|no|forcequit)$' <<<"$ANSWER"; do
                ANSWER=$(echo "$PROMPT" | grep '.' | instantmenu \
                        --preselect "$PSITEM" \
                        --border-width 4 \
                        --position center \
                        --lines 100 \
                        --reject-no-match \
                        --placeholder 'confirmation')
                checkexit
            done
        else
            while ! grep -Eq '^(yes|no|forcequit)$' <<<"$ANSWER"; do
                PROMPTHEIGHT=$(wc -l <<<"$PROMPT")
                ANSWER=$(echo "$PROMPT" | sed -E 's/\{[^{}]*\} //g; s/^(\{[^{}]*\})+//g' |
                    fzf --header-lines "$((PROMPTHEIGHT - 2))" --layout reverse --prompt "? ")
                checkexit
            done
        fi

    done

    if grep -q "yes" <<<"${ANSWER}"; then
        exit 0
    else
        exit 1
    fi

    ;;
-w) # waiting thingy
    if ! climenu; then
        echo "{heading} $2
{green icon=hourglass-end} OK" | instantmenu \
            --line-height auto \
            --lines 20 \
            --position center \
            --border-width 4 \
            --width auto \
            --placeholder "loading..." &
    else
        echo "loading...
$2" | imenu -M
    fi
    ;;
-e) # error message
    if ! climenu; then
        echo "{heading} $2
{red icon=circle-exclamation} OK" | instantmenu \
            --line-height auto \
            --lines 20 \
            --position center \
            --border-width 4 \
            --width auto \
            --placeholder "error"

    else
        echo "Error
$2" | imenu -M
    fi
    ;;

-P) # password prompt
    if ! climenu; then
        echo "" | instantmenu \
            --border-width 4 \
            --prompt "${2:-enter password}" \
            --password \
            --position center \
            --width 800
    else
        passwordbox() {
            unset user_input
            while [ -z "$user_input" ]; do
                user_input=$(
                    gum input --password --prompt "${1:-enter password}> "
                )
            done
            echo "$user_input"
        }
        passwordbox "${2:-enter password}"
    fi
    ;;
-i) # input prompt
    if ! climenu; then
        if [ -z "$4" ]; then
            echo "" | instantmenu \
                --line-height auto \
                --border-width 4 \
                --placeholder "${3:-enter to confirm}" \
                --prompt "${2:-enter text}" \
                --position center \
                --width 800 \
                --input-only
        else
            echo "" | instantmenu \
                --initial-text "$4" \
                --line-height auto \
                --border-width 4 \
                --placeholder "${3:-enter to confirm}" \
                --prompt "${2:-enter text}" \
                --position center \
                --width 800 \
                --input-only
        fi
    else
        textbox() {
            unset user_input
            while [ -z "$user_input" ]; do
                #statements
                user_input=$(
                    gum input --prompt "${1:-enter text}> "
                )
            done
            echo "$user_input"
        }
        textbox "${2:-enter text}"
    fi
    ;;
-m) # message
    PROMPT="$(sed 's/^/{heading} /g' <<<"$2")"
    PROMPT="$PROMPT
{heading}
OK"
    PROMPTHEIGHT="$(wc -l <<<"$PROMPT")"

    if ! climenu; then
        echo "$PROMPT" | instantmenu \
            --border-width 4 \
            --lines 20 \
            --position center \
            --placeholder "$2"
    else
        echo "$PROMPT" | fzf --layout reverse --header-lines "$((PROMPTHEIGHT - 1))" --prompt "- "
    fi
    ;;
-M) # message from stdin
    PROMPT="$(sed 's/^/{heading} /g' </dev/stdin)"
    PROMPT="$PROMPT
{heading}
OK"
    PROMPTHEIGHT=$(wc -l <<<"$PROMPT")

    if ! climenu; then
        if [ "$PROMPTHEIGHT" -lt 6 ]; then
            echo "$PROMPT" | instantmenu \
                --border-width 4 \
                --line-height auto \
                --lines 20 \
                --position center \
                --placeholder "$2"
        else
            echo "$PROMPT" | instantmenu \
                --border-width 4 \
                --lines 20 \
                --position center \
                --placeholder "$2"
        fi
    else
        echo "$PROMPT" | fzf --layout reverse --header-lines "$((PROMPTHEIGHT - 1))" --prompt "- "
    fi
    ;;

-t) # show an android like toast
    echo "{heading} $2" | instantmenu \
        --toast 3.5 \
        --width auto \
        --lines 10 \
        --border-width 5 \
        --x-offset 1000000 \
        --y-offset -1 \
        --placeholder 'alert' &
    ;;
-l) # choose item from list
    ASTDIN="$(cat /dev/stdin)"
    ANSWER=""

    if [ "$2" = "-i" ]; then
        shift 1
        ICONMODE=true
    fi

    if [ "$2" = "-s" ] && [ -n "$3" ]; then
        PRESELECT="$3"
        shift 2
    else
        PRESELECT="0"
    fi

    while ! grep -q .. <<<"$ANSWER"; do
        if ! climenu; then
            if [ -z "$ICONMODE" ]; then
                ANSWER=$(echo "$ASTDIN" | instantmenu \
                    --preselect "$PRESELECT" \
                    --insensitive \
                    --border-width 4 \
                    --prompt "${2:-choose}" \
                    --position center \
                    --lines 20)
            else
                ANSWER=$(echo "$ASTDIN" | instantmenu \
                    --preselect "$PRESELECT" \
                    --insensitive \
                    --line-height auto \
                    --width auto \
                    --border-width 4 \
                    --prompt "${2:-choose}" \
                    --position center \
                    --lines 20)
            fi
        else
            if grep -q '^{heading}' <<<"$ASTDIN"; then
                HEADERLINES=$(echo "$ASTDIN" | grep -c '^{heading}')
                ANSWER="$(echo "$ASTDIN" | fzf --layout reverse --header-lines "$HEADERLINES" --prompt "${2:-choose}> ")"
            else
                ANSWER="$(echo "$ASTDIN" | tac | fzf --prompt "${2:-choose}> ")"
            fi
        fi
        if [ -z "$ANSWER" ] && [ -n "$IMENUACCEPTEMPTY" ]; then
            exit 0
        fi
        if grep -q "forcequit" <<<"$ANSWER"; then
            exit 1
        fi

        # instantmenu outputs clean labels while fzf echoes raw lines,
        # so compare against the stripped list in gui mode (raw still wins,
        # e.g. for labels that genuinely start with a brace); never return
        # heading rows
        if ! climenu; then
            if ! grep -Fxq -- "$ANSWER" <<<"$ASTDIN" &&
                ! grep -Fxq -- "$ANSWER" <<<"$(sed -E 's/^\{[^{}]*\} ?//' <<<"$ASTDIN")"; then
                ANSWER=""
            fi
        elif ! grep -Fxq -- "$ANSWER" <<<"$ASTDIN" || grep -q '^{heading}' <<<"$ANSWER"; then
            ANSWER=""
        fi
    done

    echo "$ANSWER"
    ;;
-b) # checkbox list
    # lets user toggle
    AFILE=/tmp/listfile
    cat /dev/stdin >"$AFILE"
    cat /dev/stdin
    awk '{printf "%d %s\n", NR, $0}' <"$AFILE" | sed 's/^/[ ] /g' >"${AFILE}2"
    echo "OK" >>"${AFILE}2"
    cat "${AFILE}2" >"$AFILE"

    quit() {
        grep -a '^\[x' "$AFILE" | sed 's/^\[.\] [0-9]* //g'
        rm "$AFILE"
        exit
    }

    while ! [ "$ANSWER" = "OK" ]; do
        ANSWER="$(imenu -l 'type ok to confirm' <"$AFILE")"
        if grep -q '^OK' <<<"$ANSWER"; then
            quit
        fi
        if [ -n "$ANSWER" ]; then
            LINENUMBER=$(echo "$ANSWER" | grep -o '\[.\] [0-9]*' | grep -o '[0-9]*')
            if grep -q '^\[ \]' <<<"$ANSWER"; then
                NEWANSWER="$(echo "$ANSWER" | sed 's/^\[.\] /[x] /g' | sed 's|/|\\/|g')"
            else
                NEWANSWER="$(echo "$ANSWER" | sed 's/^\[.\] /[ ] /g' | sed 's|/|\\/|g')"
            fi
            sed -i "s/^\[.\] ${LINENUMBER}[^0-9][^0-9]*.*/$NEWANSWER/g" "$AFILE"
        fi
    done

    ;;

-E) # edit list
    # add line numbers
    # echo list | imenu -E title addcommand
    shift 1
    numlines() {
        nl | grep -o '[0-9][0-9]*.*' |
            sed 's/^\([0-9][0-9]*\)./\1 /g'
    }

    rmnums() {
        LIST="$(sed 's/^[0-9]* //g' <<<"$NUMBERLIST")"
    }

    # move line n up
    linedown() {
        if [ "$1" -gt "$MAXNUMBER" ]; then
            echo "$NUMBERLIST"
            return
        fi
        NUM2="$(($1 + 1))"
        sed "$1{h;d};${NUM2}G" </dev/stdin
    }

    # move line n down
    lineup() {
        if [ "$1" -lt 2 ]; then
            echo "$NUMBERLIST"
            return
        fi
        linedown "$(($1 - 1))"
    }

    itemmenu() {
        if ! climenu; then
            echo "{blue icon=angles-up} move to top
{blue icon=chevron-up} move up
{blue icon=arrow-left} back
{blue icon=chevron-down} move down
{blue icon=angles-down} move to the bottom
{red icon=trash} remove" | imenu -l -i -s 2 "$1"
        else
            echo "move to top
move up
back
move down
move to the bottom" | imenu -l "$1"
        fi
    }

    if [ -n "$2" ]; then
        ITEMCOMMAND="$2"
    else
        ITEMCOMMAND="ls ~/ | imenu -l"
    fi

    LIST="$(cat /dev/stdin)"
    MAXNUMBER="$(("$(wc -l <<<"$LIST")" - 1))"

    while :; do
        NUMBERLIST="$(numlines <<<"$LIST")"
        LPRESELECT="${ITEMNUMBER:-0}"
        ITEM="$({
            # TODO: add checkmark
            echo "{green icon=check} Ok"
            # TODO: add plus sign
            echo "{green icon=plus} Add item"
            echo "$NUMBERLIST"
        } | grep "." | imenu -l -s "$((LPRESELECT + 1))" "${1:-edit list}")"
        case "$ITEM" in
        *Ok)
            echo "$LIST"
            exit
            ;;
        "Add item")
            ADDEDITEM="$(eval "$ITEMCOMMAND")"
            if [ -n "$ADDEDITEM" ]; then
                LIST="$LIST
$ADDEDITEM"
            fi
            continue

            ;;
        *)
            ITEMCHOICE="$(itemmenu "$ITEM")"
            ITEMNUMBER="$(grep -o '^[0-9]*' <<<"$ITEM")"
            case "$ITEMCHOICE" in
            *up)
                NUMBERLIST="$(echo "$NUMBERLIST" | lineup "$ITEMNUMBER")"
                rmnums
                ;;
            *down)
                NUMBERLIST="$(echo "$NUMBERLIST" | linedown "$ITEMNUMBER")"
                rmnums
                ;;
            *top)
                NUMBERLIST="$(echo "$ITEM" && sed "/^$ITEMNUMBER /d" <<<"$NUMBERLIST")"
                rmnums
                ;;
            *bottom)
                NUMBERLIST="$(sed "/^$ITEMNUMBER /d" <<<"$NUMBERLIST" && echo "$ITEM")"
                rmnums
                ;;
            *remove)
                NUMBERLIST="$(sed "/^$ITEMNUMBER /d" <<<"$NUMBERLIST")"
                rmnums
                ;;
            *)
                true
                ;;
            esac

            ;;
        esac
    done

    ;;

*)
    echohelp
    ;;
esac
