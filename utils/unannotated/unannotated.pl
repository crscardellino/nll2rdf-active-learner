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

use autodie qw/ open close opendir closedir /;
use strict;
use warnings;
use File::Basename qw/ basename dirname /;
use List::Util qw/ sum /;
use lib dirname(__FILE__);
use Utils qw/ get_progress trim /;

my $arff = shift @ARGV;
die "You have to provide a valid arff file" unless defined $arff;

my $iteration = shift @ARGV;
die "You have to provide a valid iteration" unless defined $iteration;

my $filter = shift @ARGV;
$filter = 50 unless defined $filter;

# To store instances
my $instances = "/tmp/nll2rdf.tmp/instances/iteration$iteration";
mkdir $instances;

# Get the relevant features
my @features = `cat /tmp/nll2rdf.tmp/features/features.$iteration.txt`;
chomp @features;
my %features = map { $_ => 1 } @features;

# Get the relevant instances in the unannotated corpus
print STDERR "Getting the relevant instances in the unannotated corpus\n";
my $instances_file = "/tmp/nll2rdf.tmp/instances.data";
my $current_example = 0;
my $total_examples = trim(`wc -l $instances_file | awk '{ print \$1 }'`);
print STDERR get_progress $total_examples, $current_example;

open(my $uh, ">", "/tmp/nll2rdf.tmp/unannotated.data");
open(my $ih, "<", $instances_file);

while(<$ih>) {
  chomp;
  my $data = $_;

  $current_example++;
  print STDERR "\r" . get_progress $total_examples, $current_example;

  my @grams = split ",", $data;
  pop @grams; # Remove the instance id

  # The grams are relevant if exist as a feature. The instance is relevant if it has at least one relevant feature (can have more)
  my $relevant = scalar(grep { exists $features{$_} } @grams) > 0;

  # If we have a relevant instance we store the whole instance
  print $uh "$data\n" if $relevant;
}

close $ih;
close $uh;

open($uh, "<", "/tmp/nll2rdf.tmp/unannotated.data");

print STDERR "\nFormatting data to fit the features of the model";

my @attributes = `grep "^\@ATTRIBUTE" $arff | awk '{ print \$2 }'`;
chomp @attributes;
pop @attributes; # Remove the class attribute
my %totalattrs = map { $_ => 0 } @attributes;

while(<$uh>) {
  chomp;

  my @line = split ",", $_;

  pop @line; # Remove the instance identifier

  foreach my $attr (@line) {
    $totalattrs{$attr} += 1 if exists $totalattrs{$attr};
  }
}

my %filtered_attributes = map { $_ => 1 } (grep { $totalattrs{$_} > $filter } @attributes);

open($uh , "<", "/tmp/nll2rdf.tmp/unannotated.data");
open(my $ah, ">", "/tmp/nll2rdf.tmp/unannotated.csv");

$total_examples = trim `wc -l /tmp/nll2rdf.tmp/unannotated.data | awk '{ print \$1 }'`;
$current_example = 0;

my %tagged_instances;

if(-e "/tmp/nll2rdf.tmp/tagged_instances.txt") {
  my @tagged_instances = `cat /tmp/nll2rdf.tmp/tagged_instances.txt`;
  %tagged_instances = map { $_ => 1 } @tagged_instances;
}

print STDERR "\nGetting data from unannotated instances\n";
print STDERR get_progress $total_examples, $current_example;

while(<$uh>) {
  chomp;
  my @line = split ",", $_;
  my $instanceid = pop @line;

  $current_example++;
  print STDERR "\r" . get_progress $total_examples, $current_example;

  next if exists $tagged_instances{$instanceid};

  my %setofattrs = map { $_ => 0 } @attributes;

  foreach my $attr (@line) {
    $setofattrs{$attr} += 1 if exists $filtered_attributes{$attr};
  }

  print $ah "'$instanceid'," . join(",", map { $setofattrs{$_} } sort keys %setofattrs) . ",0\n";
}

close $ah;
close $uh;
print STDERR "\n";