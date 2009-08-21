NLIBDIR = /usr/lib/nagios/plugins
CLIBDIR = /usr/lib/vigilo-collector
CONFDIR = /etc/vigilo-collector
DESTDIR =

install:
	-mkdir -p $(DESTDIR)$(NLIBDIR) $(DESTDIR)$(CLIBDIR) $(DESTDIR)$(CONFDIR)
	install -p -m 755 Collector $(DESTDIR)$(NLIBDIR)/Collector
	install -p -m 644 general.conf $(DESTDIR)$(CONFDIR)/general.conf
	cp -pr lib/* $(DESTDIR)$(CLIBDIR)/
	mkdir $(DESTDIR)$(CLIBDIR)/ext
	find $(DESTDIR)$(CLIBDIR) -type d -name .svn -exec rm -rf {} \;

tests:
	@true

clean:
	@true

.PHONY: install tests clean
