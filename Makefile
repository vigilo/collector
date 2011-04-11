NAME = collector
PKGNAME = vigilo-$(NAME)
LIBDIR = /usr/lib
NLIBDIR = $(LIBDIR)/nagios/plugins
CLIBDIR = $(LIBDIR)/$(PKGNAME)
SYSCONFDIR = /etc
LOCALSTATEDIR = /var
CONFDIR = $(SYSCONFDIR)/vigilo/$(NAME)
DESTDIR =

VERSION := $(shell cat VERSION.txt)

INFILES = Collector general.conf pkg/cleanup.sh Collector.1

build: $(INFILES)

define find-distro
if [ -f /etc/debian_version ]; then \
	echo "debian" ;\
elif [ -f /etc/mandriva-release ]; then \
	echo "mandriva" ;\
elif [ -f /etc/redhat-release ]; then \
	echo "redhat" ;\
else \
	echo "unknown" ;\
fi
endef
DISTRO := $(shell $(find-distro))
DIST_TAG = $(DISTRO)

ifeq ($(DISTRO),debian)
	CMDPIPE = $(LOCALSTATEDIR)/spool/nagios/nagios.cmd
else ifeq ($(DISTRO),mandriva)
	CMDPIPE = $(LOCALSTATEDIR)/spool/nagios/nagios.cmd
else ifeq ($(DISTRO),redhat)
	CMDPIPE = $(LOCALSTATEDIR)/spool/nagios/cmd/nagios.cmd
else
	CMDPIPE = $(LOCALSTATEDIR)/spool/nagios/nagios.cmd
endif


Collector: Collector.pl.in
	sed -e 's,@NAGIOS_PLUGINS_DIR@,$(NLIBDIR),g;s,@CONFDIR@,$(CONFDIR),g' $^ > $@
general.conf: general.conf.in
	sed -e 's,@LIBDIR@,$(LIBDIR),g;s,@SYSCONFDIR@,$(SYSCONFDIR),g;s,@LOCALSTATEDIR@,$(LOCALSTATEDIR),g;s,@CMDPIPE@,$(CMDPIPE),g' \
		$^ > $@
pkg/cleanup.sh: pkg/cleanup.sh.in
	sed -e 's,@CONFDIR@,$(CONFDIR),g' $^ > $@
Collector.1: Collector
	perldoc -oMan -d $@ $^
man: Collector.1

install: $(INFILES)
	-mkdir -p $(DESTDIR)$(NLIBDIR) $(DESTDIR)$(CLIBDIR) $(DESTDIR)$(CONFDIR)
	install -m 755 -p Collector $(DESTDIR)$(NLIBDIR)/Collector
	install -m 644 -p general.conf $(DESTDIR)$(CONFDIR)/general.conf
	cp -pr lib/* $(DESTDIR)$(CLIBDIR)/
	mkdir $(DESTDIR)$(CLIBDIR)/ext
	find $(DESTDIR)$(CLIBDIR) -type d -name .svn -exec rm -rf {} \;
	install -m 755 -p -D pkg/cleanup.sh $(DESTDIR)/etc/cron.hourly/$(PKGNAME)-cleanup.sh

clean:
	rm -f $(INFILES)
	rm -rf build

sdist: dist/$(PKGNAME)-$(VERSION).tar.gz
dist/$(PKGNAME)-$(VERSION).tar.gz:
	mkdir -p build/sdist/$(PKGNAME)-$(VERSION)
	rsync -a --exclude .svn --exclude /dist --exclude /build --delete ./ build/sdist/$(PKGNAME)-$(VERSION)
	mkdir -p dist
	cd build/sdist; tar -czf $(CURDIR)/dist/$(PKGNAME)-$(VERSION).tar.gz $(PKGNAME)-$(VERSION)


SVN_REV = $(shell LANGUAGE=C LC_ALL=C svn info 2>/dev/null | awk '/^Revision:/ { print $$2 }')
rpm: clean pkg/$(NAME).$(DISTRO).spec dist/$(PKGNAME)-$(VERSION).tar.gz
	mkdir -p build/rpm/{$(NAME),BUILD,TMP}
	mv dist/$(PKGNAME)-$(VERSION).tar.gz build/rpm/$(NAME)/
	sed -e 's/@VERSION@/'`cat VERSION.txt`'/g' pkg/$(NAME).$(DISTRO).spec \
		> build/rpm/$(NAME)/$(PKGNAME).spec
	rpmbuild -ba --define "_topdir $(CURDIR)/build/rpm" \
				 --define "_sourcedir %{_topdir}/$(NAME)" \
				 --define "_specdir %{_topdir}/$(NAME)" \
				 --define "_rpmdir %{_topdir}/$(NAME)" \
				 --define "_srcrpmdir %{_topdir}/$(NAME)" \
				 --define "_tmppath %{_topdir}/TMP" \
				 --define "_builddir %{_topdir}/BUILD" \
				 --define "svn .svn$(SVN_REV)" \
				 --define "dist .$(DIST_TAG)" \
				 $(RPMBUILD_OPTS) \
				 build/rpm/$(NAME)/$(PKGNAME).spec
	mkdir -p dist
	find build/rpm/$(NAME) -type f -name "*.rpm" | xargs cp -a -f -t dist/


.PHONY: build install clean rpm man sdist
