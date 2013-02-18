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
INSTALLDIR = /usr/local/etc

# This is where logtail will go
INSTALLDIR_BIN = /usr/local/bin

# Some people want the logcheck.sh in /usr/local/bin. Uncomment this
# if you want this. /usr/local/etc was kept for compatibility reasons.
#INSTALLDIR_SH = /usr/local/bin
INSTALLDIR_SH = /usr/local/etc

# The scratch directory for logcheck files.
TMPDIR = /usr/local/etc/tmp

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
		/bin/rm ./src/logtail ./src/logtail.o

uninstall:	
		/bin/rm $(INSTALLDIR_SH)/logcheck.sh
		/bin/rm $(INSTALLDIR)/logcheck.ignore
		/bin/rm $(INSTALLDIR)/logcheck.hacking
		/bin/rm $(INSTALLDIR)/logcheck.violations
		/bin/rm $(INSTALLDIR)/logcheck.violations.ignore
		/bin/rm $(INSTALLDIR_BIN)/logtail

install:	
		@echo "Making $(SYSTYPE)"
		$(CC) $(CFLAGS) -o ./src/logtail ./src/logtail.c
		@echo "Creating temp directory $(TMPDIR)"
		@if [ ! -d $(TMPDIR) ]; then /bin/mkdir $(TMPDIR); fi
		@echo "Setting temp directory permissions"
		chmod 700 $(TMPDIR)
		@echo "Copying files"
		cp ./systems/$(SYSTYPE)/logcheck.hacking $(INSTALLDIR)
		cp ./systems/$(SYSTYPE)/logcheck.violations $(INSTALLDIR)
		cp ./systems/$(SYSTYPE)/logcheck.violations.ignore $(INSTALLDIR)
		cp ./systems/$(SYSTYPE)/logcheck.ignore $(INSTALLDIR)
		cp ./systems/$(SYSTYPE)/logcheck.sh $(INSTALLDIR_SH)
		cp ./src/logtail $(INSTALLDIR_BIN)
		@echo "Setting permissions"
		chmod 700 $(INSTALLDIR_SH)/logcheck.sh
		chmod 700 $(INSTALLDIR_BIN)/logtail
		chmod 600 $(INSTALLDIR)/logcheck.violations.ignore
		chmod 600 $(INSTALLDIR)/logcheck.violations
		chmod 600 $(INSTALLDIR)/logcheck.hacking
		chmod 600 $(INSTALLDIR)/logcheck.ignore
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

