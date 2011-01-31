NAME = collector
LIBDIR = /usr/lib
NLIBDIR = $(LIBDIR)/nagios/plugins
CLIBDIR = $(LIBDIR)/vigilo-collector
SYSCONFDIR = /etc
LOCALSTATEDIR = /var
CONFDIR = $(SYSCONFDIR)/vigilo/collector
DESTDIR =

INFILES = Collector general.conf pkg/cleanup.sh

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

install: $(INFILES)
	-mkdir -p $(DESTDIR)$(NLIBDIR) $(DESTDIR)$(CLIBDIR) $(DESTDIR)$(CONFDIR)
	install -m 755 -p Collector $(DESTDIR)$(NLIBDIR)/Collector
	install -m 644 -p general.conf $(DESTDIR)$(CONFDIR)/general.conf
	cp -pr lib/* $(DESTDIR)$(CLIBDIR)/
	mkdir $(DESTDIR)$(CLIBDIR)/ext
	find $(DESTDIR)$(CLIBDIR) -type d -name .svn -exec rm -rf {} \;
	install -m 755 -p -D pkg/cleanup.sh $(DESTDIR)/etc/cron.hourly/vigilo-collector-cleanup.sh

clean:
	rm -f $(INFILES)


SVN_REV = $(shell LANGUAGE=C LC_ALL=C svn info 2>/dev/null | awk '/^Revision:/ { print $$2 }')
rpm: clean pkg/$(NAME).$(DISTRO).spec
	mkdir -p build/$(NAME)
	rsync -a --exclude .svn --delete ./ build/$(NAME)
	mkdir -p build/rpm/{$(NAME),BUILD,TMP}
	cd build; tar -cjf rpm/$(NAME)/$(NAME).tar.bz2 $(NAME)
	cp pkg/$(NAME).$(DISTRO).spec build/rpm/$(NAME)/vigilo-$(NAME).spec
	rpmbuild -ba --define "_topdir $(CURDIR)/build/rpm" \
				 --define "_sourcedir %{_topdir}/$(NAME)" \
				 --define "_specdir %{_topdir}/$(NAME)" \
				 --define "_rpmdir %{_topdir}/$(NAME)" \
				 --define "_srcrpmdir %{_topdir}/$(NAME)" \
				 --define "_tmppath %{_topdir}/TMP" \
				 --define "_builddir %{_topdir}/BUILD" \
				 --define "svn .svn$(SVN_REV)" \
				 --define "dist .$(DIST_TAG)" \
				 build/rpm/$(NAME)/vigilo-$(NAME).spec
	mkdir -p dist
	find build/rpm/$(NAME) -type f -name "*.rpm" | xargs cp -a -f -t dist/


.PHONY: build install clean rpm
