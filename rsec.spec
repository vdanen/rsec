%define name	rsec
%define version	0.50
%define release	1sls

Summary:	Security Reporting tool for OpenSLS
Name:		%{name}
Version:	%{version}
Release:	%{release}
License:	GPL
Group:		System/Base
URL:		http://opensls.org/cgi-bin/viewcvs.cgi/tools/rsec/
Source0:	%{name}-%{version}.tar.bz2

BuildRoot:	%_tmppath/%name-%version-%release-root

Requires:	/bin/bash /bin/touch perl-base diffutils /usr/bin/chage gawk
Requires:	setup >= 2.2.0-21mdk, coreutils, iproute2
PreReq:		rpm-helper >= 0.4
Conflicts:	passwd < 0.67, msec

%description
The OpenSLS Security Reporting tool (rsec) is largely based on the
Mandrakelinux msec program.  rsec produces the same reports as msec, but
does not manage permission issues or system configuration changes.  It is
nothing more than a reporting tool to advise you of changes to your system
and potential problem areas.  Any changes or fixes are entirely up to the
user to correct.

%prep

%setup -q

%build
make CFLAGS="$RPM_OPT_FLAGS"

%install
[ -n "%{buildroot}" -a "%{buildroot}" != / ] && rm -rf %{buildroot}

mkdir -p %{buildroot}{%{_sysconfdir}/{security,logrotate.d,cron.daily,cron.hourly}}
mkdir -p %{buildroot}{%{_datadir}/rsec,%{_bindir},/var/log/security,%{_mandir}/man3}

install -m 0640 cron-sh/{security,diff}_check.sh %{buildroot}%{_datadir}/rsec
install -m 0750 cron-sh/{promisc_check,security,urpmicheck}.sh %{buildroot}%{_datadir}/rsec
install -m 0750 src/promisc_check/promisc_check src/rsec_find/rsec_find %{buildroot}%{_bindir}
install -m 0644 rsec.logrotate %{buildroot}/etc/logrotate.d/rsec
install -m 0644 *.3 %{buildroot}%{_mandir}/man3/
install -m 0640 rsec.conf %{buildroot}%{_sysconfdir}/security
install -m 0750 rsec.crondaily %{buildroot}%{_sysconfdir}/cron.daily/rsec
install -m 0750 rsec.cronhourly %{buildroot}%{_sysconfdir}/cron.hourly/rsec
pushd %{buildroot}%{_sysconfdir}/cron.daily
	ln -s ../..%{_datadir}/rsec/urpmicheck.sh urpmicheck
popd

touch %{buildroot}/var/log/security.log

%post
touch /var/log/security.log

%clean
[ -n "%{buildroot}" -a "%{buildroot}" != / ] && rm -rf %{buildroot}

%files
%defattr(-,root,root)
%doc AUTHORS COPYING ChangeLog
%_bindir/promisc_check
%_bindir/rsec_find
%dir %_datadir/rsec
%{_datadir}/rsec/*
%{_mandir}/man3/rsec.3*
%dir /var/log/security
%config(noreplace) %{_sysconfdir}/security/rsec.conf
%config(noreplace) %{_sysconfdir}/logrotate.d/rsec
%config(noreplace) %{_sysconfdir}/cron.daily/rsec
%config(noreplace) %{_sysconfdir}/cron.hourly/rsec
%{_sysconfdir}/cron.daily/urpmicheck
%ghost /var/log/security.log

%changelog
* Wed Mar 10 2004 Vincent Danen <vdanen@opensls.org> 0.50-1sls
- first OpenSLS package based on msec-0.42-1mdk
