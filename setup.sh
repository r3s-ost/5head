#!/bin/bash

echo "[*] Installing package dependencies..."
apt-get install -y libssl-dev libffi-dev python-dev build-essential
echo "[+] Packages installed"
echo "[*] Installing Poetry..."
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
echo "[+] Poetry installed"
echo "[*] Installing CME + Poetry..."
git clone --recursive https://github.com/byt3bl33d3r/CrackMapExec
cd CrackMapExec
poetry install
poetry run crackmapexec
echo "[+] CME + Poetry installed"
cd ../
if [ ! -d "./loot" ]; then
        mkdir loot
fi
