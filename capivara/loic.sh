#!/bin/bash
#loic.sh
#
# LOIC was originally written for Windows environments,
# but it can be executed under Linux with Mono or 
# Wine.  This script ensures Mono is installed, then
# download and "install" LOIC on the system.
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
loic_script="
#!/bin/bash
#loic.sh
# https://github.com/forkd/capivara
##
mono /usr/local/bin/LOIC.exe
"
loic_config="
<?xml version="1.0" encoding="utf-8"?>
<configuration><appSettings>
  <add key="AcceptEULA" value="1" />
  </appSettings>appSettings>
</configuration>
"

dnf install mono-devel

wget https://github.com/NewEraCracker/LOIC/releases/download/2.0.0.4/LOIC_2.0.0.4.zip -O "$target_path/loic.zip"
unzip "$target_path/loic.zip" -d "$target_path/loic"
cp "$target_path/loic/LOIC.exe" /usr/local/bin
echo "$loic_script" > /usr/local/bin/loic.sh
echo "$loic_config" > /usr/local/bin/LOIC.exe.config
chmod 755 /usr/local/bin/LOIC.exe /usr/local/bin/loic.sh /usr/local/bin/LOIC.exe.config
rm -rf "$target_path/loic.zip" "$target_path/loic"

