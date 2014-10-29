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
use File::Basename qw/ dirname /;
use lib dirname(__FILE__);
use Constants qw / get_class get_rule /;

my $tagdir = shift @ARGV;
die "You have to provide a valid directory of the tagged corpus" unless defined $tagdir;

my $filter = shift @ARGV;
$filter = 0 unless defined $filter;

print STDERR "Getting features from tagged corpus\n";

my @corpusfiles = `find $tagdir -type f -name "*.conll"`;
chomp @corpusfiles;

open(my $dh, ">", "/tmp/nll2rdf.tmp/annotated.data");

my %featureset = ();

foreach my $file(@corpusfiles) {
  open(my $fh, "<", $file);

  my $class;
  my @unigrams = ();

  while(<$fh>) {
    chomp;

    next if ($_ =~ m/^\s*$/);

    my @line = split /\s+/, $_;

    next unless defined $line[10] && $line[10] =~ m/([BI])\-(\w+)/;

    if ($1 eq "B") {
      $class = get_class($2) . "-" . get_rule($line[11]);
    }

    my $word = lc $line[1];
    $word =~ s/'s/<POSS>/g;
    $word =~ s/^[0-9]+\.[0-9]*$/<NUMBER>/g;
    $word =~ s/^[0-9]+$/<NUMBER>/g;
    $word =~ s/''/<SYM>/g;
    $word =~ s/``/<SYM>/g;
    $word =~ s/["':;,\.#$%&*_`]/<SYM>/g;

    next unless $word =~ m/^[a-z\<][a-zA-Z_\-\>]*$/;

    push @unigrams, $word;
    $featureset{$word} += 1;
  }
  
  # Prints the unigrams
  print $dh join ",", @unigrams;

  # Print bigrams (if any)
  for my $i (0 .. (scalar(@unigrams) - 2)) {
    my $bigram = $unigrams[$i] . ";" . $unigrams[$i+1];
    print $dh "," . $bigram;
    $featureset{$bigram} += 1;
  }

  # Print trigrams (if any)
  for my $i (0 .. (scalar(@unigrams) - 3)) {
    my $trigram = $unigrams[$i] . ";" . $unigrams[$i+1] . ";" . $unigrams[$i+2];
    print $dh "," . $trigram;
    $featureset{$trigram} += 1;
  }

  # Print uniskipbigram (if any)
  for my $i (0 .. (scalar(@unigrams) - 3)) {
    my $skipgram = $unigrams[$i] . ";" . $unigrams[$i+2];
    print $dh "," . $skipgram;
    $featureset{$skipgram} += 1;
  }

  # Print biskipbigram (if any)
  for my $i (0 .. (scalar(@unigrams) - 4)) {
    my $skipgram = $unigrams[$i] . ";" . $unigrams[$i+3];
    print $dh "," . $skipgram;
    $featureset{$skipgram} += 1;
  }

  # Print biskiptrigram (if any)
  for my $i (0 .. (scalar(@unigrams) - 5)) {
    my $skipgram = $unigrams[$i] . ";" . $unigrams[$i+4];
    print $dh "," . $skipgram;
    $featureset{$skipgram} += 1;
  }

  # uniskiptrigram
  for my $i (0 .. scalar(@unigrams) - 5) {
    my $skipgram = $unigrams[$i] . ";" . $unigrams[$i+2] . ";" . $unigrams[$i+4];
    print $dh "," . $skipgram;
    $featureset{$skipgram} += 1;
  }

  print $dh ",$class\n";

  close $fh;
}

close $dh;

open(my $ah, ">", "/tmp/nll2rdf.tmp/annotated.arff");

print STDERR "Filtering features from tagged corpus\n";

my @filtered = grep { $featureset{$_} > $filter } sort (keys %featureset);

print STDERR "Creating arff file from tagged corpus\n";

print $ah "\@RELATION nll2rdf\n\n";

foreach my $feature(@filtered) {
  print $ah "\@ATTRIBUTE $feature NUMERIC\n" if $featureset{$feature} > $filter;
}

my @classes = qw/ NO-CLASS PER-COMMERCIALIZE PER-DERIVE PER-DISTRIBUTE
              PER-READ PER-REPRODUCE PER-SELL PRO-COMMERCIALIZE
              PRO-DERIVE PRO-DISTRIBUTE REQ-ATTACHPOLICY
              REQ-ATTACHSOURCE REQ-ATTRIBUTE REQ-SHAREALIKE /;

print $ah "\@ATTRIBUTE class-nll2rdf {" . join(",", sort @classes) . "}\n\n\@DATA\n";

open($dh, "<", "/tmp/nll2rdf.tmp/annotated.data");

while(<$dh>) {
  chomp;
  
  my %setoffeatures = map { $_ => 0 } @filtered;

  my @line = split ",", $_;
  my $class = pop @line;

  foreach my $word (@line) {
    $setoffeatures{$word} += 1 if exists $setoffeatures{$word};
  }

  foreach my $feature (sort keys %setoffeatures) {
    print $ah $setoffeatures{$feature} . ",";
  }
  
  print $ah "$class\n";
}

close $dh;
close $ah;