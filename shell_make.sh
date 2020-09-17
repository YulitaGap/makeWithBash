#!/usr/bin/env bash

## AUTHOR: Yulia Gapunovych


## exit the shell(default status code: 1) after printing the message to stderr
bail() {
    echo -ne "$1" >&2
    exit "${2-1}"
} 

## help message
declare -r HELP_MSG="Usage: make [options] [target] ...

    Options:
    -h, --help                  Print this message and exit.
    -f FILE                     Read FILE as a makefile. 
"

## print the usage and exit the shell(default status code: 2)
usage() {
    declare status=2
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        status=$1
        shift
    fi
    bail "${1}$HELP_MSG" "$status"
}

while getopts ":hf:" opt; do
  case ${opt} in
    h ) # process option h
       usage 0
      ;;

    f ) # process option f
    makefile=$OPTARG
      ;;

    : )
      echo "option requires an argument  -$OPTARG" 1>&2 && usage 0
      ;;

    *) # unsupported flags
      echo "Error: Unsupported flag $1"  && bail 
      ;;

  esac
done

if [ $# -eq 0 ]
  then
    echo "make: *** No targets specified and no makefile found.  Stop." && bail
fi

shift $((OPTIND -1))

#==========MAIN CODE BELOW==========

# reading makefile
if ! test -f "$makefile"; then
echo "make: $makefile : No such file or directory " && bail
fi 

declare -A target_prerequisites
declare -A target_commands

IFS=$'\n'
while read -r line; do
    if [[ $line == *:* ]]; then

    #splitting by ':'
        IFS=':' read -r -a parts <<<"$line"
        curr_target="${parts[0]}"
        curr_prerequisites="${parts[1]}"

    #check if already exists built target
        if  test -f "$curr_target"; then
        echo "make: $curr_target is up to date. " && bail
        fi 
    
    
    #splitting by ' '
        target_prerequisites["$curr_target"]=""
        if ! [ -z "$curr_prerequisites" ];
        then
        IFS=' ' read -ra prerequisites <<< "$curr_prerequisites"
            for i in "${prerequisites[@]}"
            do
                target_prerequisites["$curr_target"]+="$i"
            done
        fi 

    #getting commands for target
    elif ! [ -z "$line" ];then
        COMMAND="${line/$(printf '\t')/}"
        target_commands["$curr_target"]="$COMMAND"
    fi
done <"$makefile"

# building targets
for x in "${!target_prerequisites[@]}"; do
    dep="${target_prerequisites[$x]//[$'\t\r\n ']/}"
    com="${target_commands[$x]}"
    
    if ! [ -z "$dep" ];then 
        make "$dep"
    fi
    
    echo "$com"
    eval "${target_commands[$x]}"
done
