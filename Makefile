VERSION = 0.63
PACKAGE = rsec

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
	mkdir -p $(RPM_BUILD_ROOT)/etc/security
	mkdir -p $(RPM_BUILD_ROOT)/usr/sbin
	cp cron-sh/*.sh $(RPM_BUILD_ROOT)/usr/share/rsec

	mkdir -p $(RPM_BUILD_ROOT)/var/log
	mkdir -p $(RPM_BUILD_ROOT)/var/log/security
	touch $(RPM_BUILD_ROOT)/var/log/security.log
	cd src/promisc_check && make install
	cd src/rsec_find && make install
	mkdir -p $(RPM_BUILD_ROOT)/usr/share/man/man8/
	install -m644 *.8 $(RPM_BUILD_ROOT)/usr/share/man/man8/

dist: clean
	find . -not -name '*.bz2'|cpio -pd $(PACKAGE)-$(VERSION)/
	find $(PACKAGE)-$(VERSION) -type d -name .svn|xargs rm -rf 
	tar cfj $(PACKAGE)-$(VERSION).tar.bz2 $(PACKAGE)-$(VERSION)
	rm -rf $(PACKAGE)-$(VERSION)
