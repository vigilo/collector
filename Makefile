LIBDIR = /usr/lib
NLIBDIR = $(LIBDIR)/nagios/plugins
CLIBDIR = $(LIBDIR)/vigilo-collector
SYSCONFDIR = /etc
CONFDIR = $(SYSCONFDIR)/vigilo/collector
DESTDIR =

install:
	-mkdir -p $(DESTDIR)$(NLIBDIR) $(DESTDIR)$(CLIBDIR) $(DESTDIR)$(CONFDIR)
	sed -e 's,@NAGIOS_PLUGINS_DIR@,$(NLIBDIR),g;s,@CONFDIR@,$(CONFDIR),g' \
		Collector.in > $(DESTDIR)$(NLIBDIR)/Collector
	chmod 755 $(DESTDIR)$(NLIBDIR)/Collector
	touch --reference Collector.in $(DESTDIR)$(NLIBDIR)/Collector
	sed -e 's,@LIBDIR@,$(LIBDIR),g' general.conf.in > $(DESTDIR)$(CONFDIR)/general.conf
	chmod 644 $(DESTDIR)$(CONFDIR)/general.conf
	touch --reference general.conf.in $(DESTDIR)$(CONFDIR)/general.conf
	cp -pr lib/* $(DESTDIR)$(CLIBDIR)/
	mkdir $(DESTDIR)$(CLIBDIR)/ext
	find $(DESTDIR)$(CLIBDIR) -type d -name .svn -exec rm -rf {} \;


.PHONY: install
