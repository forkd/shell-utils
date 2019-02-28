#!/bin/bash
#narkissos.sh
#
# Image manipulation tool in batch.  Narkissos can handle your
# image(s) in many ways like: set their filenames and datetime;
# normalize colors; resize to a defined value; and create thumbnails.
#
# Author: José Lopes
# License: MIT
# Date: 2012-12-03
##


PATH_=0
SIZE=0
NORMALIZE=0
FILENAME=0
DATETIME=0
THUMBNAILS=0
RECURSIVE=0
VERBOSE=0

THUMB_S="160x120"
THUMB_M="260x180"
THUMB_L="360x268"
USAGE="
USAGE: "${0##*/}" -h | -V | -p PATH [OPTIONS]
 -p, --path       Process an entire directory or a single file
 -h, --help       Display this message and exit
 -V, --version    Display the current version and exit

OPTIONS
 -s, --size       Change the default output size (1920 px)
 -n, --normalize  Normalize image's colors
 -f, --filename   Set the file name
 -d, --datetime   Set file's datetime according to its EXIF info
 -t, --thumbnails Generate image thumbnails

 -r, --recursive  Process subdirectories (should be used with -p only)
 -v, --verbose    Run in verbose mode

EXAMPLES
 $ "${0##*/}" -p ~/Pictures -f -d -n -s 700 -t
 $ "${0##*/}" -p ~/Pictures/handle-this -f -n -s 700 -t -v -r
"


size() {
# Resize an image to SIZE if it is bigger than that.
# $1 - Image to be resized.
# 
    local image_width=$(identify -format "%w" "$1")
    local image_height=$(identify -format "%h" "$1")
    local resize=""
    
    if [ "$image_width" -ge "$image_height" ]; then
        resize="${SIZE}x"
    else
        resize="x$SIZE"
    fi
    
    if [ "$NORMALIZE" != "0" ]; then
        [ "$image_width" -gt "$SIZE" ] && convert "$1" -resize "$resize" \
                                                  -normalize "$1"
    else
        [ "$image_width" -gt "$SIZE" ] && convert "$1" -resize "$resize" "$1"
    fi

    return $?
}

normalize() {
# Normalize the colors of an image.
# $1 - Image to be normalized.
#
    convert "$1" -normalize "$1"
    return $?
}

filename() {
# Redefine the name of a file.
# $1 - File to be analysed.
#
# Return
# New filename.
#
# Based on zzminusculas and zzarrumanome from 
# Funções ZZ (http://funcoeszz.net/)
#
# The file-exists test depends on filesystem type.
# Test result could differ in VBoxFS and Ext4, 
# for example.
#
    local newname=$(echo "$1" | 
                    sed -e "# Lower case
                        y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/
                        y/ÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇÑ/àáâãäåèéêëìíîïòóôõöùúûüçñ/
                       
                        # Delete accents
                        y/àáâãäåèéêëìíîïòóôõöùúûü/aaaaaaeeeeiiiiooooouuuu/
                        y/çñß¢Ð£Øø§µÝý¥¹²³/cnbcdloosuyyy123/
                       
                        # Delete conectives
                        s/ d[aeo]s\? /_/g
                       
                        # Delete single and double quotes
                        s/[\"']//g
                       
                        # Trim
                        s/^  *//
                        s/  *$//
                       
                        # Strange chars become _
                        s/[^a-z0-9._-]/_/g
                       
                        # Concatenate 2 or more _
                        s/__*/_/g
                       
                        # Delete _ before and after . and -
                        s/_\([.-]\)/\1/g
                        s/\([.-]\)_/\1/g
                       
                        # No - at the begin
                        s/^-/_/
                       
                        # No empty names
                        s/^$/_/")
    
    if [ "$1" != "$newname" ]; then
        if test -e "$newname"; then
            local i=1
            while test -e "$newname.$i"; do
                i=$((i+1))
            done
            newname="$newname.$i"
        fi
        mv "$1" "$newname"
    fi
    
    echo "$newname"
}

datetime() {
# Set the date of last modification of a image file
# according to its EXIF information.
# $1 - Image file.
#
    local img_date=$(identify -format "%[exif:DateTimeOriginal]" "$1" | 
                     sed -e "s/:/-/;s/:/-/")
    [ "$img_date" == "0000-00-00 00:00:00" ] && img_date=""
    touch --date="$img_date" "$1"
    return $?
}

thumbnails() {
# Generate thumbnails for a image file.
# $1 - Image file.
#
    local original_width=$(identify -format "%w" "$1")
    local original_height=$(identify -format "%h" "$1")

    # Images must be 400x400px at least.
    if [[ "$original_width" -lt "400"  ||
          "$original_height" -lt "400" ]]; then
        return 0
    fi

    # Large thumb
    #local width="${THUMB_L%x*}"
    #local height="${THUMB_L##*x}"
    local thumb_l="${1%.*}-$THUMB_L.${1##*.}"

    [ "$original_width" -gt "700" ] &&
    convert "$1" -resize 700x "$thumb_l" ||
    cp -f "$1" "$thumb_l"

    convert "$thumb_l" -gravity center \
            -crop "$THUMB_L+0+0" "$thumb_l"
    convert "$thumb_l" -gravity center \
            -crop "$THUMB_M+0+0" "${1%.*}-$THUMB_M.${1##*.}"
    convert "$thumb_l" -gravity center \
            -crop "$THUMB_S+0+0" "${1%.*}-$THUMB_S.${1##*.}"

    return $?
}


main() {
# Implement the main loop where files are evaluated.
# $1 - Path or file to be analysed.
#
    if [ -d "$1" ]; then
        local file_
        cd "$1"

        for file_ in *; do
            if [ ! -d "$file_" ]; then
                single_file_process "$file_"
            else
                if [ "$RECURSIVE" != "0" ]; then
                    [ "$VERBOSE" != "0" ] && echo ">> $file_"
                    main "$file_"
                    [ "$VERBOSE" != "0" ] && echo "<< $file_"
                    cd ..
                fi
            fi
        done
    else
        cd $(dirname "$1")  # dirname
        single_file_process "${1##*/}"  # basename
    fi

    return $?
}

single_file_process() {
# Routine to process a single file.
# $1 - File to be processed.
#
    local file_="$1"
    local filetype=$(file "$1" | cut -d":" -f2 | cut -d" " -f2)

    if [[ "$filetype" == "JPEG" || "$filetype" == "PNG" ]]; then
        if [ "$SIZE" != "0" ]; then
            size "$file_"
        else
            [ "$NORMALIZE" != "0" ] && normalize "$file_"
        fi

        [ "$FILENAME" != "0" ] && file_=$(filename "$file_")
        [ "$DATETIME" != "0" ] && datetime "$file_"
        [ "$THUMBNAILS" != "0" ] && thumbnails "$file_"

        [ "$VERBOSE" != "0" ] && echo "> $1 - processed"
        return 0
    fi

    [ "$VERBOSE" != "0" ] && echo "> $1 - not an image"
    return 0
}


# Arguments processing
while [ -n "$1" ]; do
    case "$1" in
        -p | --path) shift; PATH_="$1" ;;
        -s | --size) shift; SIZE="$1"; ;;
        -n | --normalize) NORMALIZE=1 ;;
        -f | --filename) FILENAME=1 ;;
        -d | --datetime) DATETIME=1 ;;
        -t | --thumbnails) THUMBNAILS=1 ;;
        -r | --recursive) RECURSIVE=1 ;;
        -v | --verbose) VERBOSE=1 ;;
        -h | --help) echo "$USAGE"; exit 0 ;;
        
        -V | --version)
            echo -e "\nNarkissos\n\n$(cat "$0" | sed -n "5,24p" | 
                                          cut -c 3-)\n"
            exit 0
            ;;
        
        *)
            echo -e "\nNarkissos: Invalid argument - $1\n"
            exit 1
            ;;
    esac
    shift  # Next argument, please. :)
done

# Is ImageMagick installed?  Check it out!
if ! dpkg-query -W imagemagick &> /dev/null; then
    echo -e "\nNarkissos: Package Imagemagick not installed.
Maybe you can install it with:\n    # apt-get install imagemagick\n"
    exit 1
fi

# Check if PATH_ exists and if user have write permission on it.
if [ "$PATH_" != "0" ]; then
    [ -w "$PATH_" ] || { echo -e "\nNarkissos: $PATH_ 
Path does not exist or you do not have writing permissions on it.\n"; exit 1; }
else
    echo -e "\nNarkissos: You must inform a file or a path to process.\n"
    exit 1
fi

# Does SIZE have a valid value?
if [ "$SIZE" != "0" ]; then
    [[ "$SIZE" =~ ^[0-9]+$ ]] || { echo -e "\nNarkissos: $SIZE
It is not a acceptable value for image's max width/height.\n"; exit 1; }
fi

# Everything's OK! Let's rock n' roll!
main "$PATH_"
exit $?
