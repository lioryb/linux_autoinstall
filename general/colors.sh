#!/bin/bash

function define_colors
{
    _CBLK=0
    _CRED=1
    _CGRN=2
    _CORG=3
    _CBLU=4
    _CPUR=5
    _CCYN=6
    _CGRY=7

    _CNONE=9

    _NC='\033[0m' # No Color

    _FG=30 # foreground
    _BG=40 # background
}

function set_color
{
    # see https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
    local fg=$(($1 + $_FG))
    local attr=
    local bg=
    case $# in
        3)
            attr="${3};"
            ;& # fall-through
        2)  
            bg="$(($2 + $_BG));"
            ;;
    esac

    echo "\033[${attr}${bg}${fg}m"
}


function undef_colors
{
    unset _CBLK
    unset _CRED
    unset _CGRN
    unset _CORG
    unset _CBLU
    unset _CPUR
    unset _CCYN
    unset _CGRY
    unset _NC
    unset _FG
    unset _BG

    unset define_colors
    unset undef_colors
}
