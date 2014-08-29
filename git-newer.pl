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


unless(@ARGV == 3) {
  print "usage: git-newer.pl [path-to-repo] [email-recipient] [email-from]\n";
  exit 1;
}

chdir($ARGV[0]);

my $repo_local=`git log -1 --date=relative --format=%at`;
my $repo_remote=`git log -1 --date=relative --format=%at origin`;

chomp $repo_local;
chomp $repo_remote;

if ($repo_local < $repo_remote) {
  my $email = MIME::Lite->new(
			      From     => $ARGV[2],
			      To       => $ARGV[1],
			      Subject  => 'get-newer: a commit has been made recently',
			      Data     => "New commits for $ARGV[0]\n\tremote: ". localtime($repo_remote) . ", local: " . localtime($repo_local) . "\n"
			     );
  $email->send;
}

exit 0;
