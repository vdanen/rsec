#!/bin/sh
#
# Update urpmi and apt media and report on any newly found packages
#
# Written by Vincent Danen <vdanen@annvix.org>
#
# $Id$

if [[ -f /etc/security/rsec.conf ]]; then
    . /etc/security/rsec.conf
else
    echo "/etc/security/rsec.conf doesn't exist."
    exit 1
fi

TMP=`mktemp /tmp/secure.XXXXXX`
HOST=`hostname`
DATE=`date`
HEAD=0

# apt comes first as urpmi is most likely to be the one most used, so if apt exists
# it's because the user wants to use it

if [ -x /usr/bin/apt-get ]; then
    apt-get update >/dev/null 2>&1
    APTLIST=`apt-get upgrade --check-only 2>/dev/null|egrep -v "(Reading|Building|will be upgraded)"`
    if [ "${APTLIST}" != "" ]; then
        if [ "${HEAD}" -eq 0 ]; then
            printf "\nAnnvix package updates monitor\n\n" >> ${TMP}
            printf "Check performed on ${HOST} on ${DATE}\n\n" >> ${TMP}
            printf "The following updates are available for your system.  To install these\n" >> ${TMP}
            printf "updates, please use 'urpmi' or 'apt-get' on your system.\n\n" >> ${TMP}
            HEAD=1
            printf "++ The following updates were found via apt:\n\n" >> ${TMP}
            printf "${APTLIST}\n\n" >> ${TMP}
        fi
    fi
fi
        
if [ -x /usr/sbin/urpmi ]; then
    urpmi.update -a >/dev/null 2>&1
    MEDIA=`urpmq --list-media`

    for i in ${MEDIA}
    do
        LIST=`urpmq --auto-select --media ${i}`
        if [ "${LIST}" != "" ]; then
            if [ "${HEAD}" -eq 0 ]; then
                printf "\nAnnvix package updates monitor\n\n" >> ${TMP}
                printf "Check performed on ${HOST} on ${DATE}\n\n" >> ${TMP}
                printf "The following updates are available for your system.  To install these\n" >> ${TMP}
                printf "updates, please execute 'urpmi' or 'apt-get' on your system.\n\n" >> ${TMP}
                HEAD=1
            fi
            if [ "${HEAD}" -eq 1 ]; then
                printf "++ The following updates were found via urpmi:\n" >> ${TMP}
                HEAD=2
            fi
            printf "++ Packages in media '${i}':\n\n" >> ${TMP}
            printf "${LIST}\n\n" >> ${TMP}
        fi
    done
fi

# only mail the report if there is something worth mailing
if [ -s ${TMP} ]; then
    cat ${TMP} | /bin/mail -s "[rsec] *** Package Updates Check on ${HOST}, ${DATE} ***" "${MAIL_USER}"
fi

if [ -f ${TMP} ]; then
	rm -f ${TMP}
fi
