%define	name	nagios-plugin-collector
%define	version	1.13
%define release 1

Name:		%{name}
Summary:	Centralized collector plugin for Nagios
Version:	%{version}
Release:	%{release}
Source0:	Collector.tar.bz2

Group:		System/Servers
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-build
License:	GPLv2
#Copyright:	CS-SI
Requires:	perl-Crypt-DES
Requires:	perl-Net-SNMP
Requires:	perl-Digest-HMAC
Requires:	perl-Digest-SHA1
Buildarch:	noarch

%description
Centralized collector plugin for Nagios
This plugin collects the SNMP data once and forwards it
to an UDP port. Its configuration needs to be generated
This application is part of the Vigilo Project <http://vigilo-project.org>

%prep
%setup -q -n collector


%install
rm -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT  


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc COPYING
#%doc %{_datadir}/docs/*
%{_libdir}/*
%{_sysconfdir}/*
#%_datadir/%{name}


%changelog
* Fri Mar 20 2009  Thomas Burguiere <thomas.burguiere@c-s.fr>
- first creation of the RPM from debian archive
