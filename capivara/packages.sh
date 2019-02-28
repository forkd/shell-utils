#!/bin/bash
#packages.sh
#
# Installs some community maintained packages used 
# for pentesting in Fedora 25.  Must be executed 
# as ROOT.
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

dnf install finger \
    hping3 fping \
    wireshark wireshark-gtk \
    nmap nmap-frontend \
    hydra hydra-frontend \
    john ophcrack

