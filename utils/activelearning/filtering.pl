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

my $featuresdir = shift @ARGV;

print STDERR "Analyzing features\n";

opendir(my $dh, $featuresdir) or die $!;

while(readdir $dh) {
  next unless $_ =~ m/^features\.([A-Z\-]+)\.txt$/;
  my $class = $1;

  my @classfeatures = `cat $featuresdir/features.$class.txt`;
  chomp @classfeatures;
  my %classfeatures = map { $_ => 1 } @classfeatures;
  my @nonclassfeatures = `find $featuresdir -name "features.*.txt" -not -name "features.$class.txt" -print0 | xargs -0 cat`;
  chomp @nonclassfeatures;
  my %nonclassfeatures = map { $_ => 1 } (grep { !exists $classfeatures{$_} } @nonclassfeatures);

  open(my $fh, ">", "$featuresdir/$class.filter") or die $!;

  print $fh join(",", keys %nonclassfeatures);

  close $fh;
}

closedir $dh;