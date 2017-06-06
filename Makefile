NAME = collector

INFILES = Collector general.conf vigilo-collector.cfg \
          pkg/cleanup.sh pkg/cronjobs Collector.1

all: $(INFILES)

include buildenv/Makefile.common.nopython

CLIBDIR = $(LIBDIR)/$(PKGNAME)

Collector: Collector.pl.in
	sed -e 's,@NAGIOS_PLUGINS_DIR@,$(NPLUGDIR),g;s,@CONFDIR@,$(CONFDIR),g' $^ > $@
general.conf: general.conf.in
	sed -e 's,@LIBDIR@,$(LIBDIR),g;s,@SYSCONFDIR@,$(SYSCONFDIR),g;s,@LOCALSTATEDIR@,$(LOCALSTATEDIR),g;s,@CMDPIPE@,$(NAGIOSCMDPIPE),g' \
		$^ > $@
vigilo-collector.cfg: vigilo-collector.cfg.in
	sed -e 's,@PLUGINDIR@,$(NPLUGDIR),g' $^ > $@
pkg/cleanup.sh: pkg/cleanup.sh.in
	sed -e 's,@CONFDIR@,$(CONFDIR),g' $^ > $@
pkg/cronjobs: pkg/cronjobs.in
	sed -e 's,@CLIBDIR@,$(CLIBDIR),g' $^ > $@

man: Collector.1
Collector.1: Collector
	chmod a+rx ./
	perldoc -oMan $^ > $@

install: install_pkg install_permissions

install_pkg: $(INFILES)
	-mkdir -p $(DESTDIR)$(NPLUGDIR) $(DESTDIR)$(CLIBDIR) $(DESTDIR)$(CONFDIR)
	-mkdir -p $(DESTDIR)$(NPCONFDIR) $(DESTDIR)$(SYSCONFDIR)/cron.d
	install -m 755 -p Collector $(DESTDIR)$(NPLUGDIR)/
	install -m 644 -p general.conf $(DESTDIR)$(CONFDIR)/
	install -m 644 -p vigilo-collector.cfg $(DESTDIR)$(NPCONFDIR)/
	cp -pr lib/* $(DESTDIR)$(CLIBDIR)/
	mkdir -p $(DESTDIR)$(CLIBDIR)/ext
	install -m 755 -p pkg/cleanup.sh $(DESTDIR)$(CLIBDIR)/
	install -m 644 -p pkg/cronjobs $(DESTDIR)$(SYSCONFDIR)/cron.d/$(PKGNAME)$(CRONEXT)

install_pkg_systemd: install_pkg
	mkdir -p $(DESTDIR)$(SYSTEMDDIR) $(DESTDIR)$(BINDIR)/
	install -m 755 -p worker/vigilo-collector $(DESTDIR)$(BINDIR)/
	install -m 644 -p worker/vigilo-collector.service $(DESTDIR)$(SYSTEMDDIR)/

install_permissions:
	chown root:root -R $(DESTDIR)$(CLIBDIR)
	find $(DESTDIR)$(CLIBDIR) -type d -exec chmod a+rx {} \;
	find $(DESTDIR)$(CLIBDIR) -type f -exec chmod a+r  {} \;

tests: bin/python
	VIGILO_DEBUG=1 bin/python worker/tests/test.py

clean: clean_common
	rm -f $(INFILES)

doc: sphinxdoc

.PHONY: all clean man doc tests \
	install install_pkg install_pkg_systemd install_permissions
