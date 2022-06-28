#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run me as root"
  exit
fi

## Package + Poetry install
echo "[*] Installing package dependencies..."
apt-get install -y python3-venv
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
wget https://github.com/byt3bl33d3r/CrackMapExec/releases/download/v5.2.2/cme-ubuntu-latest.zip -O deps/cme-ubuntu-latest.zip
unzip deps/cme-ubuntu-latest.zip -d deps
chmod +x deps/cme
echo "[+] CME downloaded"

## Responder setup
git clone https://github.com/lgandx/Responder deps/Responder
sed -i 's/ Random/ 1122334455667788/g' deps/Responder/Responder.conf
sed -i 's/SMB = On/SMB = Off/g' deps/Responder/Responder.conf
sed -i 's/HTTP = On/HTTP = Off/g' deps/Responder/Responder.conf


## Impacket install
wget https://github.com/SecureAuthCorp/impacket/releases/download/impacket_0_10_0/impacket-0.10.0.tar.gz -O deps/impacket-0.10.0.tar.gz
tar xvf deps/impacket-0.10.0.tar.gz -C deps/
rm deps/impacket-0.10.0.tar.gz
cd deps/impacket-0.10.0
virtualenv -p python3 .
source bin/activate
python3 -m pip install .
pip install dsinternals
deactivate
cd ../../

