#!/bin/bash
#slowloris.sh
#
# Slowloris installer.  Must be executed as ROOT.
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

dnf install perl-CPAN
perl -MCPAN -e 'install Test::More'  # needed to SSL
perl -MCPAN -e 'install IO::Socket::INET'  # may require some user interaction
perl -MCPAN -e 'install IO::Socket::SSL'  # may require some user interaction

cp 3rd-party/slowloris.pl /usr/local/bin
chmod 755 /usr/local/bin/slowloris.pl

