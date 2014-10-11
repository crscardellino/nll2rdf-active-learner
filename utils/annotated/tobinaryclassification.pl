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
use List::MoreUtils qw/ firstidx /;

my $attrfile = shift @ARGV;
my $outdir = shift @ARGV;

my @attributes = `grep "^\@ATTRIBUTE" $attrfile`;

chomp @attributes;

my @classes = split ",", (split /\s+/, pop @attributes)[2];

$classes[0] =~ s/{//;
$classes[scalar(@classes)-1] =~ s/}//;

@classes = grep { lc($_) ne "no-class" } @classes;

my @files = ();

foreach my $class(@classes) {
  open(my $fh, ">", "$outdir/$class.arff") or die $!;

  push @files, $fh;

  print $fh "\@RELATION $class\n\n";
  print $fh join "\n", @attributes;
  print $fh "\n\@ATTRIBUTE class-nll2rdf-$class {0,1}\n\n\@DATA\n";
}

my @instances = `egrep -v "^[@]|^\\s*\$" $attrfile`;
chomp @instances;

foreach my $instance(@instances) {
  my @values = split ",", $instance;
  my $instance_class = pop @values;
  
  foreach my $class(@classes) {
    my $idx = firstidx { $_ eq $class } @classes;
    my $fh = $files[$idx];

    print $fh join ",", @values;
    
    if ($class eq $instance_class) {
      print $fh ",1\n";
    } else {
      print $fh ",0\n";
    }
  }
}

foreach my $fh(@files) {
  close $fh;
}