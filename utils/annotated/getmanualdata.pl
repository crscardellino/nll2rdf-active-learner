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
my $instancesdir = shift @ARGV;

opendir(my $dh, $featuresdir) or die "Must provide a valid features directory";
closedir $dh;
opendir($dh, $instancesdir) or die "Must provide a valid instances directory";

while(readdir $dh) {
  next unless $_ =~ m/^([^A-Z]+)\.([A-Z\-]+)\.txt$/;
  my $instance = $1;
  my $class = $2;
  my @unigrams = ();

  open(my $fh, "< $instancesdir/$_") or die "$!";

  while(<$fh>) {
    chomp;

    my @line = split /\s+/, $_;

    foreach my $word(@line) {
      $word = lc $word;
      $word =~ s/'s/s/g;
      $word =~ s/''//g;
      $word =~ s/[:;,\.\"\(\)]//g;

      next unless $word =~ m/[a-z_\-]+/;

      push @unigrams, $word;
    }
  }

  my @other_classes = `find $instancesdir/ -name "$1.*.txt" -not -name "$1.$2.txt" -type f -print0 | xargs -0 -I % basename % | egrep -o "\\.[A-Z\\-]*\\." | tr -d '.'`;
  chomp @other_classes;

  @other_classes = grep { $_ ne "no-class" } (map { lc $_ } @other_classes);
  my %filtering_features = ();

  foreach my $other_class(@other_classes) {
    my @features = `cat $featuresdir/features.$other_class.txt`;
    chomp @features;
    %filtering_features = map { $_ => 1 } keys(%filtering_features), @features;
  }

  my @data = ();

  # Print filtered unigrams
  push(@data, grep { !exists $filtering_features{$_} } @unigrams);

  # Print bigrams (if any)
  for my $i (0 .. (scalar(@unigrams) - 2)) {
    my $value = $unigrams[$i] . ";" . $unigrams[$i+1];
    push (@data, $value) unless exists $filtering_features{$value};
  }

  # Print trigrams (if any)
  for my $i (0 .. (scalar(@unigrams) - 3)) {
    my $value = $unigrams[$i] . ";" . $unigrams[$i+1] . ";" . $unigrams[$i+2];
    push (@data, $value) unless exists $filtering_features{$value};
  }

  # Print uniskipbigram (if any)
  for my $i (0 .. (scalar(@unigrams) - 3)) {
    my $value = $unigrams[$i] . ";" . $unigrams[$i+2];
    push (@data, $value) unless exists $filtering_features{$value};
  }

  # Print biskipbigram (if any)
  for my $i (0 .. (scalar(@unigrams) - 4)) {
    my $value = $unigrams[$i] . ";" . $unigrams[$i+3];
    push (@data, $value) unless exists $filtering_features{$value};
  }
  
  # uniskiptrigram
  for my $i (0 .. scalar(@unigrams) - 5) {
    my $value = $unigrams[$i] . ";" . $unigrams[$i+2] . ";" . $unigrams[$i+4];
    push (@data, $value) unless exists $filtering_features{$value};
  }

  if (scalar(@data) > 0) {
    print join(",", @data) . ",$class\n";
  }
}

closedir $dh;