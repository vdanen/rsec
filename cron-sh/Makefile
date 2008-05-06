DESTDIR =
SYSCONFDIR = /etc

all:
	for f in *.sh; do bash -n $$f || exit 1; done

install:
	mkdir -p $(DESTDIR)$(SYSCONFDIR)/security/rsec/cron-sh
	cp *.sh $(DESTDIR)$(SYSCONFIDR)/security/rsec/cron-sh
