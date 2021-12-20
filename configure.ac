AC_INIT([vigilo-collector], [m4_esyscmd_s([cat VERSION.txt])], [], [], [https://www.vigilo-nms.com/])
AC_PREREQ([2.59])
AC_CANONICAL_HOST
AM_INIT_AUTOMAKE([1.9 foreign])

AC_PROG_MKDIR_P
AC_PROG_SED

AC_PATH_PROG(PERL, perl, no)
if test "x$PERL" = "x"; then
  AC_MSG_ERROR([perl not found])
fi

AC_PATH_PROG(PERLDOC, perldoc)
if test "x$PERLDOC" = "x"; then
  AC_MSG_ERROR([perldoc not found])
fi

AC_PATH_PROG(TOUCH, touch)
if test "x$TOUCH" = "x"; then
  AC_MSG_ERROR([touch not found])
fi

AC_PATH_PROG(RMDIR, rmdir)
if test "x$RMDIR" = "x"; then
  AC_MSG_ERROR([rmdir not found])
fi


# Check that the dependencies are installed
for module in          \
  'Crypt::DES'         \
  'Digest::HMAC'       \
  'Digest::SHA1'       \
  'Math::RPN'          \
  'Nagios::Cmd'        \
  'Monitoring::Plugin' \
  'Net::SNMP'
do
  AC_MSG_CHECKING([for Perl module $module])
  if ${PERL} -e 'use '$module 2>/dev/null; then
    AC_MSG_RESULT([Ok])
  else
    AC_MSG_ERROR([Perl cannot find $module]);
  fi
done


AC_ARG_VAR(nagiospluginsconfdir,  [[SYSCONFDIR/nagios/plugins.d] Nagios plugins configuration directory])
if test -z "$nagiospluginsconfdir"; then
   nagiospluginsconfdir='${sysconfdir}/nagios/plugins.d'; fi

AC_ARG_VAR(nagiospluginsdir,  [[LIBDIR/nagios/plugins] Nagios plugins directory])
if test -z "$nagiospluginsdir"; then
   nagiospluginsdir='${libdir}/nagios/plugins'; fi

AC_ARG_VAR(nagioscmdpipe,  [[/var/spool/nagios/cmd/nagios.cmd] Nagios command pipe])
if test -z "$nagioscmdpipe"; then
   nagioscmdpipe='/var/spool/nagios/cmd/nagios.cmd'; fi


AC_CONFIG_FILES([Makefile lib/Makefile])

AC_SUBST(VERSION)

AC_OUTPUT
