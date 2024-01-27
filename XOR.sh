#!/bin/bash

# requirements:
#
# md5
# cut
# tr
# base64
#

Asc() { printf '%d' "'$1"; }
HexToDec() { printf '%d' "0x$1"; }

XOREncrypt(){
    local key="$1" DataIn="$2"
    local ptr DataOut val1 val2 val3

    for (( ptr=0; ptr < ${#DataIn}; ptr++ )); do

        val1=$( Asc "${DataIn:$ptr:1}" )
        val2=$( Asc "${key:$(( ptr % ${#key} )):1}" )

        val3=$(( val1 ^ val2 ))

        DataOut+=$(printf '%02x' "$val3")

    done
    printf '%s' "$DataOut"
}

XORDecrypt() {

    local key="$1" DataIn="$2"
    local ptr DataOut val1 val2 val3

    local ptrs
    ptrs=0

    for (( ptr=0; ptr < ${#DataIn}/2; ptr++ )); do

        val1="$( HexToDec "${DataIn:$ptrs:2}" )"
        val2=$( Asc "${key:$(( ptr % ${#key} )):1}" )

        val3=$(( val1 ^ val2 ))

        ptrs=$((ptrs+2))

        DataOut+=$( printf \\$(printf "%o" "$val3") )

    done
    printf '%s' "$DataOut"
}

Operation="$1"

CodeKey="$( md5 -s "$2" | cut -d'=' -f 2 | tr -d ' ')"

read -r teststring

if [ "$Operation" == "enc" ] || [ "$Operation" == "encrypt" ]; then
    teststring="$( echo "$teststring" | base64 )"
    XOREncrypt "$CodeKey" "$teststring"
elif [ "$Operation" == "dec" ] || [ "$Operation" == "decrypt" ]; then
    XORDecrypt "$CodeKey" "$teststring" | base64 -D
fi
