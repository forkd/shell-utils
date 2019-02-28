#!/bin/bash
#weback.sh
#
# Shit happens.  A multi-purpose backup system.  Weback saves all 
# server's files and databases.  These files are filled in the own
# server and sent to Dropbox.
#
# Author: José Lopes
# License: MIT
# Date: 2013-03-08
##


SERVER="Weback"
SOURCE=0        # Backup files?
TOADDRS=0       # Send email?
MYSQL_USER=0    # Backup MySQL?
MYSQL_PASS=0
MYSQL_HOST=0
DROPBOX=0       # Mirror in Dropbox?
TODAY="$(date +%Y%m%d%H%M)"
GENERAL="weback-$TODAY.tar.gz"
FILES="weback-files-$TODAY.tar.gz"
MYSQL="weback-mysql-$TODAY.tar.gz"
SUMS="SHA1SUMS"
TARGET="$HOME/weback/ark"
KEEP=0  # Number of backups to keep.
KEEP_REGEX="^[0-9]+$"
LOG="Weback $TODAY: Backup Log -- "
USAGE="
USAGE: "${0##*/}" -h | -V | [OPTIONS]
 -h, --help     Display this message and exit
 -V, --version  Display the current version and exit

OPTIONS
 -n, --name     Set the server name
 -s, --source   Backup root; the origin of files
 -t, --target   Set default backup target
 -k, --keep     Keep only the last X backups
 -m, --mysql    MySQL data
 -d, --dropbox  Dropbox data
 -e, --email    E-mail address

EXAMPLES
 $ "${0##*/}" -s $HOME -e foo@example.com -m foo:bar:localhost
 $ "${0##*/}" -s $HOME/public_html -d foo:bar -k 3
 $ "${0##*/}" -n MyServer -s $HOME/public_html -t /var/local/web
"


bkp_files() {
# Saves all directories inside $SOURCE.
#
    cd "$SOURCE"
    # Saves all files [and directories] under $1.
    # Must avoid copying the . and weback directories.
    find . -maxdepth 1 ! -name . ! -name weback -print0 |
        xargs -0 tar -czf "$TARGET/$FILES"
    cd "$TARGET"
    
    return $?
}

bkp_mysql() {
# Saves all MySQL server databases.
#
    cd "$TARGET"

    for db in $(mysql --user="$MYSQL_USER" --password="$MYSQL_PASS" \
	              --host="$MYSQL_HOST" -Bse 'show databases' |
                sed -e "/^information_schema$/d; /^mysql$/d"); do
        mysqldump --opt --user="$MYSQL_USER" --password="$MYSQL_PASS" \
                  --host="$MYSQL_HOST" \
                  "$db" > "${SERVER}-mysql-${db}-${TODAY}.sql"
    done

    tar -czf "$MYSQL" *.sql
    rm -f *.sql

    return $?
}

sendfile() {
# Mirror the backup in Dropbox using dropbox_uploader.sh v0.11.2.
# You'll first need to add the Dropbox key.  Run the line below in
# your command shell and follow the steps on the screen.
# Dropbox Uploader: https://github.com/andreafabrizi/Dropbox-Uploader
#
    ${HOME}/weback/dbu/dropbox_uploader.sh upload
                                           "$TARGET/$GENERAL"
                                           "/weback/$GENERAL"

    return $?
}


garbage_collector() {
# Create a list of backup files and a list of files that shouldn't
# be deleted.  Remove all files in list 2 from list 1.  Delete all
# files from list 1.  That easy. ;-)
#
    local files="$(/bin/ls -t |tr '\n' ' ')"
    local dont_delete="$(/bin/ls -t |sed '/SHA1SUMS/d' |head -"$KEEP")"

    for file in $dont_delete; do
        files="$(echo $files |sed 's/'$file'//')"
    done
    
    ! [ -z "$files" ] && rm -rf $files
    return $?
}

checksum() {
# Computes the file's SHA-1 checksum and stores it in a file.
# After generated, checksums can be verified with:
#     $ sha1sum -c SHA1SUMS
#
    # File exists: checksum-it.
    if [ -e "$SUMS" ]; then
        sha1sum "$1" >> "$SUMS"
    
    # File doesn't exist.  Calcs the checksum for all files in
    # the directory.
    else
        for index in *; do
            [ -f "$index" ] && sha1sum "$index" >> "$SUMS"
        done
    fi

    return $?
}

sendmail() {
# Sends an email with the operation's log.
#
    local subject="Weback: New ${SERVER}'s Backup"
    echo -e "$LOG" |mail -s "$subject" "$TOADDRS"

    return $?
}


while [ -n "$1" ]; do
    case "$1" in
        -n | --name) 
            shift; 
            SERVER="$1"
            GENERAL="$(echo $SERVER |tr [A-Z] [a-z])-$TODAY.tar.gz"
            FILES="$(echo $SERVER |tr [A-Z] [a-z])-files-$TODAY.tar.gz"
            MYSQL="$(echo $SERVER |tr [A-Z] [a-z])-mysql-$TODAY.tar.gz"
            ;;

        -s | --source) shift; SOURCE="$1" ;;

        -m | --mysql)
            shift
            MYSQL_USER="$(echo "$1" |cut -d: -f1)"
            MYSQL_PASS="$(echo "$1" |cut -d: -f2)"
            MYSQL_HOST="$(echo "$1" |cut -d: -f3)"
            ;;

        -k | --keep)
            shift;
            if [[ $1 =~ $KEEP_REGEX ]]; then
                KEEP="$1"
            else
                echo "Integer value expected instead: $1"
                exit 1
            fi
            ;;

        -d | --dropbox) DROPBOX=1 ;;
        -e | --email) shift; TOADDRS="$1" ;;
        -h | --help) echo "$USAGE"; exit 0 ;;

        -t | --target)
            shift
            TARGET="$1"
            [ ! -e "$TARGET" ] && mkdir -p "$TARGET"

            if [ ! -d "$TARGET" ] || [ ! -w "$TARGET" ]; then
                echo -e "Could not create target directory.\nTARGET: $TARGET"
                exit 1
            fi
            ;;

        -V | --version)
            echo -e "\nWeback\n\n$(cat "$0" | sed -n "4,24p" |cut -c 3-)\n"
            exit 0
            ;;

        *)
            echo -e "Weback: Invalid argument - $1\n"
            exit 1
            ;;
    esac
    shift  # Next argument, please. :)
done

# Create local destination folder if it does not exist.
[ ! -d "$TARGET" ] && mkdir -p "$TARGET"

# Hey, ho! Let's go!
cd "$TARGET"

# Backup files...
[ "$SOURCE" != "0" ] && { LOG="$LOG FILES:"; bkp_files; }

# Backup MySQL databases...
if [ "$MYSQL_USER" != "0" ] && [ "$MYSQL_PASS" != "0" ] &&
   [ "$MYSQL_HOST" != "0" ]; then
    LOG="$LOG MYSQL:"
    bkp_mysql
fi

# Join/Remove/Check files...
LOG="$LOG ZIP/DEL:"
if [ -e "$FILES" ] && [ -e $MYSQL ]; then
    tar -czf "$GENERAL" "$FILES" "$MYSQL"
    rm -f "$FILES" "$MYSQL"

elif [ -e "$FILES" ]; then
    mv "$FILES" "$GENERAL"

elif [ -e "$MYSQL" ]; then
    mv "$MYSQL" "$GENERAL"
fi
[ "$KEEP" != "0" ] && { LOG="$LOG ROTATE:"; garbage_collector; }
[ -e "$GENERAL" ] && { LOG="$LOG CHECK:"; checksum "$GENERAL"; }

# Send files...
[ "$DROPBOX" != "0" ] && { LOG="$LOG $(tail -1 $TARGET/$SUMS): DROPBOX:"; sendfile; }

# Send email...
[ "$TOADDRS" != "0" ] && { LOG="$LOG EMAIL:"; sendmail; }

exit $?
