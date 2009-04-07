%define	name	nagios-plugin-collector
%define	version	1.5
%define release 1

Name:		%{name}
Summary:	Centralized collector plugin for Nagios
Version:	%{version}
Release:	%{release}
Source0:	collector.tar.bz2

URL:        http://www.projet-vigilo.org
Group:		System/Servers
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-build
License:	GPLv2
Requires:	perl-Crypt-DES
Requires:	perl-Net-SNMP
Requires:	perl-Digest-HMAC
Requires:	perl-Digest-SHA1
Buildarch:	noarch

%description
This plugin collects the SNMP data once and forwards it to an UDP port. Its
configuration needs to be generated.
This application is part of the Vigilo Project <http://vigilo-project.org>

%prep
%setup -q -n collector

%build

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT  


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc COPYING README TODO host.example
#%doc %{_datadir}/docs/*
%{_libdir}/*
%config(noreplace) %{_sysconfdir}/*
#%_datadir/%{name}


%changelog
* Fri Mar 20 2009  Thomas Burguiere <thomas.burguiere@c-s.fr> - 1.5-1
- first creation of the RPM from debian archive
