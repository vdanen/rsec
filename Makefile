VERSION = 0.70.1
PACKAGE = rsec

SUBDIRS = cron-sh src
MANPAGE = rsec.8
SCRIPTS = rsec.cronhourly rsec.crondaily rsec.logrotate
CONF = rsec.conf

FILES = Makefile AUTHORS COPYING ChangeLog $(SCRIPTS) $(MANPAGE) $(CONF) $(SUBDIRS)

DESTDIR =
DATADIR = /usr/share
MANDIR = /usr/share/man
SBINDIR = /usr/sbin
SYSCONFDIR = /etc

all: promisc_check rsec_find
	make -C cron-sh

clean:
	-find . -name '*.o' -o -name '*~' | xargs rm -f
	rm -f src/promisc_check/promisc_check
	rm -f src/rsec_find/rsec_find
	rm -f *.bz2
	rm -f ChangeLog
	rm -rf $(PACKAGE)-$(VERSION)

promisc_check: 
	(cd src/promisc_check && make)

rsec_find:
	(cd src/rsec_find && make)

install:
	mkdir -p $(DESTDIR)$(SYSCONFDIR)/{cron.daily,cron.hourly,logrotate.d,security} \
	$(DESTDIR){$(SBINDIR),$(BINDIR)} \
	$(DESTDIR)$(DATADIR)/rsec \
	$(DESTDIR)/var/log/security \
	$(DESTDIR)$(MANDIR)/man8/
	
	install -m 0750 cron-sh/*.sh $(DESTDIR)$(DATADIR)/rsec/
	install -m 0644 rsec.logrotate $(DESTDIR)$(SYSCONFDIR)/logrotate.d/rsec
	install -m 0644 $(MANPAGE) $(DESTDIR)$(MANDIR)/man8/
	install -m 0640 rsec.conf $(DESTDIR)$(SYSCONFDIR)/security/
	install -m 0750 rsec.crondaily $(DESTDIR)$(SYSCONFDIR)/cron.daily/rsec
	install -m 0750 rsec.cronhourly $(DESTDIR)$(SYSCONFDIR)/cron.hourly/rsec
	
	touch $(DESTDIR)/var/log/security.log
	
	cd src/promisc_check && make install
	cd src/rsec_find && make install

dist: clean changelog
	mkdir -p $(PACKAGE)-$(VERSION)
	for file in $(FILES); do \
	cp -a $$file $(PACKAGE)-$(VERSION)/ ; \
	done
	sed -e 's|@pkg_version@|$(VERSION)|g' cron-sh/pkgcheck.sh >$(PACKAGE)-$(VERSION)/cron-sh/pkgcheck.sh
	find $(PACKAGE)-$(VERSION) -type d -name .svn | xargs rm -rf 
	tar cfj $(PACKAGE)-$(VERSION).tar.bz2 $(PACKAGE)-$(VERSION)
	rm -rf $(PACKAGE)-$(VERSION)

changelog:
	svn update
	svn2cl --authors=../../common/trunk/username.xml
