PACKAGE = rsec
VERSION:=$(shell rpm -q --qf %{VERSION} --specfile $(PACKAGE).spec)
RELEASE:=$(shell rpm -q --qf %{RELEASE} --specfile $(PACKAGE).spec)
TAG := $(shell echo "V$(VERSION)_$(RELEASE)" | tr -- '-.' '__')

all: promisc_check rsec_find
	make -C cron-sh

clean:
	-find . -name '*.o' -o -name '*~' | xargs rm -f
	rm -f src/promisc_check/promisc_check
	rm -f src/rsec_find/rsec_find
	rm -f *.bz2

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

version:
	@echo $(VERSION)-$(RELEASE)

# rules to build a test rpm

localsrpm: clean localdist buildsrpm

localrpm: clean localdist buildrpm

localdist: cleandist dir localcopy tar

cleandist:
	rm -rf $(PACKAGE)-$(VERSION) $(PACKAGE)-$(VERSION).tar.bz2

dir:
	mkdir $(PACKAGE)-$(VERSION)

localcopy: clean
	find . -not -name "$(PACKAGE)-$(VERSION)" -a -not -name '*.bz2'|cpio -pd $(PACKAGE)-$(VERSION)/
	find $(PACKAGE)-$(VERSION) -type d -name CVS|xargs rm -rf 

tar:
	tar cvf $(PACKAGE)-$(VERSION).tar $(PACKAGE)-$(VERSION)
	bzip2 -9vf $(PACKAGE)-$(VERSION).tar
	rm -rf $(PACKAGE)-$(VERSION)

buildsrpm:
	rpm -ts $(PACKAGE)-$(VERSION).tar.bz2

buildrpm:
	rpm -ta $(PACKAGE)-$(VERSION).tar.bz2

# rules to build a distributable rpm

rpm: changelog cvstag dist buildrpm

dist: cleandist dir export tar

export:
	cvs export -d $(PACKAGE)-$(VERSION) -r $(TAG) tools/$(PACKAGE)

cvstag:
	cvs tag $(CVSTAGOPT) $(TAG)

changelog: ../common/username
	cvs2cl -U ../common/username -I ChangeLog 
	rm -f ChangeLog.bak
	cvs commit -m "Generated by cvs2cl the `date '+%d_%b'`" ChangeLog
