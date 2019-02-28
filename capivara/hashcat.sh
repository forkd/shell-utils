#!/bin/bash
#hashcat.sh
#
# Hashcat is a password recovery tool.  It has no
# package for Fedora, so must be compiled.  Must be 
# executed as ROOT.
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

dnf install opencl-utils-devel

wget https://github.com/hashcat/hashcat/archive/master.zip -O "$target_path/hashcat.zip"
unzip "$target_path/hashcat.zip" -d "$target_path"
make --directory="$target_path/hashcat-master" && make --directory="$target_path/hashcat-master" install
rm -rf "$target_path/hashcat.zip" "$target_path/hashcat-master"

