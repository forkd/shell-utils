#!/bin/bash
#crunch.sh
#
# Crunch is a wordlist generator.  This script
# downloads, compiles, and installs it in the server.
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

wget https://downloads.sourceforge.net/project/crunch-wordlist/crunch-wordlist/crunch-3.6.tgz -O "$target_path/crunch.tgz"
tar -xzvf "$target_path/crunch.tgz" --directory="$target_path"
make -C "$target_path/crunch-3.6" && make -C "$target_path/crunch-3.6" install
rm -rf "$target_path/crunch.tgz" "$target_path/crunch-3.6"

