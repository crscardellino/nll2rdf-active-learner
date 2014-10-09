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

my $infile = shift @ARGV;
my $filter = shift @ARGV;

$filter = 0 unless defined $filter;

open(my $fh, "<", $infile) || die "File $infile didn't open: $!";

print "\@RELATION nll2rdf\n\n";

my $lineofwords = <STDIN>; 
chomp $lineofwords;

my @words = split ",", $lineofwords;

my %classes = ();

my %totalwords = map { $_ => 0 } @words;

while(<$fh>) {
  chomp;

  my @line = split ",", $_;

  my $class = pop @line;

  foreach my $word (@line) {
    $totalwords{$word} += 1;
  }

  $classes{$class} = 1;
}

@words = grep { $totalwords{$_} > $filter } @words;

foreach my $word (@words) {
  print "\@ATTRIBUTE $word NUMERIC\n";
}

print "\@ATTRIBUTE class-nll2rdf {" . join(",", sort (keys %classes)) . "}\n\n\@DATA\n";

open($fh, "<", $infile) || die "File $infile didn't open: $!";

my $filecount = 1;

while(<$fh>) {
  chomp;
  
  my %setofattrs = map { $_ => 0 } @words;

  my @line = split ",", $_;
  my $class = pop @line;

  $filecount += 1;

  foreach my $word (@line) {
    $setofattrs{$word} += 1 if exists $setofattrs{$word};
  }

  foreach my $attr (sort keys %setofattrs) {
    print $setofattrs{$attr} . ",";
  }
  
  print "$class\n";
}