#!/bin/sh
#
#	logcheck.sh: Log file checker
#	Written by Craig Rowland <crowland@psionic.com>
#
#	This file needs the program logtail.c to run
#
#	This script checks logs for unusual activity and blatant
#	attempts at hacking. All items are mailed to administrators
# 	for review. This script and the logtail.c program are based upon 
#       the frequentcheck.sh script idea from the Gauntlet(tm) Firewall
#	(c)Trusted Information Systems Inc. The original authors are 
#	Marcus J. Ranum and Fred Avolio.
#
#	Default search files are tuned towards the TIS Firewall toolkit
# 	the TCP Wrapper program. Custom daemons and reporting facilites
#	can be accounted for as well...read the rest of the script for
#	details.
#
#	Version Information
#
#	1.0 	9/29/96  -- Initial Release
#	1.01	11/01/96 -- Added working /tmp directory for symlink protection
#			    (Thanks Richard Bullington (rbulling@obscure.org)
#	1.1	1/03/97	 -- Made this script more portable for Sun's.
#		1/03/97	 -- Made this script work on HPUX
#               5/14/97  -- Added Digital OSF/1 logging support. Big thanks
#                           to Jay Vassos-Libove <libove@compgen.com> for
#                           his changes.
 

# CONFIGURATION SECTION

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/ucb:/usr/local/bin

# Logcheck is pre-configured to work on most BSD like systems, however it
# is a rather dumb program and may need some help to work on other
# systems. Please check the following command paths to ensure they are 
# correct.

# Person to send log activity to.
SYSADMIN=root

# Full path to logtail program.
# This program is required to run this script and comes with the package.

LOGTAIL=/usr/local/bin/logtail

# Full path to SECURED (non public writable) /tmp directory.
# Prevents Race condition and potential symlink problems. I highly
# recommend you do NOT make this a publically writable/readable directory.
# You would also be well advised to make sure all your system/cron scripts
# use this directory for their "scratch" area. 

TMPDIR=/usr/local/etc/tmp

# The 'grep' command. This command MUST support the
# '-i' '-v' and '-f' flags!! The GNU grep does this by default (that's
# good GNUs for you Linux/FreeBSD/BSDI people :) ). The Sun grep I'm told
# does not support these switches, but the 'egrep' command does (Thanks
# Jason <jason@mastaler.com> ). Since grep and egrep are usually the GNU 
# variety on most systems (well most Linux, FreeBSD, BSDI, etc) and just
# hard links to each other we'll just specify egrep here. Change this if 
# you get errors.

# Linux, FreeBSD, BSDI, Sun, HPUX, etc.
GREP=egrep

# The 'mail' command. Most systems this should be OK to leave as is.
# If your default mail command does not support the '-s' (subject) command
# line switch you will need to change this command one one that does.
# The only system I've seen this to be a problem on are HPUX boxes. 
# Naturally, the HPUX is so superior to the rest of UNIX OS's that they
# feel they need to do everything differently to remind the rest that
# they are the best ;).

# Linux, FreeBSD, BSDI, Sun, etc.
MAIL=mail
# HPUX 10.x and others(?)
#MAIL=mailx
# Digital OSF/1, Irix
#MAIL=Mail

# File of known active hacking attack messages to look for.
# Only put messages in here if you are sure they won't cause
# false alarms. This is a rather generic way of checking for 
# malicious activity and can be inaccurate unless you know
# what past hacking activity looks like. The default is to
# look for generic ISS probes (who the hell else looks for 
# "WIZ" besides ISS?), and obvious sendmail attacks/probes.

HACKING_FILE=/usr/local/etc/logcheck.hacking

# File of security violation patterns to specifically look for.
# This file should contain keywords of information administrators should
# probably be aware of. May or may not cause false alarms sometimes.
# Generally, anything that is "negative" is put in this file. It may miss
# some items, but these will be caught by the next check. Move suspicious
# items into this file to have them reported regularly.

VIOLATIONS_FILE=/usr/local/etc/logcheck.violations

# File that contains more complete sentences that have keywords from
# the violations file. These keywords are normal and are not cause for 
# concern but could cause a false alarm. An example of this is the word 
# "refused" which is often reported by sendmail if a message cannot be 
# delivered or can be a more serious security violation of a system 
# attaching to illegal ports. Obviously you would put the sendmail 
# warning as part of this file. Use your judgement before putting words 
# in here or you can miss really important events. The default is to leave
# this file with only a couple entries. DO NOT LEAVE THE FILE EMPTY. Some 
# grep's will assume that an EMPTY file means a wildcard and will ignore 
# everything! The basic configuration allows for the more frequent sendmail
# error.
#
# Again, be careful what you put in here and DO NOT LEAVE IT EMPTY!

VIOLATIONS_IGNORE_FILE=/usr/local/etc/logcheck.violations.ignore

# This is the name of a file that contains patterns that we should
# ignore if found in a log file. If you have repeated false alarms
# or want specific errors ignored, you should put them in here.
# Once again, be as specific as possible, and go easy on the wildcards

IGNORE_FILE=/usr/local/etc/logcheck.ignore

# The files are reported in the order of hacking, security 
# violations, and unusual system events. Notice that this
# script uses the principle of "That which is not explicitely
# ignored is reported" in that the script will report all items
# that you do not tell it to ignore specificially. Be careful
# how you use wildcards in the logcheck.ignore file or you 
# may miss important entries.

# Make sure we really did clean up from the last run.
# Also this ensures that people aren't trying to trick us into
# overwriting files that we aren't supposed to. This is still a race
# condition, but if you are in a temp directory that does not have
# generic luser access it is not a problem. Do not allow this program
# to write to a generic /tmp directory where others can watch and/or
# create files!!

# Shouldn't need to touch these...
HOSTNAME=`hostname`
DATE=`date +%m/%d/%y:%H.%M`

umask 077
rm -f $TMPDIR/check.$$ $TMPDIR/checkoutput.$$ $TMPDIR/checkreport.$$
if [ -f $TMPDIR/check.$$ -o -f $TMPDIR/checkoutput.$$ -o -f $TMPDIR/checkreport.$$ ]; then
	echo "Log files exist in $TMPDIR directory that cannot be removed. This 
may be an attempt to spoof the log checker." \
	| $MAIL -s "$HOSTNAME $DATE ACTIVE SYSTEM ATTACK!" $SYSADMIN
	exit 1
fi

# LOG FILE CONFIGURATION SECTION
# You might have to customize these entries depending on how 
# you have syslogd configured. Be sure you check all relevant logs.
# The logtail utility is required to read and mark log files.
# See INSTALL for more information. Again, using one log file
# is preferred and is easier to manage. Be sure you know what the
# > and >> operators do before you change them. LOG FILES SHOULD
# ALWAYS BE chmod 600 OWNER root!!

# Generic and Linux Slackware 3.x
#$LOGTAIL /var/log/messages > $TMPDIR/check.$$

# Linux Red Hat Version 3.x, 4.x
$LOGTAIL /var/log/messages > $TMPDIR/check.$$
$LOGTAIL /var/log/secure >> $TMPDIR/check.$$
$LOGTAIL /var/log/maillog >> $TMPDIR/check.$$

# FreeBSD 2.x
#$LOGTAIL /var/log/messages > $TMPDIR/check.$$
#$LOGTAIL /var/log/maillog >> $TMPDIR/check.$$

# BSDI 2.x
#$LOGTAIL /var/log/messages > $TMPDIR/check.$$
#$LOGTAIL /var/log/secure >> $TMPDIR/check.$$
#$LOGTAIL /var/log/maillog >> $TMPDIR/check.$$
#$LOGTAIL /var/log/ftp.log >> $TMPDIR/check.$$
# Un-comment out the line below if you are using BSDI 2.1
#$LOGTAIL /var/log/daemon.log >> $TMPDIR/check.$$

# SunOS, Sun Solaris 2.5
#$LOGTAIL /var/log/syslog > $TMPDIR/check.$$
#$LOGTAIL /var/adm/messages >> $TMPDIR/check.$$

# HPUX 10.x and others(?)
#$LOGTAIL /var/adm/syslog/syslog.log > $TMPDIR/check.$$

# Digital OSF/1
# OSF/1 - uses rotating log directory with date & time in name
#        LOGDIRS=`find /var/adm/syslog.dated/* -type d -prune -print`
#        LOGDIR=`ls -dtr1 $LOGDIRS | tail -1` 
#        if [ ! -d "$LOGDIR" ]
#        then
#          echo "Can't identify current log directory." >> $TMPDIR/checkrepo$
#        else
#                $LOGTAIL  $LOGDIR/auth.log >> $TMPDIR/check.$$
#                $LOGTAIL  $LOGDIR/daemon.log >> $TMPDIR/check.$$
#                $LOGTAIL  $LOGDIR/kern.log >> $TMPDIR/check.$$
#                $LOGTAIL  $LOGDIR/lpr.log >> $TMPDIR/check.$$
#                $LOGTAIL  $LOGDIR/mail.log >> $TMPDIR/check.$$
#                $LOGTAIL  $LOGDIR/syslog.log >> $TMPDIR/check.$$
#                $LOGTAIL  $LOGDIR/user.log >> $TMPDIR/check.$$
#        fi
#


# END CONFIGURATION SECTION. YOU SHOULDN'T HAVE TO EDIT ANYTHING
# BELOW THIS LINE.

# Set the flag variables
FOUND=0
ATTACK=0

# See if the tmp file exists and actually has data to check, 
# if it doesn't we should erase it and exit as our job is done.
 
if [ ! -s $TMPDIR/check.$$ ]; then
	rm -f $TMPDIR/check.$$	
	exit 0
fi

# Perform Searches

# Check for blatant hacking attempts
if [ -f "$HACKING_FILE" ]; then
	if $GREP -i -f $HACKING_FILE $TMPDIR/check.$$ > $TMPDIR/checkoutput.$$; then
		echo >> $TMPDIR/checkreport.$$
		echo "Active System Attack Alerts" >> $TMPDIR/checkreport.$$
		echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=" >> $TMPDIR/checkreport.$$
		cat $TMPDIR/checkoutput.$$ >> $TMPDIR/checkreport.$$
		FOUND=1
		ATTACK=1
	fi
fi

# Check for security violations
if [ -f "$VIOLATIONS_FILE" ]; then
	if $GREP -i -f $VIOLATIONS_FILE $TMPDIR/check.$$ |
	   $GREP -v -f $VIOLATIONS_IGNORE_FILE > $TMPDIR/checkoutput.$$; then
		echo >> $TMPDIR/checkreport.$$
		echo "Security Violations" >> $TMPDIR/checkreport.$$
		echo "=-=-=-=-=-=-=-=-=-=" >> $TMPDIR/checkreport.$$
		cat $TMPDIR/checkoutput.$$ >> $TMPDIR/checkreport.$$
		FOUND=1
	fi
fi

# Do reverse grep on patterns we want to ignore
if [ -f "$IGNORE_FILE" ]; then
	if $GREP -v -f $IGNORE_FILE $TMPDIR/check.$$ > $TMPDIR/checkoutput.$$; then
		echo >> $TMPDIR/checkreport.$$
		echo "Unusual System Events" >> $TMPDIR/checkreport.$$
		echo "=-=-=-=-=-=-=-=-=-=-=" >> $TMPDIR/checkreport.$$
		cat $TMPDIR/checkoutput.$$ >> $TMPDIR/checkreport.$$
		FOUND=1
	fi
fi

# If there are results, mail them to sysadmin

if [ "$ATTACK" -eq 1 ]; then
	cat $TMPDIR/checkreport.$$ | $MAIL -s "$HOSTNAME $DATE ACTIVE SYSTEM ATTACK!" $SYSADMIN
elif [ "$FOUND" -eq 1 ]; then
	cat $TMPDIR/checkreport.$$ | $MAIL -s "$HOSTNAME $DATE system check" $SYSADMIN 
fi

# Clean Up
rm -f $TMPDIR/check.$$ $TMPDIR/checkoutput.$$ $TMPDIR/checkreport.$$
