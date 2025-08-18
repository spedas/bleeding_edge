#
# Makefile for the makemastfile directory
#
# VERSION: @(#)Makefile	1.1 11/05/96 UCB SSL
#

# *********************************************************************
#  List all target files that need to be installed into the standard places

BIN = makemastfile

# *********************************************************************
#  Include Makefile.default to set up standard targets.  This MUST be
#  taken from the local workspace, so use a relative path.  The macro
#  below will climb the directory chain until it finds a directory named
#  'Codemgr_wsdata', which marks the root of a Code Manager workspace.
#  The Makefile.default file is in 'src' in the workspace root directory.
#  Either use this macro or use an explicit relative path.

MAKEDEFAULT:sh = (while [ ! -d Codemgr_wsdata -a "`pwd`" != "/" ] ; do \
	echo '../\c' ; cd .. ; \
	done; \
	echo src/Makefile.default )

include $(MAKEDEFAULT)

# *********************************************************************
#  
#  Standard targets will also propagate down to any subdirectories, in
#  ASCII order (except for SCCS).  If your subdirectories need a special
#  order (or some of them shouldn't be processed) then redefine the
#  DIRS macro *after* including Makefile.default.
#
#DIRS =

# *********************************************************************
#  Append any needed flags to the variables
#      CFLAGS, CCFLAGS, FFLAGS, CPPFLAGS, LDFLAGS
#

# *********************************************************************
#  Define targets to build everything in BIN and LIB from object files.
#  Header files and man pages that need special processing to build
#  should also be defined here.
#
#  foo:  foo.o  fap.o
#	$(LINK.c)  -o $@  foo.o fap.o  -lfoolib

makemastfile: makemastfile.o
	$(LINK.c) -o $@ makemastfile.o -lcdf -lm -lsunmath

