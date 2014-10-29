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

use autodie qw/ open close /;
use strict;
use warnings;

my $iteration = shift @ARGV;
die "The iteration number is incorrect" unless defined $iteration;

my $out = shift @ARGV;
die "The out option must but 'mixed' or 'annotated'" unless defined $iteration and ($itereation eq "mixed" or $iteration eq "annotated");

my $filter = shift @ARGV;
$filter = 0 unless defined $filter;

print STDERR "Creating data file with initial corpus and oracle annotation";

my @annotated = `cat /tmp/nll2rdf.tmp/annotated.data`;
chomp @annotated;

open(my $oh, ">", "/tmp/nll2rdf.tmp/$out.data");

# We first move the content of the annotated file to the outfile
foreach $line(@annotated) {
  print $oh $line;
}

my @instances = "find /tmp/nll2rdf.tmp/instances/iteration$iteration/tagged -type f";
chomp @instances;

foreach my $instance(@instances) {
  $instance =~ m/^([^A-Z]+)\.([A-Z\-]+)\.txt$/;
  my $instance_name = $1;
  my $class_name = $2;

  my $data = `grep ",$instance_name\$" /tmp/nll2rdf.tmp/unannotated.data`;
  chomp $data;
  my @data = split ",", $data;
  pop @data;

  # Preprocess of the instance to make it monolabel
  my @featuresfilter = `cat /tmp/nll2rdf.tmp/features/filter.$class.$iteration.txt`;
  chomp @featuresfilter;
  my %featuresfilter = map { $_ => 1 } @featuresfilter;

  my @processeddata = grep { !exists $featuresfilter{$_} } @data;

  print $oh join(",", @processeddata) . ",$class_name\n" if scalar(@processeddata) > 0;
}

close $oh;

# Collect the features of the data file

print STDERR "Creating arff file with initial corpus and oracle annotation";

open($oh, "<" , "/tmp/nll2rdf.tmp/$out.data");
my %featureset = ();

while(<$oh>) {
  chomp;
  my @line = split ",", $_;
  pop @line; # Remove class attribute

  foreach my $feature(@line) {
    $featureset{$feature} = 1 unless defined $featureset{$feature};
    $featureset{$feature} += 1 if defined $featureset{$feature};
  }
}

close $oh;

open(my $ah, ">", "/tmp/nll2rdf.tmp/$out.arff");

my @filtered = grep { $featureset{$_} > $filter } sort (keys %featureset);

print $ah "\@RELATION nll2rdf\n\n";

foreach my $feature(@filtered) {
  print $ah "\@ATTRIBUTE $feature NUMERIC\n" if $featureset{$feature} > $filter;
}

my @classes = qw/ NO-CLASS PER-COMMERCIALIZE PER-DERIVE PER-DISTRIBUTE
              PER-READ PER-REPRODUCE PER-SELL PRO-COMMERCIALIZE
              PRO-DERIVE PRO-DISTRIBUTE REQ-ATTACHPOLICY
              REQ-ATTACHSOURCE REQ-ATTRIBUTE REQ-SHAREALIKE /;

print $ah "\@ATTRIBUTE class-nll2rdf {" . join(",", sort @classes) . "}\n\n\@DATA\n";

open($oh, "<", "/tmp/nll2rdf.tmp/$out.data");

while(<$oh>) {
  chomp;
  
  my %setoffeatures = map { $_ => 0 } @filtered;

  my @line = split ",", $_;
  my $class = pop @line;

  foreach my $feature (@line) {
    $setoffeatures{$feature} += 1 if exists $setoffeatures{$word};
  }

  foreach my $feature (sort keys %setoffeatures) {
    print $ah $setoffeatures{$feature} . ",";
  }
  
  print $ah "$class\n";
}

close $oh;
close $ah;