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
use String::Util qw(trim);

my $instancefile = shift @ARGV;
my $instancedir = shift @ARGV;
my $outputdir = shift @ARGV;

my @readable_classes = ("Permission to commercialize", "Permission to derive", "Permission to distribute",
  "Permission to read", "Permission to reproduce", "Permission to sell",
  "Prohibition to commercialize", "Prohibition to derive", "Prohibition to distribute", 
  "Requirement to attach policy", "Requirement to attach source", "Requirement to attribute",
  "Requirement to share alike");

my @classes = ("PER-COMMERCIALIZE", "PER-DERIVE", "PER-DISTRIBUTE", "PER-READ",
  "PER-REPRODUCE", "PER-SELL", "PRO-COMMERCIALIZE", "PRO-DERIVE",
  "PRO-DISTRIBUTE", "REQ-ATTACHPOLICY", "REQ-ATTACHSOURCE", "REQ-ATTRIBUTE",
  "REQ-SHAREALIKE");

open(my $fh, "<", $instancefile) or die "Couldn't open instance file: $!";
close $fh;
opendir(my $id, $instancedir) or die "Must provide a valid instances directory";
closedir $id;
opendir($id, $outputdir) or die "Must provide a valid output directory";
closedir $id;

my @queries = `cat $instacefile | tr -d "'" | cut -d, -f1`;

my $i = 1;

foreach my $query(@queries) {
  print "\nQUERY $i:\n\n";
  $i++;
  system "cat $instancedir/$query.txt";
  print "\n";

  while(1) {
    print "How to classify this query? (write all possible candidates separated by comma)";

    # for(my $j; $j < scalar @readable_classes; $j++) {
    #
    # }
  }
}