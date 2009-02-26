#!/bin/sh
#
# Update urpmi and apt media and report on any newly found packages
#
# Written by Vincent Danen <vdanen@annvix.org>
#
# $Id$

header="rsec - package updates monitor: @pkg_version@ - \$Id$\n\n"

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

function print_header() {
    if [ "${HEAD}" -eq 0 ]; then
        printf "\n${header}" >> ${TMP}
        printf "Check performed on ${HOST} on ${DATE}\n\n" >> ${TMP}
        HEAD=1
    fi
}

# apt comes first as urpmi is most likely to be the one most used, so if apt exists
# it's because the user wants to use it

if [ -x /usr/sbin/yum-updatesd ]; then
    # yum-updatesd should be doing the monitoring, but still check for apt and urpmi
    echo >/dev/null
elif [ -x /usr/bin/yum ]; then
    YUMLIST=$(yum check-update|egrep -v '^( \*|Loading|Loaded)')
    if [ "$(echo ${YUMLIST} |  awk '{print $1}')" != "0" ]; then
        print_header
        if [ "${HEAD}" -eq 1 ]; then
            printf "The following updates were found via yum:\n\n" >> ${TMP}
            printf "${YUMLIST}\n\n" >> ${TMP}
        fi
    fi
fi

if [ -x /usr/bin/apt-get ]; then
    apt-get update >/dev/null 2>&1
    APTLIST=`apt-get upgrade --check-only 2>/dev/null|egrep -v "(Reading|Building|will be upgraded)"`
    if [ "${APTLIST}" != "" ]; then
        print_header
        if [ "${HEAD}" -eq 1 ]; then
            printf "The following updates were found via apt:\n\n" >> ${TMP}
        fi
        printf "${APTLIST}\n\n" >> ${TMP}
    fi
fi
        
if [ -x /usr/sbin/urpmi ]; then
    urpmi.update -a >/dev/null 2>&1

    urpmq --list-media | while read media
    do
        URPMLIST=`urpmq --auto-select --media "${media}" 2>/dev/null`
        if [ "${LIST}" != "" ]; then
            print_header
            if [ "${HEAD}" -eq 1 ]; then
                printf "The following updates were found via urpmi:\n\n" >> ${TMP}
            fi
            printf "++ Packages in media '${media}':\n\n" >> ${TMP}
            printf "${URPMLIST}\n\n" >> ${TMP}
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
