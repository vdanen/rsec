VERSION = 0.69.1
PACKAGE = rsec

SUBDIRS = cron-sh src
MANPAGE = rsec.8
SCRIPTS = rsec.cronhourly rsec.crondaily rsec.logrotate
CONF = rsec.conf

FILES = Makefile AUTHORS COPYING ChangeLog $(SCRIPTS) $(MANPAGE) $(CONF) $(SUBDIRS)

RPM_BUILD_ROOT =
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
	rm -rf $(PACKAGE)-$(VERSION)

promisc_check: 
	(cd src/promisc_check && make)

rsec_find:
	(cd src/rsec_find && make)

install:
	mkdir -p $(RPM_BUILD_ROOT)$(SYSCONFDIR)/security
	mkdir -p $(RPM_BUILD_ROOT)$(SBINDIR)
	cp cron-sh/*.sh $(RPM_BUILD_ROOT)/usr/share/rsec

	mkdir -p $(RPM_BUILD_ROOT)/var/log
	mkdir -p $(RPM_BUILD_ROOT)/var/log/security
	touch $(RPM_BUILD_ROOT)/var/log/security.log
	cd src/promisc_check && make install
	cd src/rsec_find && make install
	mkdir -p $(RPM_BUILD_ROOT)$(MANDIR)/man8/
	install -m 0644 $(MANPAGE) $(RPM_BUILD_ROOT)$(MANDIR)/man8/

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
