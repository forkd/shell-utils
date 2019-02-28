#!/bin/bash
#set.sh
#
# Social Engineer Toolkit (SET) installer based on 
# Fedora 25, but should work on any Linux distro.
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

wget https://github.com/trustedsec/social-engineer-toolkit/archive/master.zip -O "$target_path/set.zip"
unzip "$target_path/set.zip" -d "$target_path"
python "$target_path/social-engineer-toolkit-master/setup.py" install
rm -rf "$target_path/set.zip" "$target_path/social-engineer-toolkit-master"

