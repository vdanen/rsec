#!/bin/bash
#
# originally based on msec from Mandriva
#
# $Id$

for source in /etc/sysconfig/i18n /etc/profile.d/lang.sh /etc/profile.d/10lang.sh
do
    if [ -f ${source} ]; then
        . ${source}
    fi
done

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
    echo "Required configuration file/etc/security/rsec.conf does not exist!"
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
export FIREWALL_TODAY="/var/log/security/firewall.today"
FIREWALL_YESTERDAY="/var/log/security/firewall.yesterday"
FIREWALL_DIFF="/var/log/security/firewall.diff"
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
RKHUNTER_DIFF="/var/log/security/rkhunter.diff"
export EXCLUDE_REGEXP

# Modified filters coming from debian security scripts.

# rootfs is not listed among excluded types, because 
# / is mounted twice, and filtering it would mess with excluded dir list
TYPE_FILTER='(devpts|sysfs|usbfs|tmpfs|binfmt_misc|rpc_pipefs|securityfs|auto|proc|msdos|fat|vfat|iso9660|ncpfs|smbfs|hfs|nfs|afs|coda|cifs)'
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

if [[ -f ${FIREWALL_TODAY} ]]; then
    mv -f ${FIREWALL_TODAY} ${FIREWALL_YESTERDAY}
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

if [[ ${CHECK_OPEN_PORT} == yes ]]; then
    netstat -pvlA inet,inet6 2> /dev/null > ${OPEN_PORT_TODAY};
fi

if [[ ${CHECK_FIREWALL} == yes ]]; then
    iptables -L 2>/dev/null >${FIREWALL_TODAY}
fi

# if using '-c3', get iopri_set operation not permitted errors
ionice -c2 -n7 -p $$ 2>/dev/null

# Hard disk related file check; the less priority the better...
# only run it when really required
if [[ ${CHECK_SUID_SHA1} == yes || ${CHECK_SUID_ROOT} == yes || ${CHECK_SGID} == yes || ${CHECK_WRITABLE} == yes || ${CHECK_UNOWNED} == yes  ]]; then
    nice --adjustment=+19 /usr/bin/rsec_find ${DIR}
fi

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

if [[ ${CHECK_RPM} == yes ]]; then
    rpm -qa --qf "%{NAME}-%{VERSION}-%{RELEASE}\t%{INSTALLTIME}\n" | sort > ${RPM_QA_TODAY}
fi

### rkhunter checks
if [[ ${CHECK_RKHUNTER} == yes ]]; then
    rkbinary=""
    if [ -x /usr/sbin/rkhunter ]; then
        rkbinary="/usr/sbin/rkhunter"
    elif [ -x /usr/bin/rkhunter ]; then
        rkbinary="/usr/bin/rkhunter"
    fi
    if [ "${rkbinary}" != "" ]; then
        ${rkbinary} --cronjob --summary --disable suspscan,filesystem,properties,deleted_files,apps > ${RKHUNTER_TODAY_SUMM} 2>/dev/null
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
        ${logger} -t rsec -- " ${line}"
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
                # remove non-printable characters
                cat ${text} | LC_CTYPE=$LC_CTYPE /bin/mail -s "${subject}" "${MAIL_USER}"
            fi
        fi
    fi
}

##################

. /usr/share/rsec/diff_check.sh
. /usr/share/rsec/security_check.sh

