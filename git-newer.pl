#!/usr/bin/perl
#
# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
#
# Suppose you cloned a git repo which is updated every now and then,
# and you want to be informed about new commits so you can run 'git
# pull' and/or do whatever else is needed to keep up to date.  You can
# somehow manually check every now and then --- or use this script to
# do the check for you.
#


use strict;
use warnings;
use autodie;

use MIME::Lite;
use Getopt::Long;


my $repodir = '.';

my @to;
push @to, (getpwuid($<))[0];
my $from = $to[0];

my $domail = 0;
my $dohelp = 0;
my $dryrun = 0;

GetOptions ('m|mail' => \$domail,
	    'n|dryrun' => \$dryrun,
	    'd|repodir=s' => \$repodir,
	    't|to=s' => \@to,
	    'f|from=s' => \$from,
	    'h|help' => \$dohelp);


if ($dohelp) {
  print "options:\n";
  print "-d, -repodir [path] : specify path to directory holding the git repo, (default: current directory)\n";
  print "-f, -from [mailaddr]: email address of sender of email, (default: first address from '-to' option)\n";
  print "-h, -help           : show this help text\n";
  print "-m, -mail           : send mail (default: do not send)\n";
  print "-n, -dryrun         : do nothing but print which options would be used, (default: don't run dry)\n";
  print "-t, -to [mailaddr]  : email address of recipient of email, (default: user running this script)\n";
  print "\tOptions may be specified in any order.\n";
  print "\tYou can specify multiple recipients as a comma seperated list.\n";
  print "\tIntentionally, email is not sent when there's nothing new.\n";
  exit -1 unless $dryrun;
}


if (@to > 1) {
  shift @to;
  @to = split(/,/, join(',', @to));
  $from = $to[0];
}


if ($dryrun) {
  print "\n" if $dohelp;
  print "DRYRUN\nrepodir: $repodir\nfrom: $from\nhelp: " . ($dohelp ? 'yes' : 'no');
  print "\nmail: " . ($domail ? 'yes' : 'no') . "\ndryrun: " . ($dryrun ? 'yes' : 'no') . "\n";
  foreach (@to) {
    print "to: $_\n";
  }
  exit -2;
}


chdir($repodir);
chomp(my $repo_local = `git log -1 --date=relative --format=%at`);
chomp(my $repo_remote = `git log -1 --date=relative --format=%at origin`);

if ($repo_local < $repo_remote) {
  my $msg = "New commits for $repodir\n\tremote: " . localtime($repo_remote) . ", local: " . localtime($repo_local) . "\n";
  if ($domail) {
    foreach (@to) {
      my $email = MIME::Lite->new(
				  From     => $from,
				  To       => $_,
				  Subject  => 'git-newer: a commit has been made recently',
				  Data     => $msg
				 );
      $email->send;
    }
  } else {
    print $msg;
  }
} else {
  print "$repodir: nothing new\n" unless $domail;
}

exit 0;
