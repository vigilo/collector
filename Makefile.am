my_confdir = $(sysconfdir)/vigilo/collector/
DIST_SUBDIRS = lib
SUBDIRS = . lib
CLEANFILES = $(nagiosplugins_SCRIPTS) $(nagiospluginsconf_DATA) $(man_MANS) $(my_conf_DATA)
EXTRA_DIST = *.txt *.in

nagiosplugins_SCRIPTS = Collector
nagiospluginsconf_DATA = vigilo-collector.cfg
man_MANS = Collector.1
my_conf_DATA = general.conf

Collector: Collector.pl.in Makefile
	$(SED) -e 's,@CONFDIR[@],$(my_confdir),g' $< > $@
	$(TOUCH) --reference=$< $@

general.conf: general.conf.in Makefile
	$(SED) -e 's,@LIBDIR[@],$(libdir),g;s,@SYSCONFDIR[@],$(sysconfdir),g;s,@LOCALSTATEDIR[@],$(localstatedir),g;s,@CMDPIPE[@],$(nagioscmdpipe),g' \
		$< > $@
	$(TOUCH) --reference=$< $@

vigilo-collector.cfg: vigilo-collector.cfg.in Makefile
	$(SED) -e 's,@PLUGINDIR[@],$(nagiospluginsdir),g' $< > $@
	$(TOUCH) --reference=$< $@

Collector.1: Collector
	$(PERLDOC) -oMan $< > $@
	$(TOUCH) --reference=$< $@
