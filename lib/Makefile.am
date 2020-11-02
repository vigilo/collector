my_clibdir = $(pkglibdir)

my_clib_DATA = *.pm
EXTRA_DIST = $(my_clib_DATA)

install-data-hook:
	$(MKDIR_P) -v $(DESTDIR)$(my_clibdir)/ext

uninstall-local:
	$(RMDIR) -v $(DESTDIR)$(my_clibdir)/ext 2>/dev/null || :
