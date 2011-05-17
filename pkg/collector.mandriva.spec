%define module  collector
%define name    vigilo-%{module}
%define version @VERSION@
%define release 1%{?svn}%{?dist}

Name:       %{name}
Summary:    Centralized collector plugin for Nagios
Version:    %{version}
Release:    %{release}
Source0:    %{name}-%{version}.tar.gz
URL:        http://www.projet-vigilo.org
Group:      System/Servers
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-build
License:    GPLv2
#Buildarch:  noarch  # on installe dans _libdir

BuildRequires: perl-doc

Requires:   perl-Crypt-DES
Requires:   perl-Net-SNMP
Requires:   perl-Digest-HMAC
Requires:   perl-Digest-SHA1
Requires:   perl-Nagios-Cmd
Requires:   nagios


%description
This plugin collects the SNMP data once and forwards it to an UDP port. Its
configuration needs to be generated.
This application is part of the Vigilo Project <http://vigilo-project.org>

%prep
%setup -q

%build
make \
	LIBDIR=%{_libdir} \
	SYSCONFDIR=%{_sysconfdir} \
	LOCALSTATEDIR=%{_localstatedir}

%install
rm -rf $RPM_BUILD_ROOT
make install \
	DESTDIR=$RPM_BUILD_ROOT \
	LIBDIR=%{_libdir} \
	SYSCONFDIR=%{_sysconfdir} \
	LOCALSTATEDIR=%{_localstatedir}


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(644,root,root,755)
%doc COPYING.txt README.txt TODO host.example
%{_libdir}/%{name}
%attr(755,root,root) %{_libdir}/nagios/plugins/*
%dir %{_sysconfdir}/vigilo
%config(noreplace) %{_sysconfdir}/vigilo/%{module}
%config(noreplace) %{_sysconfdir}/cron.d/*.cron


%changelog
* Fri Mar 05 2010 Aurelien Bompard <aurelien.bompard@c-s.fr>
- new release

* Thu Jul 30 2009 Aurelien Bompard <aurelien.bompard@c-s.fr> - 1.5-2
- rename

* Fri Mar 20 2009  Thomas Burguiere <thomas.burguiere@c-s.fr> - 1.5-1
- first creation of the RPM from debian archive
