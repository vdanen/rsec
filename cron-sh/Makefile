all:
	for f in *.sh; do bash -n $$f || exit 1; done

install:
	mkdir -p /etc/security/rsec/cron-sh
	cp *.sh /etc/security/rsec/cron-sh
