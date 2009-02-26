#!/bin/sh
#
# clean the apt cache every night; if this isn't done regularly it can
# start to eat away at /var
#
# of course, if you don't want to automatically remove the cache, delete
# /etc/cron.daily/apt_cleancache.sh

if [ -x /usr/bin/apt-get ]; then
    apt-get clean >/dev/null 2>&1
fi

