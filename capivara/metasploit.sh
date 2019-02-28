#!/bin/bash
#metasploit.sh
#
# Metasploit installer.  It was based on Fedora 25,
# but should run in any Linux distribution.  
# Must be executed as ROOT.
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

wget https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb -O "$target_path/msfinstall"
bash "$target_path/msfinstall"
rm -rf "$target_path/msfinstall"

