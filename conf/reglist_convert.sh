#!/bin/bash

# Starship Project
# Copyright (C) 2020-2022 by phantom
# Email: phantom@zju.edu.cn
# This file is under MIT License, see https://www.phvntom.tech/LICENSE.txt

set -e
# set -x

help() {
echo "Script to convert register list file to other format.
Usage: reglist_convert [OPTIONS] [INPUT FILE]
   [ -o | --output]  output file name
   [ -H | --help  ]  help
   [ -p | --prefix]  prefix string of each line
   [ -s | --subfix]  subfix string of each line
   [ -h | --head  ]  file header
   [ -t | --tail  ]  file tail
   [ -P | --path  ]  path separator"
    exit 2
}

SHORT=o:,H,p:,s:,h:,t:,P:
LONG=output:,help,prefix:,subfix:,head:,tail:,path:
OPTS=$(getopt -n reglist_convert --options $SHORT --longoptions $LONG -- "$@")

eval set -- $OPTS

PATHSEP=.

while :
do
  case "$1" in
    -o | --output )
      OUTPUT="$2"
      shift 2
      ;;
    -p | --prefix )
      PREFIX="$2"  
      shift 2
      ;;
    -s | --subfix )
      SUBFIX="$2"
      shift 2
      ;;
    -h | --head )
      HEAD="$2"
      shift 2
      ;;
    -t | --tail )
      TAIL="$2"
      shift 2
      ;;
    -P | --path )
      PATHSEP="$2"
      shift 2  
      ;;
    -H | --help)
      help
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      help
      ;;
  esac
done

if [ -z $OUTPUT ]; then
	help
fi

BACKUP=$(mktemp)
sed "/; \/\/ Total/d" $1 >> $BACKUP

echo -e "$HEAD" > $OUTPUT

sed "s/^[_0-9a-zA-Z]*/$PREFIX/g" $BACKUP | sed "$ !s/$/$SUBFIX/g" | sed "s/\./$PATHSEP/g" >> $OUTPUT

echo -e "$TAIL" >> $OUTPUT

rm $BACKUP

