%define module  collector

Name:       vigilo-%{module}
Summary:    Centralized collector plugin for Nagios
Version:    @VERSION@
Release:    @RELEASE@%{?dist}
Source0:    %{name}-%{version}.tar.gz
URL:        http://www.vigilo-nms.com
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
Requires:   nagios
# Pour _libdir/nagios/utils.pm
Requires:   nagios-plugins-perl


%description
This plugin collects the SNMP data once and forwards it to an UDP port. Its
configuration needs to be generated.
This application is part of the Vigilo Project <http://vigilo-nms.com>

%prep
%setup -q

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
    BINDIR=%{_bindir} \
    SYSCONFDIR=%{_sysconfdir} \
    LOCALSTATEDIR=%{_localstatedir}


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


%changelog
* Fri Mar 05 2010 Aurelien Bompard <aurelien.bompard@c-s.fr>
- new release

* Thu Jul 30 2009 Aurelien Bompard <aurelien.bompard@c-s.fr>
- rename

* Fri Mar 20 2009  Thomas Burguiere <thomas.burguiere@c-s.fr>
- first creation of the RPM from debian archive
