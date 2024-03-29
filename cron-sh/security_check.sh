#!/bin/bash
#
# originally based on msec from Mandriva
#
# $Id$

if [[ ! -f /etc/security/rsec.conf ]]; then
    echo "Required configuration file/etc/security/rsec.conf does not exist!"
    exit 1
fi

. /etc/security/rsec.conf

if [[ ${CHECK_SECURITY} != yes ]]; then
    exit 0
fi

INFOS=`mktemp /tmp/secure.XXXXXX`
SECURITY=`mktemp /tmp/secure.XXXXXX`
SECURITY_LOG="/var/log/security.log"
TMP=`mktemp /tmp/secure.XXXXXX`
FILTER="\(`echo $EXCLUDEDIR | sed -e 's/ /\\\|/g'`\)"

if [[ ! -d /var/log/security ]]; then
    mkdir /var/log/security
fi

### Writable file detection
if [[ ${CHECK_WRITABLE} == yes ]]; then
    if [[ -s ${WRITABLE_TODAY} ]]; then
        printf "\nSecurity Warning: World Writable files found :\n" >> ${SECURITY}
        cat ${WRITABLE_TODAY} | awk '{print "\t\t- " $0}' >> ${SECURITY}
    fi
fi

### Search Unowned file
if [[ ${CHECK_UNOWNED} == yes ]]; then
    if [[ -s ${UNOWNED_USER_TODAY} ]]; then
        printf "\nSecurity Warning : The following files are owned by an unknown user:\n" >> ${SECURITY}
        cat ${UNOWNED_USER_TODAY} | awk '{print "\t\t- " $0}' >> ${SECURITY}
    fi

    if [[ -s ${UNOWNED_GROUP_TODAY} ]]; then
        printf "\nSecurity Warning : The following files are owned by an unknown group:\n" >> ${SECURITY}
        cat ${UNOWNED_GROUP_TODAY} | awk '{print "\t\t- " $0}' >> ${SECURITY}
    fi
fi

if [[ ${CHECK_PERMS} == yes ]]; then
    # Files that should not be owned by someone else or readable.
    list=".netrc .rhosts .shosts .Xauthority .gnupg/secring.gpg \
    .pgp/secring.pgp .ssh/identity .ssh/id_dsa .ssh/id_rsa .ssh/random_seed"
    getent passwd | awk -F: '/^[^+-]/ { print $1 ":" $3 ":" $6 }' |
    while IFS=: read username uid homedir; do
        if ! expr "$homedir" : "$FILTER"  > /dev/null; then
            for f in ${list} ; do
                file="${homedir}/${f}"
                if [[ -e ${file} ]] ; then
                    printf "${uid} ${username} ${file} `ls -LldcGn ${file}`\n"
                fi
            done
        fi
    done | awk '$1 != $6 && $6 != "0" \
    { print "\t\t- " $3 " : file is owned by uid " $6 "." }
    $4 ~ /^-...r/ \
    { print "\t\t- " $3 " : file is group readable." }
    $4 ~ /^-......r/ \
    { print "\t\t- " $3 " : file is other readable." }
    $4 ~ /^-....w/ \
    { print "\t\t- " $3 " : file is group writable." }
    $4 ~ /^-.......w/ \
    { print "\t\t- " $3 " : file is other writable." }' > ${TMP}

    if [[ -s ${TMP} ]]; then
        printf "\nSecurity Warning: these files shouldn't be owned by someone else or readable :\n" >> ${SECURITY}
        cat ${TMP} >> ${SECURITY}
    fi

    ### Files that should not be owned by someone else or writable.
    list=".bashrc .bash_profile .bash_login .bash_logout .cshrc .emacs .exrc \
    .forward .klogin .login .logout .profile .tcshrc .fvwmrc .inputrc .kshrc \
    .nexrc .screenrc .ssh .ssh/config .ssh/authorized_keys .ssh/environment \
    .ssh/known_hosts .ssh/rc .twmrc .xsession .xinitrc .Xdefaults \
    .gnupg .gnupg/secring.gpg .ssh/identity .ssh/id_dsa .ssh/id_rsa \
    .Xauthority .cvspass .subversion/auth .purple/accounts.xml .config "
    getent passwd | awk -F: '/^[^+-]/ { print $1 ":" $3 ":" $6 }' | \
    while IFS=: read username uid homedir; do
        if ! expr "$homedir" : "$FILTER"  > /dev/null; then
            for f in ${list} ; do
                file="${homedir}/${f}"
                if [[ -e "${file}" ]] ; then
                    res=`ls -LldcGn "${file}" | sed 's/ \{1,\}/:/g'`
                    printf "${uid}:${username}:${file}:${res}\n"
                fi
            done
        fi
    done | awk -F: '$1 != $6 && $6 != "0" \
    { print "\t\t- " $3 " : file is owned by uid " $6 "." }
    $4 ~ /^.....w/ \
    { print "\t\t- " $3 " : file is group writable." }
    $4 ~ /^........w/ \
    { print "\t\t- " $3 " : file is other writable." }' > ${TMP}

    if [[ -s ${TMP} ]]; then
        printf "\nSecurity Warning: theses files should not be owned by someone else or writable :\n" >> ${SECURITY}
        cat ${TMP} >> ${SECURITY}
    fi

    ### Check home directories.  Directories should not be owned by someone else or writable.
    getent passwd | awk -F: '/^[^+-]/ { print $1 ":" $3 ":" $6 }' | \
    while IFS=: read username uid homedir; do
        if ! expr "$homedir" : "$FILTER"  > /dev/null; then
            if [[ -d "${homedir}" ]] ; then
                realuid=`ls -LldGn "${homedir}"| awk '{ print $3 }'`
                realuser=`ls -LldG "${homedir}"| awk '{ print $3 }'`
                permissions=`ls -LldG "${homedir}"| awk '{ print $1 }'`
                printf "${permissions}:${username}:(${uid}):${realuser}:(${realuid})\n"
            fi
        fi
    done | awk -F: '$3 != $5 && $5 != "(0)" \
    { print "user=" $2 $3 " : home directory is owned by " $4 $5 "." }
    $1 ~ /^d....w/ && $2 != "lp" && $2 != "mail" \
    { print "user=" $2 $3" : home directory is group writable." }
    $1 ~ /^d.......w/ \
    { print "user=" $2 $3" : home directory is other writable." }' > ${TMP}

    if [[ -s $TMP ]] ; then
        printf "\nSecurity Warning: these home directory should not be owned by someone else or writable :\n" >> ${SECURITY}
        cat ${TMP} >> ${SECURITY}
    fi
fi # End of check perms

### Passwd file check
if [[ ${CHECK_PASSWD} == yes ]]; then    
    getent passwd | awk -F: '{
    if ( $2 == "" )
        printf("\t\t- /etc/passwd:%d: User \"%s\" has no password !\n", FNR, $1);
    else if ($2 !~ /^[x*!]+$/)
        printf("\t\t- /etc/passwd:%d: User \"%s\" has a real password (it is not shadowed).\n", FNR, $1);
    else if ( $3 == 0 && $1 != "root" )
        printf("\t\t- /etc/passwd:%d: User \"%s\" has id 0 !\n", FNR, $1);
    }' > ${TMP}

    if [[ -s ${TMP} ]]; then
        printf "\nSecurity Warning: /etc/passwd check :\n" >> ${SECURITY}
        cat ${TMP} >> ${SECURITY}
    fi
fi

### Shadow password file Check
# this can only be done if we're not using tcb per default, so even if this
# check may be enabled, check for the existance of /etc/shadow first
if [ -f /etc/shadow ]; then
    if [[ ${CHECK_SHADOW} == yes ]]; then
        awk -F: '{
        if ( $2 == "" )
            printf("\t\t- /etc/shadow:%d: User \"%s\" has no password !\n", FNR, $1);
        }' < /etc/shadow > ${TMP}

        if [[ -s ${TMP} ]]; then
            printf "\nSecurity Warning: /etc/shadow check :\n" >> ${SECURITY}
            cat ${TMP} >> ${SECURITY}
        fi
    fi
fi

### File systems should not be globally exported.
if [[ -s /etc/exports ]] ; then
    awk '{
    if (($1 ~ /^#/) || ($1 ~ /^$/)) next;
        readonly = 0;
        for (i = 2; i <= NF; ++i) {
            if ($i ~ /^-ro$/)
                readonly = 1;
            else if ($i !~ /^-/)
                next;
            }
            if (readonly) {
                print "\t\t- Nfs File system " $1 " globally exported, read-only.";
            } else print "\t\t- Nfs File system " $1 " globally exported, read-write.";
        }' < /etc/exports > ${TMP}

    if [[ -s ${TMP} ]] ; then
        printf "\nSecurity Warning: Some NFS filesystem are exported globally :\n" >> ${SECURITY}
        cat ${TMP} >> ${SECURITY}
    fi
fi

### nfs mounts with missing nosuid
/bin/mount | /bin/grep -v nosuid | /bin/grep ' nfs ' > ${TMP}
if [[ -s ${TMP} ]] ; then
    printf "\nSecurity Warning: The following NFS mounts haven't got the nosuid option set :\n" >> ${SECURITY}
    cat ${TMP} | awk '{ print "\t\t- "$0 }' >> ${SECURITY}
fi

### Files that should not have + signs.
list="/etc/hosts.equiv /etc/shosts.equiv /etc/hosts.lpd"
for file in $list ; do
    if [[ -s ${file} ]] ; then
        awk '{
        if ($0 ~ /^\+@.*$/)
            next;
            if ($0 ~ /^\+.*$/)
                printf("\t\t- %s: %s\n", FILENAME, $0);
            }' ${file}
    fi
done > ${TMP}

### Passwd file check
if [[ ${CHECK_SHOSTS} == yes ]]; then    
    getent passwd | awk -F: '{print $1" "$6}' |
    while read username homedir; do
        if ! expr "$homedir" : "$FILTER"  > /dev/null; then
            for file in .rhosts .shosts; do
                if [[ -s ${homedir}/${file} ]] ; then
                    awk '{
                    if ($0 ~ /^\+@.*$/)
                        next;
                        if ($0 ~ /^\+.*$/)
                            printf("\t\t- %s: %s\n", FILENAME, $0);
                        }' ${homedir}/${file}
                fi
            done >> ${TMP}
        fi
    done

    if [[ -s ${TMP} ]]; then
        printf "\nSecurity Warning: '+' character found in hosts trusting files,\n" >> ${SECURITY}
        printf "\tthis probably mean that you trust certains users/domain\n" >> ${SECURITY}
        printf "\tto connect on this host without proper authentication :\n" >> ${SECURITY}
        cat ${TMP} >> ${SECURITY}
    fi
fi

### executables should not be in the aliases file.
list="/etc/aliases /etc/postfix/aliases"
for file in ${list}; do
    if [[ -s ${file} ]]; then
        grep -v '^#' ${file} | grep '|' | while read line; do
        printf "\t\t- ${line}\n"
    done > ${TMP}
fi

if [[ -s ${TMP} ]]; then
    printf "\nSecurity Warning: The following programs are executed in your mail\n" >> ${SECURITY}
    printf "\tvia ${file} files, this could lead to security problems :\n" >> ${SECURITY}
    cat ${TMP} >> ${SECURITY}
fi
done

### Dump a list of open port.
if [[ ${CHECK_OPEN_PORT} == yes ]]; then
    if [[ -s ${OPEN_PORT_TODAY} ]]; then
        printf "\nThese are the ports listening on your machine :\n" >> ${INFOS}
        cat ${OPEN_PORT_TODAY} >> ${INFOS}
    fi
fi


### rkhunter checks
if [[ ${CHECK_RKHUNTER} == yes ]]; then

    if [[ -s ${RKHUNTER_TODAY} ]]; then
        printf "\nrkhunter report shortlist:\n" >> ${SECURITY}
        cat ${RKHUNTER_TODAY_SUMM} >> ${SECURITY}
        printf "\nSee ${RKHUNTER_TODAY} for a full scan report\n" >> ${SECURITY}
    fi
fi

### Report
if [[ -s ${SECURITY} ]]; then
    Syslog ${SECURITY}
    Ttylog ${SECURITY}
    date=`date`
    hostname=`hostname`

    echo -e "\n\n*** Security Check, ${date} ***\n" >> ${SECURITY_LOG}
    cat ${SECURITY} >> ${SECURITY_LOG}
    cat ${INFOS} >> ${SECURITY_LOG}

    Maillog "[rsec] *** Security Check on ${hostname}, ${date} ***" "${SECURITY} ${INFOS}"
fi

if [[ -f ${SECURITY} ]]; then
    rm -f ${SECURITY}
fi

if [[ -f ${TMP} ]]; then
    rm -f ${TMP}
fi

if [[ -f ${INFOS} ]]; then
    rm -f ${INFOS};
fi
