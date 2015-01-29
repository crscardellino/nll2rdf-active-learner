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

print STDERR "Creating filters\n";

my @features_files = `find /tmp/nll2rdf.tmp/features -name "features.*.$iteration.txt"`;
die if ($? >> 8) != 0;
chomp @features_files;

foreach my $feature_file(@features_files) {
  my $feature_name = basename $feature_file;
  $feature_name =~ m/^features\.([A-Z\-]+)\.[0-9]+\.txt$/;
  my $class = $1;

  my @class_features = `cat $feature_file`;
  die if ($? >> 8) != 0;
  chomp @class_features;
  my %class_features = map { $_ => 1 } @class_features;

  my @non_class_features = `find /tmp/nll2rdf.tmp/features -name "features.*.$iteration.txt" -not -name "features.$class.$iteration.txt" -print0 | xargs -0 cat`;
  die if ($? >> 8) != 0;
  chomp @non_class_features;
  my %non_class_features = map { $_ => 1 } (grep { !exists $class_features{$_} } @non_class_features);

  open(my $fh, ">", "/tmp/nll2rdf.tmp/features/filter.$class.$iteration.txt");
  print $fh join("\n", keys %non_class_features);
  close $fh;
}
