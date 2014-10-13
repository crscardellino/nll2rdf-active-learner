#!/usr/bin/env perl

# NLL2RDF Active Learner
# Copyright (C) 2014 Cristian A. Cardellino
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use List::Util qw/ shuffle /;

my $outfile = shift @ARGV;
my $instances = shift @ARGV;
my $queries_count = shift @ARGV;

print STDERR "Making random queries (passive learning)\n";

open(my $fh, "> $outfile") or die "$!";
open(my $dh, $instances) or die "$!";
close $dh;

$queries_count = 5 unless defined $queries_count;

my @instancesid = `awk -F, '{ print \$1 }' $instances`;
chomp @instancesid;

my @queries = (shuffle(@instancesid))[0..$queries_count-1];

print STDERR "Writing queries\n";

foreach my $query(@queries) {
  print $fh "$query,0.0\n";
}

close $fh;