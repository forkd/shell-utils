#!/bin/bash
#enum4linux.sh
#
# Compile John The Ripper Jumbo version.  The
# `make install` option did't work here, so
# this John must be executed from: 
# $target_path/JohnTheRipper/run.
# This script must be executed as ROOT.
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
patch_180j1="
483c483,485
< #define MAYBE_INLINE_BODY MAYBE_INLINE
---
> //Patch by: https://github.com/magnumripper/JohnTheRipper/issues/1093
> //#define MAYBE_INLINE_BODY MAYBE_INLINE
> #define MAYBE_INLINE_BODY
"

dnf install openssl-devel

wget https://github.com/magnumripper/JohnTheRipper/archive/1.8.0-jumbo-1.zip -O "$target_path/john-jumbo.zip"
unzip "$target_path/john-jumbo.zip" -d "$target_path"
patch "$target_path/JohnTheRipper-1.8.0-jumbo-1/src/MD5_std.c" <<< "$patch_180j1"

cd "$target_path/JohnTheRipper-1.8.0-jumbo-1/src"
./configure
cd -

make -C "$target_path/JohnTheRipper-1.8.0-jumbo-1/src"
rm -rf "$target_path/john-jumbo.zip"

