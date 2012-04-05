NAME = collector

INFILES = Collector general.conf pkg/cleanup.sh pkg/cronjobs Collector.1

all: $(INFILES)

include buildenv/Makefile.common.nopython

CLIBDIR = $(LIBDIR)/$(PKGNAME)

Collector: Collector.pl.in
	sed -e 's,@NAGIOS_PLUGINS_DIR@,$(NPLUGDIR),g;s,@CONFDIR@,$(CONFDIR),g' $^ > $@
general.conf: general.conf.in
	sed -e 's,@LIBDIR@,$(LIBDIR),g;s,@SYSCONFDIR@,$(SYSCONFDIR),g;s,@LOCALSTATEDIR@,$(LOCALSTATEDIR),g;s,@CMDPIPE@,$(NAGIOSCMDPIPE),g' \
		$^ > $@
pkg/cleanup.sh: pkg/cleanup.sh.in
	sed -e 's,@CONFDIR@,$(CONFDIR),g' $^ > $@
pkg/cronjobs: pkg/cronjobs.in
	sed -e 's,@CLIBDIR@,$(CLIBDIR),g' $^ > $@

man: Collector.1
Collector.1: Collector
	perldoc -oMan $^ > $@

install: $(INFILES)
	-mkdir -p $(DESTDIR)$(NPLUGDIR) $(DESTDIR)$(CLIBDIR) $(DESTDIR)$(CONFDIR)
	install -m 755 -p Collector $(DESTDIR)$(NPLUGDIR)/Collector
	install -m 644 -p general.conf $(DESTDIR)$(CONFDIR)/general.conf
	cp -pr lib/* $(DESTDIR)$(CLIBDIR)/
	mkdir -p $(DESTDIR)$(CLIBDIR)/ext
	find $(DESTDIR)$(CLIBDIR) -type d -name .svn -exec rm -rf {} \;
	install -m 755 -p -D pkg/cleanup.sh $(DESTDIR)$(CLIBDIR)/cleanup.sh
	install -m 644 -p -D pkg/cronjobs $(DESTDIR)/etc/cron.d/$(PKGNAME).cron

clean: clean_common
	rm -f $(INFILES)


.PHONY: all install clean man
