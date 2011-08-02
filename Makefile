NAME = collector
PKGNAME = vigilo-$(NAME)
LIBDIR = /usr/lib
NPLUGDIR = /usr/lib$(if $(realpath /usr/lib64),64,)/nagios/plugins
CLIBDIR = $(LIBDIR)/$(PKGNAME)
SYSCONFDIR = /etc
LOCALSTATEDIR = /var
CONFDIR = $(SYSCONFDIR)/vigilo/$(NAME)
DESTDIR =

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

VERSION := $(shell cat VERSION.txt)

INFILES = Collector general.conf pkg/cleanup.sh pkg/cronjobs Collector.1

build: $(INFILES)

Collector: Collector.pl.in
	sed -e 's,@NAGIOS_PLUGINS_DIR@,$(NPLUGDIR),g;s,@CONFDIR@,$(CONFDIR),g' $^ > $@
general.conf: general.conf.in
	sed -e 's,@LIBDIR@,$(LIBDIR),g;s,@SYSCONFDIR@,$(SYSCONFDIR),g;s,@LOCALSTATEDIR@,$(LOCALSTATEDIR),g;s,@CMDPIPE@,$(CMDPIPE),g' \
		$^ > $@
pkg/cleanup.sh: pkg/cleanup.sh.in
	sed -e 's,@CONFDIR@,$(CONFDIR),g' $^ > $@
pkg/cronjobs: pkg/cronjobs.in
	sed -e 's,@CLIBDIR@,$(CLIBDIR),g' $^ > $@

man: Collector.1
Collector.1: Collector
	perldoc -oMan -d $@ $^

install: $(INFILES)
	-mkdir -p $(DESTDIR)$(NPLUGDIR) $(DESTDIR)$(CLIBDIR) $(DESTDIR)$(CONFDIR)
	install -m 755 -p Collector $(DESTDIR)$(NPLUGDIR)/Collector
	install -m 644 -p general.conf $(DESTDIR)$(CONFDIR)/general.conf
	cp -pr lib/* $(DESTDIR)$(CLIBDIR)/
	mkdir -p $(DESTDIR)$(CLIBDIR)/ext
	find $(DESTDIR)$(CLIBDIR) -type d -name .svn -exec rm -rf {} \;
	install -m 755 -p -D pkg/cleanup.sh $(DESTDIR)$(CLIBDIR)/cleanup.sh
	install -m 644 -p -D pkg/cronjobs $(DESTDIR)/etc/cron.d/$(PKGNAME).cron

clean:
	rm -f $(INFILES)
	rm -rf build


GIT_CHSET = $(shell git log -1 --format=format:%h .)
GIT_CHSET_COUNT = $(shell git rev-list --no-merges --count $(GIT_CHSET))
RELEASE_TAG = $(if $(RELEASE),1,0.$(GIT_CHSET_COUNT).g$(GIT_CHSET))

sdist: dist/$(PKGNAME)-$(VERSION)$(if $(RELEASE),,.g$(GIT_CHSET)).tar.gz
dist/$(PKGNAME)-$(VERSION).tar.gz dist/$(PKGNAME)-$(VERSION)%.tar.gz:
	mkdir -p build/sdist/$(notdir $(patsubst %.tar.gz,%,$@))
	rsync -aL --exclude .svn --exclude /dist --exclude /build --delete ./ build/sdist/$(notdir $(patsubst %.tar.gz,%,$@))
	mkdir -p dist
	cd build/sdist; tar -czf $(CURDIR)/$@ $(notdir $(patsubst %.tar.gz,%,$@))
	@echo "Source tarball is: $@"

rpm: clean pkg/$(NAME).$(DISTRO).spec dist/$(PKGNAME)-$(VERSION).tar.gz
	mkdir -p build/rpm/{$(NAME),BUILD,TMP}
	mv dist/$(PKGNAME)-$(VERSION).tar.gz build/rpm/$(NAME)/
	sed -e 's/@VERSION@/'`cat VERSION.txt`'/;s/@RELEASE@/$(RELEASE_TAG)/' \
		pkg/$(NAME).$(DISTRO).spec > build/rpm/$(NAME)/$(PKGNAME).spec
	rpmbuild -ba --define "_topdir $(CURDIR)/build/rpm" \
				 --define "_sourcedir %{_topdir}/$(NAME)" \
				 --define "_specdir %{_topdir}/$(NAME)" \
				 --define "_rpmdir %{_topdir}/$(NAME)" \
				 --define "_srcrpmdir %{_topdir}/$(NAME)" \
				 --define "_tmppath %{_topdir}/TMP" \
				 --define "_builddir %{_topdir}/BUILD" \
				 --define "dist .$(DIST_TAG)" \
				 $(RPMBUILD_OPTS) \
				 build/rpm/$(NAME)/$(PKGNAME).spec
	mkdir -p dist
	find build/rpm/$(NAME) -type f -name "*.rpm" | xargs cp -a -f -t dist/


.PHONY: build install clean rpm man sdist
