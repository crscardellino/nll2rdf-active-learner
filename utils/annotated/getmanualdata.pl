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

my $datafile = shift @ARGV;
my $instancesdir = shift @ARGV;
my $featuresdir = shift @ARGV;

open(my $fh, $datafile) or die $!;
close $fh;
opendir(my $dh, $featuresdir) or die $!;
closedir $dh;
opendir($dh, $instancesdir) or die $!;

print STDERR "Adding manually annotated data to the corpus\n";

while(readdir $dh) {
  next unless $_ =~ m/^([^A-Z]+)\.([A-Z\-]+)\.txt$/;
  my $instance = $1;
  my $class = $2;

  my $data = `grep ",$instance\$" $datafile`;
  chomp $data;
  my @data = split ",", $data;
  pop @data;

  # Preprocess of the instance to make it monolabel
  my $featuresfilter = `cat $featuresdir/$class.filter`;
  chomp $featuresfilter;
  my %featuresfilter = map { $_ => 1 } (split ",", $featuresfilter);

  my @processeddata = grep { !exists $featuresfilter{$_} } @data;

  print join(",", @processeddata) . ",$class\n" if scalar(@processeddata) > 0;
}

closedir $dh;