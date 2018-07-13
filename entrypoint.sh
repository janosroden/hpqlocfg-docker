#!/bin/bash

rootTag="$HPQLOCFG_ROOT_TAG"
tempInput=/tmp/ribcl.tmp.xml
hpCmdLog=/tmp/hpqlocfg.log
rm -f $tempInput $hpCmdLog

iloArgs=( )
xmllintArgs=( --format )

while [[ $# -gt 0 ]]; do
    if [[ $1 = --xpath ]]; then
        shift
        xmllintArgs=( "${xmllintArgs[@]}" --xpath "$1" )
        shift
    elif [[ $1 = -s ]]; then
        shift
        iloServer="$1"
        shift
    elif [[ $1 = -u ]]; then
        shift
        iloUser="$1"
        shift
    elif [[ $1 = -p ]]; then
        shift
        iloPassword="$1"
        shift
    elif [[ $1 = -f && $2 = - ]]; then               # Read from stdin
        shift
        shift
        cat > $tempInput
        iloArgs=( "${iloArgs[@]}" -f $tempInput )
    elif [[ $1 = -f && -f $2 && $2 != *.xml ]]; then # Allow file extensions other than .xml
        ln -sfn $2 $tempInput
        shift
        shift
        iloArgs=( "${iloArgs[@]}" -f $tempInput )
    else
        iloArgs=( "${iloArgs[@]}" "$1" )
        shift
    fi
done

if [[ -n ${iloServer+x} ]]; then
    iloArgs=( "${iloArgs[@]}" -s "$iloServer" )
elif [[ -n $ILO_SERVER ]]; then
    iloArgs=( "${iloArgs[@]}" -s "$ILO_SERVER" )
fi

if [[ -n ${iloUser+x} ]]; then
    iloArgs=( "${iloArgs[@]}" -u "$iloUser" )
elif [[ -n $ILO_USER ]]; then
    iloArgs=( "${iloArgs[@]}" -u "$ILO_USER" )
fi

if [[ -n ${iloPassword+x} ]]; then
    iloArgs=( "${iloArgs[@]}" -p "$iloPassword" )
elif [[ -n $ILO_PASSWORD ]]; then
    iloArgs=( "${iloArgs[@]}" -p "$ILO_PASSWORD" )
fi

WINEDEBUG=-all wine /bin/hp/HPQLOCFG.exe "${iloArgs[@]}" | \
   tr -d '\r' | \
   tee $hpCmdLog | \
   grep -e '^<' -e '^ ' | \
   grep -v '<\?xml' | \
   {
       output="$(cat)"
       if [[ -z $output ]]; then
          cat $hpCmdLog >&2
          exit 1
        elif [[ -n $rootTag ]]; then
            echo "<$rootTag>$output</$rootTag>" | xmllint "${xmllintArgs[@]}" -
        else
            echo "$output"
        fi
   }
