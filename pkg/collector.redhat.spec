%define module  collector
%define name    vigilo-%{module}
%define version 2.0.0
%define release 1%{?svn}%{?dist}

Name:       %{name}
Summary:    Centralized collector plugin for Nagios
Version:    %{version}
Release:    %{release}
Source0:    collector.tar.bz2
URL:        http://www.projet-vigilo.org
Group:      System/Servers
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-build
License:    GPLv2
Requires:   perl-Crypt-DES
Requires:   perl-Net-SNMP
Requires:   perl-Digest-HMAC
Requires:   perl-Digest-SHA1
Requires:   perl-Nagios-Cmd
Requires:   nagios
Buildarch:  noarch

# Renamed from nagios-plugin-collector
Obsoletes:  nagios-plugin-collector < 1.5-2
Provides:   nagios-plugin-collector = %{version}-%{release}

%description
This plugin collects the SNMP data once and forwards it to an UDP port. Its
configuration needs to be generated.
This application is part of the Vigilo Project <http://vigilo-project.org>

%prep
%setup -q -n %{module}

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
%defattr(-,root,root)
%doc COPYING README README.fr TODO host.example
%{_libdir}/%{name}
%{_libdir}/nagios/plugins/*
%config(noreplace) %{_sysconfdir}/*


%changelog
* Fri Mar 05 2010 Aurelien Bompard <aurelien.bompard@c-s.fr>
- new release

* Thu Jul 30 2009 Aurelien Bompard <aurelien.bompard@c-s.fr> - 1.5-2
- rename

* Fri Mar 20 2009  Thomas Burguiere <thomas.burguiere@c-s.fr> - 1.5-1
- first creation of the RPM from debian archive
