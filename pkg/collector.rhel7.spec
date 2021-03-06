%define module  collector
# Le code est noarch, mais s'installe dans _libdir (arch-dependent)
%global debug_package %{nil}

Name:       vigilo-%{module}
Summary:    Centralized collector plugin for Nagios
Version:    @VERSION@
Release:    @RELEASE@%{?dist}
Source0:    %{name}-%{version}@PREVERSION@.tar.gz
URL:        https://www.vigilo-nms.com
Group:      Applications/System
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-build
License:    GPLv2
#Buildarch:  noarch  # on installe dans _libdir

Requires:   perl-Crypt-DES
Requires:   perl-Net-SNMP
Requires:   perl-Digest-HMAC
Requires:   perl-Digest-SHA1
Requires:   perl-Nagios-Cmd
Requires:   perl-Math-RPN
Requires:   perl-Nagios-Plugin
Requires:   nagios

%description
This plugin collects the SNMP data once and forwards it to an UDP port. Its
configuration needs to be generated.
This application is part of the Vigilo Project <https://www.vigilo-nms.com>

%prep
%setup -q -n %{name}-%{version}@PREVERSION@

%build
make \
    LIBDIR=%{_libdir} \
    SYSCONFDIR=%{_sysconfdir} \
    LOCALSTATEDIR=%{_localstatedir}

%install
rm -rf $RPM_BUILD_ROOT
make install_pkg \
    DESTDIR=$RPM_BUILD_ROOT \
    LIBDIR=%{_libdir} \
    SYSCONFDIR=%{_sysconfdir} \
    LOCALSTATEDIR=%{_localstatedir} \
    MANDIR=%{_mandir}


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(644,root,root,755)
%doc COPYING.txt README.txt TODO host.example
%{_libdir}/%{name}
%attr(755,root,root) %{_libdir}/%{name}/cleanup.sh
%attr(755,root,root) %{_libdir}/nagios/plugins/*
%dir %{_sysconfdir}/vigilo
%config(noreplace) %{_sysconfdir}/vigilo/%{module}
%config(noreplace) %{_sysconfdir}/cron.d/*.cron
%dir %{_sysconfdir}/nagios/plugins.d
%config(noreplace) %{_sysconfdir}/nagios/plugins.d/%{name}.cfg
%{_mandir}/man1/Collector.1*


%changelog
* Fri Mar 05 2010 Aurelien Bompard <aurelien.bompard@c-s.fr>
- new release

* Thu Jul 30 2009 Aurelien Bompard <aurelien.bompard@c-s.fr>
- rename

* Fri Mar 20 2009  Thomas Burguiere <thomas.burguiere@c-s.fr>
- first creation of the RPM from debian archive
