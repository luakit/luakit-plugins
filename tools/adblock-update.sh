#!/bin/bash
#
# Usage: adblock-update.sh [-h] [URL]
# This script can be used to download/update filterlists for the luakit adblock-module
# It will only update the file if the server-side version is newer.
#
#	URL		URL of the filterlist to download, leave empty to download Easylist
#	-h, --help	Display this help-message and exit

# help message
function usage ()
{
cat << EOF
Usage: $0 [-h] [URL]
This script can be used to download/update filterlists for the luakit adblock-module.
It will only update the file if the server-side version is newer.

	URL		URL of the filterlist to download, leave empty to download Easylist
	-h, --help	Display this help message and exit
EOF
}

# check for $XDG_DATA_HOME or fallback
[[ -z "$XDG_DATA_HOME" ]] && DATADIR="$HOME/.local/share" || DATADIR="$XDG_DATA_HOME"


# use URL if given else default to easylist.txt
if (( $# == 1 )) || (( $# == 0 )); then
	[[ ! -z $1 ]] && [[ $1 == "-h" ]] || [[ $1 == "--help" ]] && usage && exit 0  # check for -hflag
	listurl="${1:-"https://easylist-downloads.adblockplus.org/easylist.txt"}"
	listname="$(basename ${listurl})"
elif (( $# > 1 ));then
	usage
	exit 11
fi

# look for adblock directory || create
[[ -d "$DATADIR/luakit/adblock/" ]] || mkdir "$DATADIR/luakit/adblock/" && cd "$DATADIR/luakit/adblock/"

# backup the old list
[[ -f ${listname} ]] && cp -p ${listname} ${listname}.b

# try to download the file
wget -N --connect-timeout=10 --tries=20 --retry-connrefused --waitretry=5 ${listurl}

# if download failed move old file back in place
if (( $? != 0 )); then
	[[ -f ${listname}.b ]] && cp -p ${listname}.b ${listname} && rm ${listname}.b
	echo "Error: List Download Failed!"
	exit 11
else
	[[ -f ${listname}.b ]] && rm ${listname}.b # if all went well remove backup
	echo "All went well. :)"
	exit 0
fi
