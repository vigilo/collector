LIBDIR = /usr/lib
NLIBDIR = $(LIBDIR)/nagios/plugins
CLIBDIR = $(LIBDIR)/vigilo-collector
SYSCONFDIR = /etc
LOCALSTATEDIR = /var
CONFDIR = $(SYSCONFDIR)/vigilo/collector
DESTDIR =

INFILES = Collector general.conf

build: $(INFILES)

Collector: Collector.pl.in
	sed -e 's,@NAGIOS_PLUGINS_DIR@,$(NLIBDIR),g;s,@CONFDIR@,$(CONFDIR),g' $^ > $@
general.conf: general.conf.in
	sed -e 's,@LIBDIR@,$(LIBDIR),g;s,@SYSCONFDIR@,$(SYSCONFDIR),g;s,@LOCALSTATEDIR@,$(LOCALSTATEDIR),g' \
		$^ > $@

install: $(INFILES)
	-mkdir -p $(DESTDIR)$(NLIBDIR) $(DESTDIR)$(CLIBDIR) $(DESTDIR)$(CONFDIR)
	install -m 755 Collector $(DESTDIR)$(NLIBDIR)/Collector
	install -m 644 general.conf $(DESTDIR)$(CONFDIR)/general.conf
	cp -pr lib/* $(DESTDIR)$(CLIBDIR)/
	mkdir $(DESTDIR)$(CLIBDIR)/ext
	find $(DESTDIR)$(CLIBDIR) -type d -name .svn -exec rm -rf {} \;

clean:
	rm -f $(INFILES)


.PHONY: build install clean
