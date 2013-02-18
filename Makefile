# Makefile for logcheck package.
# logtail.c : Log file tailing program
# 
# Send problems/code hacks to crowland@psionic.com or crowland@vni.net
# Thanks to rbulling@obscure.org for cleaning this Makefile up..
#

# Generic compiler
 CC = cc
# GNU..
# CC = gcc 

# Normal systems flags
CFLAGS = -O
# Braindead HPUX compiler flags
#CFLAGS = -O -Aa

# If you change these be sure you edit logcheck.sh to reflect
# the new paths!!

# This is where keyword files go.
INSTALLDIR = /etc/logcheck

# This is where logtail will go
INSTALLDIR_BIN = /usr/bin

# Some people want the logcheck.sh in /usr/local/bin. Uncomment this
# if you want this. /usr/local/etc was kept for compatibility reasons.
INSTALLDIR_SH = /usr/bin
#INSTALLDIR_SH = /etc/logcheck

# The scratch directory for logcheck files.
TMPDIR = /tmp

# Debug mode for logtail
# CFLAGS = -g -DDEBUG

all:
		@echo "Usage: make <systype>"
		@echo "<systype> is one of: "
		@echo "  linux, bsdos, freebsd, sun, generic, hpux, digital"
		@echo "" 
		@echo "NOTE: This will make and install the package in these" 
		@echo "      directories:" 
		@echo "        logcheck configuration files : $(INSTALLDIR)" 
		@echo "        logcheck.sh shell script     : $(INSTALLDIR_SH)" 
		@echo "        logtail program              : $(INSTALLDIR_BIN)" 
		@echo "" 
		@echo "Edit the makefile if you wish to change these paths." 
		@echo "Any existing files will be overwritten."

clean:		
		/bin/rm ./src/logtail ./src/logtail.o || true

uninstall:	
		/bin/rm $(INSTALLDIR_SH)/logcheck.sh
		/bin/rm $(INSTALLDIR)/logcheck.ignore
		/bin/rm $(INSTALLDIR)/logcheck.hacking
		/bin/rm $(INSTALLDIR)/logcheck.violations
		/bin/rm $(INSTALLDIR)/logcheck.violations.ignore
		/bin/rm $(INSTALLDIR_BIN)/logtail

install:	
		@echo "Making $(SYSTYPE)"
		$(CC) $(CFLAGS) -c -o ./src/logtail.o ./src/logtail.c
		$(CC) $(CFLAGS) -o ./src/logtail ./src/logtail.o
		@echo "Creating temp directory $(TMPDIR)"
		@if [ ! -d $(DESTDIR)$(TMPDIR) ]; then /bin/mkdir -p $(DESTDIR)$(TMPDIR); fi
		@echo "Setting temp directory permissions"
		chmod 700 $(DESTDIR)$(TMPDIR)
		@echo "Copying files"
		@if [ ! -d $(DESTDIR)$(INSTALLDIR_BIN) ]; then /bin/mkdir -p $(DESTDIR)$(INSTALLDIR_BIN); fi
		@if [ ! -d $(DESTDIR)$(INSTALLDIR) ]; then /bin/mkdir -p $(DESTDIR)$(INSTALLDIR); fi
		@if [ ! -d $(DESTDIR)$(INSTALLDIR_SH) ]; then /bin/mkdir -p $(DESTDIR)$(INSTALLDIR_SH); fi
#		cp ./systems/$(SYSTYPE)/logcheck.hacking $(DESTDIR)$(INSTALLDIR)
#		cp ./systems/$(SYSTYPE)/logcheck.violations $(DESTDIR)$(INSTALLDIR)
#		cp ./systems/$(SYSTYPE)/logcheck.violations.ignore $(DESTDIR)$(INSTALLDIR)
#		cp ./systems/$(SYSTYPE)/logcheck.ignore $(DESTDIR)$(INSTALLDIR)
		cp ./systems/$(SYSTYPE)/logcheck.sh $(DESTDIR)$(INSTALLDIR_SH)
		cp ./src/logtail $(DESTDIR)$(INSTALLDIR_BIN)
		@echo "Setting permissions"
		chmod 700 $(DESTDIR)$(INSTALLDIR_SH)/logcheck.sh
		chmod 700 $(DESTDIR)$(INSTALLDIR_BIN)/logtail
#		chmod 600 $(DESTDIR)$(INSTALLDIR)/logcheck.violations.ignore
#		chmod 600 $(DESTDIR)$(INSTALLDIR)/logcheck.violations
#		chmod 600 $(DESTDIR)$(INSTALLDIR)/logcheck.hacking
#		chmod 600 $(DESTDIR)$(INSTALLDIR)/logcheck.ignore
		@echo "Done. Don't forget to set your crontab."		

generic:		
		make install SYSTYPE=generic

linux:		
		make install SYSTYPE=linux

bsdos:		
		make install SYSTYPE=bsdos

freebsd:	
		make install SYSTYPE=freebsd

sun:		
		make install SYSTYPE=sun

hpux:		
		make install SYSTYPE=hpux

digital:		
		make install SYSTYPE=digital


distclean: clean
