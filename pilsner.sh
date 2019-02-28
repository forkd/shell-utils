#!/usr/bin/env bash
#pilsner.sh
#
# Assistant to backup files to an external HDD.
#
# Author: José Lopes
# License: MIT
# Date: 2016-07-15
##


set -euo pipefail  # Bash's strict mode

from=""
to=""
logfile=".pilsner/pilsner-$(date -u +"%Y-%m-%d").log"
usage="
USAGE: pilsner.sh [OPTIONS]
OPTIONS
 -h, --help             Display this message and exit
 -f, --from [PATH]      Path to original files to sync --reference is $HOME
 -t, --to [PATH]        Path to destination directory on external HDD
 -s, --sync             Backup to [TARGET]
 -c, --clean            Delete junk files in [TARGET]

EXAMPLES
  $ pilsner.sh -f \"Documents Movies\" -t \"/media/pilsner\" -s -c
"


sync() {
    # USAGE: sync $to $backup_dirs
    # rsync options:
    # -a: archive mode
    # -H: preserve hard-links
    # -h: human readable numbers
    # -x: don't cross file system boundaries
    # -v: increase verbosity
    # --numeric-ids: don't map UID/GID values
    # --delete: delete extraneous files from destination directories
    # --progress: show progress during transfer
    # --stats: print statistics
    # --exclude: files to avoid syncing
    # --out-format: output format
    # --log-file-format: as it says
    # --log-file: one log file to rule'em all
    ##
    while [ -n "${1:-}" ]; do
        logger "info" "Syncing $2 -> $1"
        rsync -aHhxv --numeric-ids --delete --progress --stats \
            --exclude=".DS_Store" --exclude=".fseventsd" \
            --exclude=".Spotlight-V100" --exclude=".Trashes" \
            --exclude=".com.apple*" --exclude="._*" \
            --out-format="RSYNC: %f %b bytes" \
            --log-file-format="RSYNC: %f %b bytes" --log-file="$logfile" \
            "$2" "$1"
        shift
    done
}

clean() {
    logger "info" "Cleaning $1"
    find "$1" \( -name ".DS_Store" -o -name ".fseventsd" \
        -o -name ".Spotlight-V100" -o -name ".Trashes" -o -name ".com.apple*" \
        -o -name "._*" \) -exec rm -rf {} \;
}

logger() {
    # USAGE: logger LEVEL MESSAGE
    case "$1" in
        "info") log="INFO: $2" ;;
        "warning") log="WARNING: $2" ;;
        *)
            echo "$(date -u +"%Y%m%dT%H%M%SZ")  ERROR: $2" |tee -a "$logfile"
            exit 1
            ;;
    esac
    echo "$(date -u +"%Y%m%dT%H%M%SZ")  $log" |tee -a "$logfile"
}


while [ -n "${1:-}" ]; do
    case "${1:-}" in
        -f | --from) shift; from="$1" ;;
        -t | --to) shift; to="$1" ;;
        -s | --sync) will_sync="true" ;;
        -c | --clean) will_clean="true" ;;
        -h | --help) echo "$usage"; exit 0 ;;
        *) echo "$usage"; exit 1 ;;
    esac
    shift
done

cd $HOME
[ ! -d .pilsner ] && mkdir .pilsner
[ ! -e "$logfile" ]  && touch "$logfile"

# Original files check
if [ ! -z "$from" ]; then
    for dirfile in $from; do
        [ ! -r "$dirfile" ] && logger "error" "Can't read $dirfile"
    done
else
    logger "error" "Original files must be set: -f option"
    exit 1
fi

# Target check
if [ ! -z "$to" ]; then
    [ ! -w "$to" ] && logger "error" "Can't write on $to"
else
    logger "error" "Target must be set: -t option"
    exit 1
fi

[ -n "${will_sync:-}" ] && sync "$to" $from  # don't use double quotes here
[ -n "${will_clean:-}" ] && clean "$to"
