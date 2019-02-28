#!/bin/bash
#enum4linux.sh
#
# enum4linux installer based on Fedora 25 
# environment.  Must be executed as ROOT.
#
# Copyright 2017 José Lopes de Oliveira Jr.
#
# Use of this source code is governed by a MIT-like
# license that can be found in the LICENSE file.
##


if [ "$UID" != "0" ]; then
    echo "Must be root"
    exit 1
fi

target_path="/tmp"

dnf install python-impacket openldap-clients samba samba-client

wget https://github.com/portcullislabs/enum4linux/archive/master.zip \
    -O "$target_path/enum4linux.zip"
wget https://github.com/RiskSense-Ops/polenum/archive/master.zip \
    -O "$target_path/polenum.zip"

for f in "$target_path/enum4linux.zip" "$target_path/polenum.zip"; do
    unzip "$f" -d "$target_path";
done

cp "$target_path/enum4linux-master/enum4linux.pl" \
    "$target_path/polenum-master/polenum.py" \
    /usr/local/bin

chmod 755 /usr/local/bin/enum4linux.pl /usr/local/bin/polenum.py

rm -rf "$target_path/enum4linux.zip" "$target_path/polenum.zip" \
    "$target_path/enum4linux-master" "$target_path/polenum-master"

