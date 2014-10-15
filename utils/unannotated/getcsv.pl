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
use List::Util qw/ sum shuffle /;
use POSIX qw/ floor /;
use String::Util qw/ trim /;

sub get_progress {
  my $totalexamples = shift @_;
  my $examplenumber = shift @_;
  my $percentage = $examplenumber * 100 / $totalexamples;

  my $totalbars = "=" x floor $percentage;
  my $totalempties = " " x (100 - floor $percentage);
  
  return "[". $totalbars . $totalempties . "]" . sprintf("%.2f%%", $percentage);
}

my $datafile = shift @ARGV;
my $dirpath = shift @ARGV;
my $oldarff = shift @ARGV;
my $filter = shift @ARGV;

$filter = 10 unless defined $filter;

print STDERR "Getting data from unannotated instances\n";

opendir(my $dh, $dirpath) or die "$dirpath is not a valid directory";
closedir $dh;

open(my $fh , "<", $datafile) or die "Couldn't open file $datafile: $!";

my @attributes = `grep "^\@ATTRIBUTE" $oldarff | awk '{ print \$2 }'`;
chomp @attributes;
pop @attributes; # Remove the class attribute
my %totalattrs = map { $_ => 0 } @attributes;

my $totalexamples = trim(`wc -l $datafile | awk '{ print \$1 }'`);
my $currentexamples = 0;

open(my $ah, ">", "$dirpath/data/unannotated.nll2rdf.csv") or die "Couldn't create file $dirpath/data/unannotated.nll2rdf.csv: $!";

while(<$fh>) {
  chomp;

  my @line = split ",", $_;

  pop @line; # Remove the instance identifier

  foreach my $attr (@line) {
    $totalattrs{$attr} += 1 if exists $totalattrs{$attr};
  }
}

close $fh;

# Filter the attributes (we ignore the attributes less than the filter)
my %filtered_attributes = map { $_ => 1 } (grep { $totalattrs{$_} > $filter } @attributes);

open($fh , "<", $datafile) or die "Couldn't open file $datafile: $!";

while(<$fh>) {
  $currentexamples += 1;

  print STDERR "\r" . get_progress $totalexamples, $currentexamples;

  chomp;
  
  my %setofattrs = map { $_ => 0 } @attributes;

  my @line = split ",", $_;
  my $instanceid = pop @line;

  foreach my $attr (@line) {
    $setofattrs{$attr} += 1 if exists $filtered_attributes{$attr};
  }

  if(sum(values %setofattrs) > $filter) {
    print $ah "'$instanceid'," . join(",", map { $setofattrs{$_} } sort keys %setofattrs) . ",0\n";
  }
}

print STDERR "\nFinnished getting instances of unannotated corpus\n";