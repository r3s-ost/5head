#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run me as root"
  exit
fi

echo "[*] Logging verbose install output in install.log..."

## Package + Poetry install
echo "[*] Installing package dependencies..."
apt-get install -y python3-venv >> install.log
echo "[+] Packages installed"


## Folder structure scaffolding
echo "[*] Creating dependency directory..."
if [ ! -d "./deps" ]; then
	mkdir deps
fi
echo "[+] Dependency directory created"
echo "[*] Creating loot directory..."
if [ ! -d "./loot" ]; then
        mkdir loot
fi
echo "[+] Loot directory created"


## CME install
echo "[*] Grabbing CME..."
wget https://github.com/byt3bl33d3r/CrackMapExec/releases/download/v5.2.2/cme-ubuntu-latest.zip -O deps/cme-ubuntu-latest.zip &> /dev/null
unzip deps/cme-ubuntu-latest.zip -d deps >> install.log
chmod +x deps/cme
rm deps/cme-ubuntu-latest.zip
echo "[+] CME downloaded"

## Responder setup
echo "[*] Grabbing lgandx fork of Responder..."
git clone https://github.com/lgandx/Responder deps/Responder &> /dev/null
echo "[+] Responder downloaded"
echo "[*] Setting Responder.conf settings..."
sed -i 's/ Random/ 1122334455667788/g' deps/Responder/Responder.conf
sed -i 's/SMB = On/SMB = Off/g' deps/Responder/Responder.conf
sed -i 's/HTTP = On/HTTP = Off/g' deps/Responder/Responder.conf
echo "[+] Responder.conf configured"


## Impacket install
echo "[*] Installing Impacket..."
wget https://github.com/SecureAuthCorp/impacket/releases/download/impacket_0_10_0/impacket-0.10.0.tar.gz -O deps/impacket-0.10.0.tar.gz &> /dev/null
tar xvf deps/impacket-0.10.0.tar.gz -C deps/ >> install.log
rm deps/impacket-0.10.0.tar.gz
cd deps/impacket-0.10.0
virtualenv -p python3 . >> ../../install.log
source bin/activate
python3 -m pip install . >> ../../install.log
pip install dsinternals >> ../../install.log
deactivate
cd ../../
echo "[+] Impacket installed"


## Mitm6 install
echo "[*] Installing mitm6..."
pip install mitm6 --log install.log &> /dev/null
echo "[+] mitm6 installed"


## LdapRelayScan install
echo "[*] Installing LdapRelayScan..."
git clone https://github.com/zyn3rgy/LdapRelayScan deps/LdapRelayScan &> /dev/null
cd deps/LdapRelayScan
virtualenv -p python3 . >> ../../install.log
source bin/activate
pip install -r requirements.txt >> ../../install.log
deactivate
cd ../../
echo "[+] LdapRelayScan installed"

## bloodhound-python install
echo "[*] Installing bloodhound-python..."
pip install bloodhound --log install.log &> /dev/null
echo "[+] bloodhound-python installed"


echo "[+] Installation complete!"
