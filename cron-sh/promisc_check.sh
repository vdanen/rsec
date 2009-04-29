#!/bin/bash
#
# originally based on msec from Mandriva
#
# $Id$

Syslog() {
    if [[ ${SYSLOG_WARN} == yes ]]; then
        ${logger} -t rsec -- " ${1}"
    fi
}

Ttylog() {
    if [[ ${TTY_WARN} == yes ]]; then
	w | grep -v "load\|TTY" | grep '^root' | awk '{print $2}' | while read line; do
            echo -e "${1}" > /dev/$line
        done
    fi
}

LogPromisc() {
    date=`date`
    Syslog "Security warning : $1 is in promiscuous mode."
    Syslog "    A sniffer is probably running on your system."
    Ttylog "\\033[1;31mSecurity warning : $1 is in promiscuous mode.\\033[0;39m"
    Ttylog "\\033[1;31mA sniffer is probably running on your system.\\033[0;39m"
    echo -e "\n${date} Security warning : $1 is in promiscuous mode." >> /var/log/security.log
    echo "    A sniffer is probably running on your system." >> /var/log/security.log

}

if [[ ! -f /etc/security/rsec.conf ]]; then
    echo "Required configuration file/etc/security/rsec.conf does not exist!"
    exit 1
fi

. /etc/security/rsec.conf

if tail /var/log/security.log | grep -q "promiscuous"; then
    # Dont flood with warning.
    exit 0
fi

# check for where logger is, and if it doesn't exist, disable syslog
if [ -x /bin/logger ]; then
    logger="/bin/logger"
elif [ -x /usr/bin/logger ]; then
    logger="/usr/bin/logger"
else
    SYSLOG_WARN="no"
fi

# Check if a network interface is in promiscuous mode...

if [[ ${CHECK_PROMISC} == no ]]; then
    exit 0;
fi

for INTERFACE in `/sbin/ip link list | grep PROMISC | cut -f 2 -d ':';/usr/bin/promisc_check -q`; do
    LogPromisc ${INTERFACE}
done

# promisc_check.sh ends here
