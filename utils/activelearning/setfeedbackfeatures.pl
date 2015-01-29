#!/usr/bin/env perl

# NLL2RDF Active Learner
# Copyright (C) 2014 AUTHOR NAME
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
use File::Basename qw/ basename /;

my $iteration = shift @ARGV;
die "You must provide a valid iteration number" unless defined $iteration;

# How many features to take (-1 means all)
my $size = shift @ARGV;
$size = 10 unless defined $size;

print STDERR "Setting new features with feedback\n";

my @features_files = `find /tmp/nll2rdf.tmp/features -name "features.*.$iteration.txt"`;
die if ($? >> 8) != 0;
chomp @features_files;

# Save the original features (to add the feedback features after)
my %original_features = ();

print STDERR "Getting original features\n";
foreach my $feature_file(@features_files) {
  my $feature_name = basename $feature_file;
  $feature_name =~ m/^features\.([A-Z\-]+)\.[0-9]+\.txt$/;
  my $class = $1;

  my @features = `cat $feature_file`;
  chomp @features;

  $original_features{$class} = \@features;
}

my @feedback_files = `find /tmp/nll2rdf.tmp/features -name "feedback.*.$iteration.txt"`;
die if ($? >> 8) != 0;
chomp @feedback_files;

my %feedback_features = ();

print STDERR "Getting feedback features\n";
foreach my $feedback_file(@feedback_files) {
  my $feedback_name = basename $feedback_file;
  $feedback_name =~ m/^feedback\.([A-Z\-]+)\.[0-9]+\.txt$/;
  my $class = $1;

  my @feedback = `cat $feedback_file`;
  chomp @feedback;

  splice(@feedback, $size) if $size >= 0; # Only left $size elements

  $feedback_features{$class} = \@feedback;
}

print STDERR "Saving new features\n";
foreach my $feature_file(@features_files) {
  my $feature_name = basename $feature_file;
  $feature_name =~ m/^features\.([A-Z\-]+)\.[0-9]+\.txt$/;
  my $class = $1;

  my %feature_set = map { $_ => 1 } @{$original_features{$class}};

  open(my $fh, ">", $feature_file);

  print $fh join("\n", @{$original_features{$class}}) . "\n" if scalar(@{$original_features{$class}}) > 0;
  print $fh join("\n", grep { !defined $feature_set{$_} } @{$feedback_features{$class}});

  close $fh;
}

print STDERR "Collecting features\n";
open(my $fh, ">", "/tmp/nll2rdf.tmp/features/features.$iteration.txt");

my @features = `find /tmp/nll2rdf.tmp/features -name "features.*.$iteration.txt" -print0 | xargs -0 cat`;
chomp @features;
my %set_of_features = map { $_ => 1 } @features;

print $fh join("\n", keys %set_of_features);

close $fh;
