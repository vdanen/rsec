#!/bin/sh

# Update urpmi medium and report on any newly found packages

urpmi.update -a >/dev/null 2>&1

MEDIA=`urpmq --list-media`

HOST=`hostname`
DATE=`date`
HEAD=0

HEADER="OpenSLS package updates monitor\n\nCheck performed on host $HOST on $DATE\n\nThe following updates are available for your system.  To install these\nupdates, please execute 'urpmi --auto-select' on your system.\n\n"

for i in $MEDIA
do
    LIST=`urpmq --auto-select --media $i`
    if [ "$LIST" != "" ]; then
	if [ "$HEAD" == "0" ]; then
	    echo -e $HEADER
	    HEAD=1
	fi
	echo "The following updates in media '$i' were found:"
	echo -n " "
	echo $LIST
	echo ""
    fi
done
