#!/bin/bash

print_usage() {
        printf '
        5head.sh usage: [-h] [-t targetfile] write this later

        mandatory arguments:
          -t TARGETFILE         Newline-delimmited list of targets. Accepts CIDRs or ranges (192.168.0.1-255)
          -i INTERFACE          Interface to use for network traffic

        useful arguments:
          -u USERNAME           Username to use for authentication
          -p PASSWORD           Password to use for authentication
          -d DOMAIN             Specific domain to perform authentication attempts on (NOT IMPLEMENTED YET)
          -s SAFE               Safe mode. Will not try to authenticate (YOU THOUGHT THIS WAS IMPLEMENTED?)

        optional arguments:
          -v VERBOSE            Print verbose output (THIS ISNT IMPLEMENTED EITHER)
          -h                    Print this helpmenu
';
}

if [[ $* == *-h ]]; then
        print_usage
        exit 1;
fi


### Argument helper
while getopts ":t:d:u:p:i:" o; do
    case "${o}" in
        t)
            targets=${OPTARG}
            ;;
        d)
            domain=${OPTARG}
            ;;
        u)
            username=${OPTARG}
            ;;
        p)
            password=${OPTARG}
            ;;
        i)
            interface=${OPTARG}
            ;;
        *)
            print_usage
            ;;
    esac
done
shift $((OPTIND-1))

## Debug

#echo $targets
#echo $domain
#echo $username
#echo $password
#echo $interface

### Tmux bootstrapping
if [ -z "${TMUX}" ]; then
        export session="5head"
        export targets=$targets
        export domain=$domain
        export username=$username
        export password=$password
        export interface=$interface
        export PROMPT="%F{9}5head.sh%f > "
        window=0
        tmux new-session -d -s $session ./5head.sh
        tmux rename-window -t $session:$window 'main'
        tmux attach-session -t $session
        exit 1;
fi

### Colors
green='\e[32m'
cyan='\e[96m'
red='\e[91m'
clear='\e[0m'

ColorGreen () {
        echo -ne $green$1$clear
}
ColorCyan () {
        echo -ne $cyan$1$clear
}
ColorRed () {
        echo -ne $red$1$clear
}

## Main part executing inside of tmux
function packet_cap() {
        echo -e '[*] Starting packet captured in "packet_cap" window...\n\n'
        tmux new-window -n "packet_cap"
        tmux send-keys -t 5head:packet_cap 'PROMPT="%F{9}5head.sh%f > "' C-m
        tmux send-keys -t 5head:packet_cap 'clear' C-m
        tmux send-keys -t 5head:packet_cap 'echo "[*] Starting packet capture on ${interface}..."' C-m
        tmux send-keys -t 5head:packet_cap 'echo "[*] Output will be written to loot/packet_capture.pcap"' C-m
        tmux send-keys -t 5head:packet_cap 'tcpdump -i $interface -w loot/packet_capture.pcap' C-m
}

function cme_enum() {
        echo -e '[*] Enumerating targets with CrackMapExec...\n\n'
        tmux new-window -n "cme_enum"
        tmux send-keys -t 5head:cme_enum 'PROMPT="%F{9}5head.sh%f > "' C-m
        tmux send-keys -t 5head:cme_enum 'clear' C-m
        tmux send-keys -t 5head:cme_enum 'cd CrackMapExec; poetry run crackmapexec smb ../$targets >> ../loot/cme_enum.txt' C-m
        tmux split-window -v -l 80%
        tmux send-keys -t 5head:cme_enum 'PROMPT="%F{9}5head.sh%f > "' C-m
        tmux send-keys -t 5head:cme_enum 'clear' C-m
        tmux send-keys -t 5head:cme_enum 'echo -e "[*] Reading CrackMapExec enum results as they are discovered...\n[\!] Periodically press enter in pane above to ensure completion...\n"' C-m
        tmux send-keys -t 5head:cme_enum 'tail -f loot/cme_enum.txt' C-m
}

function resp_ntlmrelay_1() {
	echo -e '[*] Setting up Responder + Ntlmrelayx.py (SAM dump)...\n\n'
	tmux new-window -n "relay"
	tmux send-keys -t 5head:relay 'PROMPT="%F{9}5head.sh%f > "' C-m
	tmux send-keys -t 5head:relay 'clean' C-m
	tmux send-keys -t 5head:relay '
}


function debug() {
        echo "test"
        tmux show-environment
        env
}


## Main function area
printf '
    ____                                  __        __          __
   / __ \___  ____  ___  ____ _____ _____/ /__     / /   ____ _/ /_  _____
  / /_/ / _ \/ __ \/ _ \/ __ `/ __ `/ __  / _ \   / /   / __ `/ __ \/ ___/
 / _, _/  __/ / / /  __/ /_/ / /_/ / /_/ /  __/  / /___/ /_/ / /_/ (__  )
/_/ |_|\___/_/ /_/\___/\__, /\__,_/\__,_/\___/  /_____/\__,_/_.___/____/
                      /____/
'

echo "[*] Starting 5head.sh..."
if [ ! -d "./loot" ]; then
        mkdir loot
fi
touch ~/.hushlogin
PROMPT="%F{9}5head.sh%f > "

### Menu Stuff
menu(){
echo -ne "
~ 5head.sh ~
$(ColorGreen '1)') Packet capture + search for suspicious traffic
$(ColorGreen '2)') Enumerate targets with CrackMapExec
$(ColorGreen '3)') Setup Responder + Ntlmrelayx.py (prereq: 2)
$(ColorGreen '4)') Search for ASREPRoastable users
$(ColorGreen '5)') Search for Kerberoastable users $(ColorRed 'Creds required')
$(ColorGreen '6)') Enumerate hosts for authentication coercion mechanisms $(ColorRed 'Creds required')
$(ColorGreen '7)') Enumerate shares on target hosts $(ColorRed 'Creds required')
$(ColorGreen '8)') Search for ADCS targets $(ColorRed 'Creds required')
$(ColorGreen '9)') Run the Python Bloodhound ingestor - Note: YMMV $(ColorRed 'Creds required')
$(ColorGreen '0)') Background 5head.sh
$(ColorGreen 'ash)') debugger
$(ColorCyan 'Choose a task:') "
        read a
        case $a in
                1) packet_cap ; menu ;;
                2) cme_enum ; menu ;;
                0) tmux detach ;;
                ash) debug ; menu ;;
                *) echo "Invalid command entered"; menu ;;
        esac
}

menu

## To-do
# 1. Need a dependenacy checker startup thing
# 2. need env variable + variable safety checker exeter thing
