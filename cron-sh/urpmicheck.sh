#!/bin/sh
#
# Update urpmi medium and report on any newly found packages
#
# Written by Vincent Danen <vdanen@annvix.org>

if [[ -f /etc/security/rsec.conf ]]; then
    . /etc/security/rsec.conf
else
    echo "/etc/security/rsec.conf doesn't exist."
    exit 1
fi

TMP=`mktemp /tmp/secure.XXXXXX`

urpmi.update -a >/dev/null 2>&1

MEDIA=`urpmq --list-media`

HOST=`hostname`
DATE=`date`
HEAD=0

for i in $MEDIA
do
    LIST=`urpmq --auto-select --media $i`
    if [ "$LIST" != "" ]; then
        if [ "$HEAD" -eq 0 ]; then
            printf "\nAnnvix package updates monitor\n\n" >> $TMP
            printf "Check performed on $HOST on $DATE\n\n" >> $TMP
            printf "The following updates are available for your system.  To install these\n" >> $TMP
            printf "updates, please execute 'urpmi --auto-select' on your system.\n\n" >> $TMP
            HEAD=1
        fi
	printf "The following updates in media '$i' were found:\n\n" >> $TMP
	printf "$LIST\n\n" >> $TMP
    fi
done

# only mail the report if there is something worth mailing
if [[ -s $TMP ]]; then
    cat $TMP | /bin/mail -s "[rsec] *** Package Updates Check on $HOST, $DATE ***" "${MAIL_USER}"
fi

if [[ -f $TMP ]]; then
	rm -f $TMP
fi
