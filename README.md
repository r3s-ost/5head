<p align="center">
  <img src="https://user-images.githubusercontent.com/51839088/177005677-e86231f7-1843-47f8-a58d-3fb59bade7ca.png">
</p>

# 5head.sh
5head.sh is a wrapper of a series of common network penetration testing toolsets within a portable and modular scripting platform that quickly allows network penetration testers to perform repeatable tasks. The tool was written with the goal of allowing operators to automate the boring stuff and focus on custom attack paths. 

The [tmux](https://github.com/tmux/tmux/wiki) terminal multiplexer is heavily utilized for job management. 5head.sh was purposefully written with a BYOT.conf (Bring-Your-Own-Tmux.conf) mindset, so a custom tmux.conf is not provided. 

Development and testing was performed within a fresh install of Kali Linux to simulate the broadest use case across. It has not been tested on alternate *NIX platforms.

This repo also contains a `setup.sh` installation script, which will configure the neccessary copies of tools needed for 5head.sh's modules. This allows operators to still utilize alternate versions/forks of tooling that will not conflict with the copies used by 5head.sh.

## Installation
To begin installation of 5head.sh, cloen the repo:
```bash
git clone https://github.com/Renegade-Labs/5head.sh
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

### Mandatory Arguments
#### Targets file


#### Interface
Run `ip a` and locate the appropriate network interface to pass to this argument.

This allows 5head.sh to be aware of what network interface to bind to for traffic poisoning attacks.

### Recommended Usage
It is heavily recommended to supply the following arguments to 5head.sh:
- `-d DOMAIN`
- `-c DOMAIN CONTOLLER`
- `-u USERNAME`
- `-p PASSWORD`

If these are not supplied, the toolset will prompt for you to provide them when neccessary. Without credentials much of the functionality will not work.

For `-c DOMAIN CONTOLLER` it is recommended to utilize the FQDN of the domain contoller you would like to target. This will require `/etc/resolv.conf` to be configured with a working DNS server (often times the same domain contoller).

## Modules

### Enum

### Poison

### AD


## Support
5head.sh heavily utilizes CrackMapExec for much of the activity it performs. If you are feeling generous please support CrackMapExec and other open-source security tools through a subscription to [Porchetta Industries](https://porchetta.industries/).
