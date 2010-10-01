# DO NOT EDIT! GENERATED AUTOMATICALLY!
# Copyright (C) 2002-2010 Free Software Foundation, Inc.
#
# This file is free software, distributed under the terms of the GNU
# General Public License.  As a special exception to the GNU General
# Public License, this file may be distributed as part of a program
# that contains a configuration script generated by Autoconf, under
# the same distribution terms as the rest of that program.
#
# Generated by gnulib-tool.
#
# This file represents the compiled summary of the specification in
# gnulib-cache.m4. It lists the computed macro invocations that need
# to be invoked from configure.ac.
# In projects that use version control, this file can be treated like
# other built files.


# This macro should be invoked from ./configure.ac, in the section
# "Checks for programs", right after AC_PROG_CC, and certainly before
# any checks for libraries, header files, types and library functions.
AC_DEFUN([gl_EARLY],
[
  m4_pattern_forbid([^gl_[A-Z]])dnl the gnulib macro namespace
  m4_pattern_allow([^gl_ES$])dnl a valid locale name
  m4_pattern_allow([^gl_LIBOBJS$])dnl a variable
  m4_pattern_allow([^gl_LTLIBOBJS$])dnl a variable
  AC_REQUIRE([AC_PROG_RANLIB])
  AC_REQUIRE([AM_PROG_CC_C_O])
  # Code from module alignof:
  # Code from module alloca-opt:
  # Code from module announce-gen:
  # Code from module arg-nonnull:
  # Code from module arpa_inet:
  # Code from module autobuild:
  AB_INIT
  # Code from module byteswap:
  # Code from module c++defs:
  # Code from module c-ctype:
  # Code from module c-strcase:
  # Code from module c-strcaseeq:
  # Code from module canonicalize-lgpl:
  # Code from module configmake:
  # Code from module duplocale:
  # Code from module environ:
  # Code from module errno:
  # Code from module extensions:
  AC_REQUIRE([gl_USE_SYSTEM_EXTENSIONS])
  # Code from module float:
  # Code from module flock:
  # Code from module fpieee:
  AC_REQUIRE([gl_FP_IEEE])
  # Code from module full-read:
  # Code from module full-write:
  # Code from module func:
  # Code from module gendocs:
  # Code from module getaddrinfo:
  # Code from module gettext-h:
  # Code from module git-version-gen:
  # Code from module gitlog-to-changelog:
  # Code from module gnu-web-doc-update:
  # Code from module gnumakefile:
  # Code from module gnupload:
  # Code from module gperf:
  # Code from module havelib:
  # Code from module hostent:
  # Code from module iconv:
  # Code from module iconv-h:
  # Code from module iconv_open:
  # Code from module iconv_open-utf:
  # Code from module include_next:
  # Code from module inet_ntop:
  # Code from module inet_pton:
  # Code from module inline:
  # Code from module isinf:
  # Code from module isnan:
  # Code from module isnand:
  # Code from module isnanf:
  # Code from module isnanl:
  # Code from module lib-symbol-versions:
  # Code from module lib-symbol-visibility:
  # Code from module libunistring:
  # Code from module localcharset:
  # Code from module locale:
  # Code from module lstat:
  # Code from module maintainer-makefile:
  # Code from module malloc-posix:
  # Code from module malloca:
  # Code from module math:
  # Code from module mbrlen:
  # Code from module mbrtowc:
  # Code from module mbsinit:
  # Code from module memchr:
  # Code from module multiarch:
  # Code from module netdb:
  # Code from module netinet_in:
  # Code from module pathmax:
  # Code from module putenv:
  # Code from module readlink:
  # Code from module safe-read:
  # Code from module safe-write:
  # Code from module servent:
  # Code from module size_max:
  # Code from module snprintf:
  # Code from module socklen:
  # Code from module ssize_t:
  # Code from module stat:
  # Code from module stat-time:
  # Code from module stdarg:
  dnl Some compilers (e.g., AIX 5.3 cc) need to be in c99 mode
  dnl for the builtin va_copy to work.  With Autoconf 2.60 or later,
  dnl AC_PROG_CC_STDC arranges for this.  With older Autoconf AC_PROG_CC_STDC
  dnl shouldn't hurt, though installers are on their own to set c99 mode.
  AC_REQUIRE([AC_PROG_CC_STDC])
  # Code from module stdbool:
  # Code from module stddef:
  # Code from module stdint:
  # Code from module stdio:
  # Code from module stdlib:
  # Code from module strcase:
  # Code from module streq:
  # Code from module strftime:
  # Code from module striconveh:
  # Code from module string:
  # Code from module strings:
  # Code from module sys_file:
  # Code from module sys_socket:
  # Code from module sys_stat:
  # Code from module time:
  # Code from module time_r:
  # Code from module unistd:
  # Code from module unistr/base:
  # Code from module unistr/u8-mbtouc:
  # Code from module unistr/u8-mbtouc-unsafe:
  # Code from module unistr/u8-mbtoucr:
  # Code from module unistr/u8-prev:
  # Code from module unistr/u8-uctomb:
  # Code from module unitypes:
  # Code from module unused-parameter:
  # Code from module useless-if-before-free:
  # Code from module vasnprintf:
  # Code from module vc-list-files:
  # Code from module verify:
  # Code from module version-etc:
  # Code from module version-etc-fsf:
  # Code from module vsnprintf:
  # Code from module warn-on-use:
  # Code from module warnings:
  # Code from module wchar:
  # Code from module write:
  # Code from module xsize:
])

# This macro should be invoked from ./configure.ac, in the section
# "Check for header files, types and library functions".
AC_DEFUN([gl_INIT],
[
  AM_CONDITIONAL([GL_COND_LIBTOOL], [true])
  gl_cond_libtool=true
  gl_m4_base='m4'
  m4_pushdef([AC_LIBOBJ], m4_defn([gl_LIBOBJ]))
  m4_pushdef([AC_REPLACE_FUNCS], m4_defn([gl_REPLACE_FUNCS]))
  m4_pushdef([AC_LIBSOURCES], m4_defn([gl_LIBSOURCES]))
  m4_pushdef([gl_LIBSOURCES_LIST], [])
  m4_pushdef([gl_LIBSOURCES_DIR], [])
  gl_COMMON
  gl_source_base='lib'
  # Code from module alignof:
  # Code from module alloca-opt:
  gl_FUNC_ALLOCA
  # Code from module announce-gen:
  # Code from module arg-nonnull:
  # Code from module arpa_inet:
  gl_HEADER_ARPA_INET
  AC_PROG_MKDIR_P
  # Code from module autobuild:
  # Code from module byteswap:
  gl_BYTESWAP
  # Code from module c++defs:
  # Code from module c-ctype:
  # Code from module c-strcase:
  # Code from module c-strcaseeq:
  # Code from module canonicalize-lgpl:
  gl_CANONICALIZE_LGPL
  gl_MODULE_INDICATOR([canonicalize-lgpl])
  gl_STDLIB_MODULE_INDICATOR([canonicalize_file_name])
  gl_STDLIB_MODULE_INDICATOR([realpath])
  # Code from module configmake:
  # Code from module duplocale:
  gl_FUNC_DUPLOCALE
  gl_LOCALE_MODULE_INDICATOR([duplocale])
  # Code from module environ:
  gl_ENVIRON
  gl_UNISTD_MODULE_INDICATOR([environ])
  # Code from module errno:
  gl_HEADER_ERRNO_H
  # Code from module extensions:
  # Code from module float:
  gl_FLOAT_H
  # Code from module flock:
  gl_FUNC_FLOCK
  gl_HEADER_SYS_FILE_MODULE_INDICATOR([flock])
  # Code from module fpieee:
  # Code from module full-read:
  # Code from module full-write:
  # Code from module func:
  gl_FUNC
  # Code from module gendocs:
  # Code from module getaddrinfo:
  gl_GETADDRINFO
  gl_NETDB_MODULE_INDICATOR([getaddrinfo])
  # Code from module gettext-h:
  AC_SUBST([LIBINTL])
  AC_SUBST([LTLIBINTL])
  # Code from module git-version-gen:
  # Code from module gitlog-to-changelog:
  # Code from module gnu-web-doc-update:
  # Code from module gnumakefile:
  # Autoconf 2.61a.99 and earlier don't support linking a file only
  # in VPATH builds.  But since GNUmakefile is for maintainer use
  # only, it does not matter if we skip the link with older autoconf.
  # Automake 1.10.1 and earlier try to remove GNUmakefile in non-VPATH
  # builds, so use a shell variable to bypass this.
  GNUmakefile=GNUmakefile
  m4_if(m4_version_compare([2.61a.100],
  	m4_defn([m4_PACKAGE_VERSION])), [1], [],
        [AC_CONFIG_LINKS([$GNUmakefile:$GNUmakefile], [],
  	[GNUmakefile=$GNUmakefile])])
  # Code from module gnupload:
  # Code from module gperf:
  # Code from module havelib:
  # Code from module hostent:
  gl_HOSTENT
  # Code from module iconv:
  AM_ICONV
  # Code from module iconv-h:
  gl_ICONV_H
  # Code from module iconv_open:
  gl_FUNC_ICONV_OPEN
  # Code from module iconv_open-utf:
  gl_FUNC_ICONV_OPEN_UTF
  # Code from module include_next:
  # Code from module inet_ntop:
  gl_FUNC_INET_NTOP
  gl_ARPA_INET_MODULE_INDICATOR([inet_ntop])
  # Code from module inet_pton:
  gl_FUNC_INET_PTON
  gl_ARPA_INET_MODULE_INDICATOR([inet_pton])
  # Code from module inline:
  gl_INLINE
  # Code from module isinf:
  gl_ISINF
  gl_MATH_MODULE_INDICATOR([isinf])
  # Code from module isnan:
  gl_ISNAN
  gl_MATH_MODULE_INDICATOR([isnan])
  # Code from module isnand:
  gl_FUNC_ISNAND
  gl_MATH_MODULE_INDICATOR([isnand])
  # Code from module isnanf:
  gl_FUNC_ISNANF
  gl_MATH_MODULE_INDICATOR([isnanf])
  # Code from module isnanl:
  gl_FUNC_ISNANL
  gl_MATH_MODULE_INDICATOR([isnanl])
  # Code from module lib-symbol-versions:
  gl_LD_VERSION_SCRIPT
  # Code from module lib-symbol-visibility:
  gl_VISIBILITY
  # Code from module libunistring:
  gl_LIBUNISTRING
  # Code from module localcharset:
  gl_LOCALCHARSET
  LOCALCHARSET_TESTS_ENVIRONMENT="CHARSETALIASDIR=\"\$(top_builddir)/$gl_source_base\""
  AC_SUBST([LOCALCHARSET_TESTS_ENVIRONMENT])
  # Code from module locale:
  gl_LOCALE_H
  # Code from module lstat:
  gl_FUNC_LSTAT
  gl_SYS_STAT_MODULE_INDICATOR([lstat])
  # Code from module maintainer-makefile:
  AC_CONFIG_COMMANDS_PRE([m4_ifdef([AH_HEADER],
    [AC_SUBST([CONFIG_INCLUDE], m4_defn([AH_HEADER]))])])
  # Code from module malloc-posix:
  gl_FUNC_MALLOC_POSIX
  gl_STDLIB_MODULE_INDICATOR([malloc-posix])
  # Code from module malloca:
  gl_MALLOCA
  # Code from module math:
  gl_MATH_H
  # Code from module mbrlen:
  gl_FUNC_MBRLEN
  gl_WCHAR_MODULE_INDICATOR([mbrlen])
  # Code from module mbrtowc:
  gl_FUNC_MBRTOWC
  gl_WCHAR_MODULE_INDICATOR([mbrtowc])
  # Code from module mbsinit:
  gl_FUNC_MBSINIT
  gl_WCHAR_MODULE_INDICATOR([mbsinit])
  # Code from module memchr:
  gl_FUNC_MEMCHR
  gl_STRING_MODULE_INDICATOR([memchr])
  # Code from module multiarch:
  gl_MULTIARCH
  # Code from module netdb:
  gl_HEADER_NETDB
  # Code from module netinet_in:
  gl_HEADER_NETINET_IN
  AC_PROG_MKDIR_P
  # Code from module pathmax:
  gl_PATHMAX
  # Code from module putenv:
  gl_FUNC_PUTENV
  gl_STDLIB_MODULE_INDICATOR([putenv])
  # Code from module readlink:
  gl_FUNC_READLINK
  gl_UNISTD_MODULE_INDICATOR([readlink])
  # Code from module safe-read:
  gl_SAFE_READ
  # Code from module safe-write:
  gl_SAFE_WRITE
  # Code from module servent:
  gl_SERVENT
  # Code from module size_max:
  gl_SIZE_MAX
  # Code from module snprintf:
  gl_FUNC_SNPRINTF
  gl_STDIO_MODULE_INDICATOR([snprintf])
  # Code from module socklen:
  gl_TYPE_SOCKLEN_T
  # Code from module ssize_t:
  gt_TYPE_SSIZE_T
  # Code from module stat:
  gl_FUNC_STAT
  gl_SYS_STAT_MODULE_INDICATOR([stat])
  # Code from module stat-time:
  gl_STAT_TIME
  gl_STAT_BIRTHTIME
  # Code from module stdarg:
  gl_STDARG_H
  # Code from module stdbool:
  AM_STDBOOL_H
  # Code from module stddef:
  gl_STDDEF_H
  # Code from module stdint:
  gl_STDINT_H
  # Code from module stdio:
  gl_STDIO_H
  # Code from module stdlib:
  gl_STDLIB_H
  # Code from module strcase:
  gl_STRCASE
  # Code from module streq:
  # Code from module strftime:
  gl_FUNC_GNU_STRFTIME
  # Code from module striconveh:
  if test $gl_cond_libtool = false; then
    gl_ltlibdeps="$gl_ltlibdeps $LTLIBICONV"
    gl_libdeps="$gl_libdeps $LIBICONV"
  fi
  # Code from module string:
  gl_HEADER_STRING_H
  # Code from module strings:
  gl_HEADER_STRINGS_H
  # Code from module sys_file:
  gl_HEADER_SYS_FILE_H
  AC_PROG_MKDIR_P
  # Code from module sys_socket:
  gl_HEADER_SYS_SOCKET
  AC_PROG_MKDIR_P
  # Code from module sys_stat:
  gl_HEADER_SYS_STAT_H
  AC_PROG_MKDIR_P
  # Code from module time:
  gl_HEADER_TIME_H
  # Code from module time_r:
  gl_TIME_R
  gl_TIME_MODULE_INDICATOR([time_r])
  # Code from module unistd:
  gl_UNISTD_H
  # Code from module unistr/base:
  gl_LIBUNISTRING_LIBHEADER([0.9.2], [unistr.h])
  # Code from module unistr/u8-mbtouc:
  gl_MODULE_INDICATOR([unistr/u8-mbtouc])
  gl_LIBUNISTRING_MODULE([0.9], [unistr/u8-mbtouc])
  # Code from module unistr/u8-mbtouc-unsafe:
  gl_MODULE_INDICATOR([unistr/u8-mbtouc-unsafe])
  gl_LIBUNISTRING_MODULE([0.9], [unistr/u8-mbtouc-unsafe])
  # Code from module unistr/u8-mbtoucr:
  gl_MODULE_INDICATOR([unistr/u8-mbtoucr])
  gl_LIBUNISTRING_MODULE([0.9], [unistr/u8-mbtoucr])
  # Code from module unistr/u8-prev:
  gl_LIBUNISTRING_MODULE([0.9], [unistr/u8-prev])
  # Code from module unistr/u8-uctomb:
  gl_MODULE_INDICATOR([unistr/u8-uctomb])
  gl_LIBUNISTRING_MODULE([0.9], [unistr/u8-uctomb])
  # Code from module unitypes:
  gl_LIBUNISTRING_LIBHEADER([0.9], [unitypes.h])
  # Code from module unused-parameter:
  # Code from module useless-if-before-free:
  # Code from module vasnprintf:
  gl_FUNC_VASNPRINTF
  # Code from module vc-list-files:
  # Code from module verify:
  # Code from module version-etc:
  gl_VERSION_ETC
  # Code from module version-etc-fsf:
  # Code from module vsnprintf:
  gl_FUNC_VSNPRINTF
  gl_STDIO_MODULE_INDICATOR([vsnprintf])
  # Code from module warn-on-use:
  # Code from module warnings:
  AC_SUBST([WARN_CFLAGS])
  # Code from module wchar:
  gl_WCHAR_H
  # Code from module write:
  gl_FUNC_WRITE
  gl_UNISTD_MODULE_INDICATOR([write])
  # Code from module xsize:
  gl_XSIZE
  # End of code from modules
  m4_ifval(gl_LIBSOURCES_LIST, [
    m4_syscmd([test ! -d ]m4_defn([gl_LIBSOURCES_DIR])[ ||
      for gl_file in ]gl_LIBSOURCES_LIST[ ; do
        if test ! -r ]m4_defn([gl_LIBSOURCES_DIR])[/$gl_file ; then
          echo "missing file ]m4_defn([gl_LIBSOURCES_DIR])[/$gl_file" >&2
          exit 1
        fi
      done])dnl
      m4_if(m4_sysval, [0], [],
        [AC_FATAL([expected source file, required through AC_LIBSOURCES, not found])])
  ])
  m4_popdef([gl_LIBSOURCES_DIR])
  m4_popdef([gl_LIBSOURCES_LIST])
  m4_popdef([AC_LIBSOURCES])
  m4_popdef([AC_REPLACE_FUNCS])
  m4_popdef([AC_LIBOBJ])
  AC_CONFIG_COMMANDS_PRE([
    gl_libobjs=
    gl_ltlibobjs=
    if test -n "$gl_LIBOBJS"; then
      # Remove the extension.
      sed_drop_objext='s/\.o$//;s/\.obj$//'
      for i in `for i in $gl_LIBOBJS; do echo "$i"; done | sed -e "$sed_drop_objext" | sort | uniq`; do
        gl_libobjs="$gl_libobjs $i.$ac_objext"
        gl_ltlibobjs="$gl_ltlibobjs $i.lo"
      done
    fi
    AC_SUBST([gl_LIBOBJS], [$gl_libobjs])
    AC_SUBST([gl_LTLIBOBJS], [$gl_ltlibobjs])
  ])
  gltests_libdeps=
  gltests_ltlibdeps=
  m4_pushdef([AC_LIBOBJ], m4_defn([gltests_LIBOBJ]))
  m4_pushdef([AC_REPLACE_FUNCS], m4_defn([gltests_REPLACE_FUNCS]))
  m4_pushdef([AC_LIBSOURCES], m4_defn([gltests_LIBSOURCES]))
  m4_pushdef([gltests_LIBSOURCES_LIST], [])
  m4_pushdef([gltests_LIBSOURCES_DIR], [])
  gl_COMMON
  gl_source_base='tests'
changequote(,)dnl
  gltests_WITNESS=IN_`echo "${PACKAGE-$PACKAGE_TARNAME}" | LC_ALL=C tr abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ | LC_ALL=C sed -e 's/[^A-Z0-9_]/_/g'`_GNULIB_TESTS
changequote([, ])dnl
  AC_SUBST([gltests_WITNESS])
  gl_module_indicator_condition=$gltests_WITNESS
  m4_pushdef([gl_MODULE_INDICATOR_CONDITION], [$gl_module_indicator_condition])
  m4_popdef([gl_MODULE_INDICATOR_CONDITION])
  m4_ifval(gltests_LIBSOURCES_LIST, [
    m4_syscmd([test ! -d ]m4_defn([gltests_LIBSOURCES_DIR])[ ||
      for gl_file in ]gltests_LIBSOURCES_LIST[ ; do
        if test ! -r ]m4_defn([gltests_LIBSOURCES_DIR])[/$gl_file ; then
          echo "missing file ]m4_defn([gltests_LIBSOURCES_DIR])[/$gl_file" >&2
          exit 1
        fi
      done])dnl
      m4_if(m4_sysval, [0], [],
        [AC_FATAL([expected source file, required through AC_LIBSOURCES, not found])])
  ])
  m4_popdef([gltests_LIBSOURCES_DIR])
  m4_popdef([gltests_LIBSOURCES_LIST])
  m4_popdef([AC_LIBSOURCES])
  m4_popdef([AC_REPLACE_FUNCS])
  m4_popdef([AC_LIBOBJ])
  AC_CONFIG_COMMANDS_PRE([
    gltests_libobjs=
    gltests_ltlibobjs=
    if test -n "$gltests_LIBOBJS"; then
      # Remove the extension.
      sed_drop_objext='s/\.o$//;s/\.obj$//'
      for i in `for i in $gltests_LIBOBJS; do echo "$i"; done | sed -e "$sed_drop_objext" | sort | uniq`; do
        gltests_libobjs="$gltests_libobjs $i.$ac_objext"
        gltests_ltlibobjs="$gltests_ltlibobjs $i.lo"
      done
    fi
    AC_SUBST([gltests_LIBOBJS], [$gltests_libobjs])
    AC_SUBST([gltests_LTLIBOBJS], [$gltests_ltlibobjs])
  ])
])

# Like AC_LIBOBJ, except that the module name goes
# into gl_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gl_LIBOBJ], [
  AS_LITERAL_IF([$1], [gl_LIBSOURCES([$1.c])])dnl
  gl_LIBOBJS="$gl_LIBOBJS $1.$ac_objext"
])

# Like AC_REPLACE_FUNCS, except that the module name goes
# into gl_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gl_REPLACE_FUNCS], [
  m4_foreach_w([gl_NAME], [$1], [AC_LIBSOURCES(gl_NAME[.c])])dnl
  AC_CHECK_FUNCS([$1], , [gl_LIBOBJ($ac_func)])
])

# Like AC_LIBSOURCES, except the directory where the source file is
# expected is derived from the gnulib-tool parameterization,
# and alloca is special cased (for the alloca-opt module).
# We could also entirely rely on EXTRA_lib..._SOURCES.
AC_DEFUN([gl_LIBSOURCES], [
  m4_foreach([_gl_NAME], [$1], [
    m4_if(_gl_NAME, [alloca.c], [], [
      m4_define([gl_LIBSOURCES_DIR], [lib])
      m4_append([gl_LIBSOURCES_LIST], _gl_NAME, [ ])
    ])
  ])
])

# Like AC_LIBOBJ, except that the module name goes
# into gltests_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gltests_LIBOBJ], [
  AS_LITERAL_IF([$1], [gltests_LIBSOURCES([$1.c])])dnl
  gltests_LIBOBJS="$gltests_LIBOBJS $1.$ac_objext"
])

# Like AC_REPLACE_FUNCS, except that the module name goes
# into gltests_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gltests_REPLACE_FUNCS], [
  m4_foreach_w([gl_NAME], [$1], [AC_LIBSOURCES(gl_NAME[.c])])dnl
  AC_CHECK_FUNCS([$1], , [gltests_LIBOBJ($ac_func)])
])

# Like AC_LIBSOURCES, except the directory where the source file is
# expected is derived from the gnulib-tool parameterization,
# and alloca is special cased (for the alloca-opt module).
# We could also entirely rely on EXTRA_lib..._SOURCES.
AC_DEFUN([gltests_LIBSOURCES], [
  m4_foreach([_gl_NAME], [$1], [
    m4_if(_gl_NAME, [alloca.c], [], [
      m4_define([gltests_LIBSOURCES_DIR], [tests])
      m4_append([gltests_LIBSOURCES_LIST], _gl_NAME, [ ])
    ])
  ])
])

# This macro records the list of files which have been installed by
# gnulib-tool and may be removed by future gnulib-tool invocations.
AC_DEFUN([gl_FILE_LIST], [
  build-aux/announce-gen
  build-aux/arg-nonnull.h
  build-aux/c++defs.h
  build-aux/config.rpath
  build-aux/gendocs.sh
  build-aux/git-version-gen
  build-aux/gitlog-to-changelog
  build-aux/gnu-web-doc-update
  build-aux/gnupload
  build-aux/unused-parameter.h
  build-aux/useless-if-before-free
  build-aux/vc-list-files
  build-aux/warn-on-use.h
  doc/gendocs_template
  lib/alignof.h
  lib/alloca.in.h
  lib/arpa_inet.in.h
  lib/asnprintf.c
  lib/byteswap.in.h
  lib/c-ctype.c
  lib/c-ctype.h
  lib/c-strcase.h
  lib/c-strcasecmp.c
  lib/c-strcaseeq.h
  lib/c-strncasecmp.c
  lib/canonicalize-lgpl.c
  lib/config.charset
  lib/duplocale.c
  lib/errno.in.h
  lib/float+.h
  lib/float.in.h
  lib/flock.c
  lib/full-read.c
  lib/full-read.h
  lib/full-write.c
  lib/full-write.h
  lib/gai_strerror.c
  lib/getaddrinfo.c
  lib/gettext.h
  lib/iconv.c
  lib/iconv.in.h
  lib/iconv_close.c
  lib/iconv_open-aix.gperf
  lib/iconv_open-hpux.gperf
  lib/iconv_open-irix.gperf
  lib/iconv_open-osf.gperf
  lib/iconv_open-solaris.gperf
  lib/iconv_open.c
  lib/iconveh.h
  lib/inet_ntop.c
  lib/inet_pton.c
  lib/isinf.c
  lib/isnan.c
  lib/isnand.c
  lib/isnanf.c
  lib/isnanl.c
  lib/libunistring.valgrind
  lib/localcharset.c
  lib/localcharset.h
  lib/locale.in.h
  lib/lstat.c
  lib/malloc.c
  lib/malloca.c
  lib/malloca.h
  lib/malloca.valgrind
  lib/math.in.h
  lib/mbrlen.c
  lib/mbrtowc.c
  lib/mbsinit.c
  lib/memchr.c
  lib/memchr.valgrind
  lib/netdb.in.h
  lib/netinet_in.in.h
  lib/pathmax.h
  lib/printf-args.c
  lib/printf-args.h
  lib/printf-parse.c
  lib/printf-parse.h
  lib/putenv.c
  lib/readlink.c
  lib/ref-add.sin
  lib/ref-del.sin
  lib/safe-read.c
  lib/safe-read.h
  lib/safe-write.c
  lib/safe-write.h
  lib/size_max.h
  lib/snprintf.c
  lib/stat-time.h
  lib/stat.c
  lib/stdarg.in.h
  lib/stdbool.in.h
  lib/stddef.in.h
  lib/stdint.in.h
  lib/stdio-write.c
  lib/stdio.in.h
  lib/stdlib.in.h
  lib/strcasecmp.c
  lib/streq.h
  lib/strftime.c
  lib/strftime.h
  lib/striconveh.c
  lib/striconveh.h
  lib/string.in.h
  lib/strings.in.h
  lib/strncasecmp.c
  lib/sys_file.in.h
  lib/sys_socket.in.h
  lib/sys_stat.in.h
  lib/time.in.h
  lib/time_r.c
  lib/unistd.in.h
  lib/unistr.in.h
  lib/unistr/u8-mbtouc-aux.c
  lib/unistr/u8-mbtouc-unsafe-aux.c
  lib/unistr/u8-mbtouc-unsafe.c
  lib/unistr/u8-mbtouc.c
  lib/unistr/u8-mbtoucr.c
  lib/unistr/u8-prev.c
  lib/unistr/u8-uctomb-aux.c
  lib/unistr/u8-uctomb.c
  lib/unitypes.in.h
  lib/vasnprintf.c
  lib/vasnprintf.h
  lib/verify.h
  lib/version-etc-fsf.c
  lib/version-etc.c
  lib/version-etc.h
  lib/vsnprintf.c
  lib/wchar.in.h
  lib/write.c
  lib/xsize.h
  m4/00gnulib.m4
  m4/absolute-header.m4
  m4/alloca.m4
  m4/arpa_inet_h.m4
  m4/asm-underscore.m4
  m4/autobuild.m4
  m4/byteswap.m4
  m4/canonicalize.m4
  m4/check-math-lib.m4
  m4/codeset.m4
  m4/dos.m4
  m4/double-slash-root.m4
  m4/duplocale.m4
  m4/eealloc.m4
  m4/environ.m4
  m4/errno_h.m4
  m4/exponentd.m4
  m4/exponentf.m4
  m4/exponentl.m4
  m4/extensions.m4
  m4/fcntl-o.m4
  m4/float_h.m4
  m4/flock.m4
  m4/fpieee.m4
  m4/func.m4
  m4/getaddrinfo.m4
  m4/glibc21.m4
  m4/gnulib-common.m4
  m4/hostent.m4
  m4/iconv.m4
  m4/iconv_h.m4
  m4/iconv_open.m4
  m4/include_next.m4
  m4/inet_ntop.m4
  m4/inet_pton.m4
  m4/inline.m4
  m4/intmax_t.m4
  m4/inttypes_h.m4
  m4/isinf.m4
  m4/isnan.m4
  m4/isnand.m4
  m4/isnanf.m4
  m4/isnanl.m4
  m4/ld-version-script.m4
  m4/lib-ld.m4
  m4/lib-link.m4
  m4/lib-prefix.m4
  m4/libunistring-base.m4
  m4/libunistring.m4
  m4/localcharset.m4
  m4/locale-fr.m4
  m4/locale-ja.m4
  m4/locale-zh.m4
  m4/locale_h.m4
  m4/longlong.m4
  m4/lstat.m4
  m4/malloc.m4
  m4/malloca.m4
  m4/math_h.m4
  m4/mbrlen.m4
  m4/mbrtowc.m4
  m4/mbsinit.m4
  m4/mbstate_t.m4
  m4/memchr.m4
  m4/mmap-anon.m4
  m4/multiarch.m4
  m4/netdb_h.m4
  m4/netinet_in_h.m4
  m4/pathmax.m4
  m4/printf.m4
  m4/putenv.m4
  m4/readlink.m4
  m4/safe-read.m4
  m4/safe-write.m4
  m4/servent.m4
  m4/size_max.m4
  m4/snprintf.m4
  m4/socklen.m4
  m4/sockpfaf.m4
  m4/ssize_t.m4
  m4/stat-time.m4
  m4/stat.m4
  m4/stdarg.m4
  m4/stdbool.m4
  m4/stddef_h.m4
  m4/stdint.m4
  m4/stdint_h.m4
  m4/stdio_h.m4
  m4/stdlib_h.m4
  m4/strcase.m4
  m4/strftime.m4
  m4/string_h.m4
  m4/strings_h.m4
  m4/sys_file_h.m4
  m4/sys_socket_h.m4
  m4/sys_stat_h.m4
  m4/time_h.m4
  m4/time_r.m4
  m4/tm_gmtoff.m4
  m4/unistd_h.m4
  m4/vasnprintf.m4
  m4/version-etc.m4
  m4/visibility.m4
  m4/vsnprintf.m4
  m4/warn-on-use.m4
  m4/warnings.m4
  m4/wchar_h.m4
  m4/wchar_t.m4
  m4/wint_t.m4
  m4/write.m4
  m4/xsize.m4
  top/GNUmakefile
  top/maint.mk
])
