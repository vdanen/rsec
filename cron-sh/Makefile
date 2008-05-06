SYSCONFDIR = /etc

all:
	for f in *.sh; do bash -n $$f || exit 1; done

install:
	mkdir -p $(SYSCONFDIR)/security/rsec/cron-sh
	cp *.sh $(SYSCONFIDR)/security/rsec/cron-sh
