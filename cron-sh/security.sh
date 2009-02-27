#!/bin/bash
#
# originally based on msec from Mandrakesoft
#
# $Id$

LCK=/var/run/rsec.pid

function cleanup() {
    rm -f $LCK
}

if [ -f $LCK ]; then
    if [ -d /proc/`cat $LCK` ]; then
    	exit 0
    else
    	rm -f $LCK
    fi
fi

echo -n $$ > $LCK

trap cleanup 0

if [[ ! -f /etc/security/rsec.conf ]]; then
    echo "Can't access /etc/security/rsec.conf."
    exit 1
fi

. /etc/security/rsec.conf

umask ${UMASK_ROOT=077}

# check for where logger is, and if it doesn't exist, disable syslog
if [ -x /bin/logger ]; then
    logger="/bin/logger"
elif [ -x /usr/bin/logger ]; then
    logger="/usr/bin/logger"
else
    SYSLOG_WARN="no"
fi

[[ ${MAIL_WARN} == yes ]] && [ -z ${MAIL_USER} ] && MAIL_USER="root"

export SUID_ROOT_TODAY="/var/log/security/suid_root.today"
SUID_ROOT_YESTERDAY="/var/log/security/suid_root.yesterday"
SUID_ROOT_DIFF="/var/log/security/suid_root.diff"
export SGID_TODAY="/var/log/security/sgid.today"
SGID_YESTERDAY="/var/log/security/sgid.yesterday"
SGID_DIFF="/var/log/security/sgid.diff"
export SUID_SHA1_TODAY="/var/log/security/suid_sha1.today"
SUID_SHA1_YESTERDAY="/var/log/security/suid_sha1.yesterday"
SUID_SHA1_DIFF="/var/log/security/suid_sha1.diff"
export OPEN_PORT_TODAY="/var/log/security/open_port.today"
OPEN_PORT_YESTERDAY="/var/log/security/open_port.yesterday"
OPEN_PORT_DIFF="/var/log/security/open_port.diff"
export WRITABLE_TODAY="/var/log/security/writable.today"
WRITABLE_YESTERDAY="/var/log/security/writable.yesterday"
WRITABLE_DIFF="/var/log/security/writable.diff"
export UNOWNED_USER_TODAY="/var/log/security/unowned_user.today"
UNOWNED_USER_YESTERDAY="/var/log/security/unowned_user.yesterday"
UNOWNED_USER_DIFF="/var/log/security/unowned_user.diff"
export UNOWNED_GROUP_TODAY="/var/log/security/unowned_group.today"
UNOWNED_GROUP_YESTERDAY="/var/log/security/unowned_group.yesterday"
UNOWNED_GROUP_DIFF="/var/log/security/unowned_group.diff"
export RPM_QA_TODAY="/var/log/security/rpm-qa.today"
RPM_QA_YESTERDAY="/var/log/security/rpm-qa.yesterday"
RPM_QA_DIFF="/var/log/security/rpm-qa.diff"
export RKHUNTER_TODAY="/var/log/security/rkhunter.today"
export RKHUNTER_TODAY_SUMM="/var/log/security/rkhunter.summ"
RKHUNTER_YESTERDAY="/var/log/security/rkhunter.yesterday"
export EXCLUDE_REGEXP

# Modified filters coming from debian security scripts.

# rootfs is not listed among excluded types, because 
# / is mounted twice, and filtering it would mess with excluded dir list
TYPE_FILTER='(devpts|sysfs|usbfs|tmpfs|binfmt_misc|auto|proc|msdos|fat|vfat|iso9660|ncpfs|smbfs|hfs|nfs|afs|coda|rpc_pipefs)'
MOUNTPOINT_FILTER='^\/(mnt|media)'
DIR=`awk '$3 !~ /'${TYPE_FILTER}'/ && $2 !~ /'${MOUNTPOINT_FILTER}'/ \
	{print $2}' /proc/mounts | uniq`
PRINT="%h/%f\n"
EXCLUDEDIR=`awk '$3 ~ /'${TYPE_FILTER}'/ || $2 ~ /'${MOUNTPOINT_FILTER}'/ \
	{print $2}' /proc/mounts | uniq`
export EXCLUDEDIR

if [[ ! -d /var/log/security ]]; then
    mkdir /var/log/security
fi

if [[ -f ${SUID_ROOT_TODAY} ]]; then
    mv ${SUID_ROOT_TODAY} ${SUID_ROOT_YESTERDAY};
fi

if [[ -f ${SGID_TODAY} ]]; then
    mv ${SGID_TODAY} ${SGID_YESTERDAY};
fi

if [[ -f ${WRITABLE_TODAY} ]]; then
    mv ${WRITABLE_TODAY} ${WRITABLE_YESTERDAY};
fi

if [[ -f ${UNOWNED_USER_TODAY} ]]; then
    mv ${UNOWNED_USER_TODAY} ${UNOWNED_USER_YESTERDAY};
fi

if [[ -f ${UNOWNED_GROUP_TODAY} ]]; then
    mv ${UNOWNED_GROUP_TODAY} ${UNOWNED_GROUP_YESTERDAY};
fi

if [[ -f ${OPEN_PORT_TODAY} ]]; then
    mv -f ${OPEN_PORT_TODAY} ${OPEN_PORT_YESTERDAY}
fi

if [[ -f ${SUID_SHA1_TODAY} ]]; then
    mv ${SUID_SHA1_TODAY} ${SUID_SHA1_YESTERDAY};
fi

if [[ -f ${RPM_QA_TODAY} ]]; then
    mv -f ${RPM_QA_TODAY} ${RPM_QA_YESTERDAY}
fi

if [[ -f ${RKHUNTER_TODAY} ]]; then
    mv -f ${RKHUNTER_TODAY} ${RKHUNTER_YESTERDAY}
fi

netstat -pvlA inet 2> /dev/null > ${OPEN_PORT_TODAY};

# Hard disk related file check; the less priority the better...
nice --adjustment=+19 /usr/bin/rsec_find ${DIR}

if [[ -f ${SUID_ROOT_TODAY} ]]; then
    sort < ${SUID_ROOT_TODAY} > ${SUID_ROOT_TODAY}.tmp
    mv -f ${SUID_ROOT_TODAY}.tmp ${SUID_ROOT_TODAY}
fi

if [[ -f ${SGID_TODAY} ]]; then
    sort < ${SGID_TODAY} > ${SGID_TODAY}.tmp
    mv -f ${SGID_TODAY}.tmp ${SGID_TODAY}
fi

if [[ -f ${WRITABLE_TODAY} ]]; then
    sort < ${WRITABLE_TODAY} | egrep -v '^(/var)?/tmp$' > ${WRITABLE_TODAY}.tmp
    # do exclusions
    if [ -n "$WRITABLE_EXCLUDE" ]; then
        for i in $WRITABLE_EXCLUDE; do
            test -f ${WRITABLE_TODAY}.tmp.1 && mv ${WRITABLE_TODAY}.tmp.1 ${WRITABLE_TODAY}.tmp
            cat ${WRITABLE_TODAY}.tmp | egrep -v "^$i" >${WRITABLE_TODAY}.tmp.1
        done
        mv -f ${WRITABLE_TODAY}.tmp.1 ${WRITABLE_TODAY}.tmp
    fi
    mv -f ${WRITABLE_TODAY}.tmp ${WRITABLE_TODAY}    
fi

if [[ -f ${UNOWNED_USER_TODAY} ]]; then
    sort < ${UNOWNED_USER_TODAY} > ${UNOWNED_USER_TODAY}.tmp
    mv -f ${UNOWNED_USER_TODAY}.tmp ${UNOWNED_USER_TODAY}
fi

if [[ -f ${UNOWNED_GROUP_TODAY} ]]; then
    sort < ${UNOWNED_GROUP_TODAY} > ${UNOWNED_GROUP_TODAY}.tmp
    mv -f ${UNOWNED_GROUP_TODAY}.tmp ${UNOWNED_GROUP_TODAY}
fi

if [[ -f ${SUID_ROOT_TODAY} ]]; then
    while read line; do 
	sha1sum ${line}
    done < ${SUID_ROOT_TODAY} > ${SUID_SHA1_TODAY}
fi

### rpm database check

if [[ ${RPM_CHECK} == yes ]]; then
    rpm -qa --qf "%{NAME}-%{VERSION}-%{RELEASE}\t%{INSTALLTIME}\n" | sort > ${RPM_QA_TODAY}
fi

### rkhunter checks
if [[ ${RKHUNTER_CHECK} == yes ]]; then
    if [ -x /usr/sbin/rkhunter ]; then
	/usr/sbin/rkhunter --cronjob --summary --disable filesystem,properties > ${RKHUNTER_TODAY_SUMM} 2>/dev/null
	# the log may be in different locations, so check first
	if [ -f /var/log/security/rkhunter.log ]; then
	    cp -f /var/log/security/rkhunter.log ${RKHUNTER_TODAY}
	elif [ -f /var/log/rkhunter.log ]; then
	    cp -f /var/log/rkhunter.log ${RKHUNTER_TODAY}
	fi
    fi
fi

### Functions ###

Syslog() {
    if [[ ${SYSLOG_WARN} == yes ]]; then
    while read line; do
        ${logger} -- " ${line}"
    done < ${1}
    fi
}

Ttylog() {
    if [[ ${TTY_WARN} == yes ]]; then
    for i in `w | grep -v "load\|TTY" | grep '^root' | awk '{print $2}'` ; do
        cat ${1} > /dev/$i
    done
    fi
}

Maillog() {
    subject=${1}
    text=${2}
    SOMETHING_TO_SEND=
    
    if [[ ${MAIL_WARN} == yes ]]; then
	if [[ -z ${MAIL_USER} ]]; then 
	    MAIL_USER="root"
	fi
	if [[ -x /bin/mail ]]; then
	    for f in ${text}; do
		if [[ -s $f ]]; then
		    SOMETHING_TO_SEND=1
		    break
		fi
	    done
	    if [[ -z ${SOMETHING_TO_SEND} ]]; then
		if [[ ${MAIL_EMPTY_CONTENT} != no ]]; then
		    /bin/mail -s "${subject}" "${MAIL_USER}" <<EOF
Nothing has changed since the last run.
EOF
                fi
            else
		cat ${text} | /bin/mail -s "${subject}" "${MAIL_USER}"
	    fi
	fi
    fi
}

##################

. /usr/share/rsec/diff_check.sh
. /usr/share/rsec/security_check.sh

