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
use File::Basename;
use lib dirname(__FILE__);
use Constants qw / get_class get_rule /;

my @unigrams = ();
my @postags = ();
my $lastclass = undef;

while(<STDIN>){
  chomp;

  next if ($_ =~ m/^\s*$/);

  my @line = split /\s+/, $_;

  next unless defined $line[10] && $line[10] =~ m/([BI])\-(\w+)/;

  if ($1 eq "B" and scalar @unigrams > 0) {
    # Prints the unigrams
    print join ",", @unigrams;

    # Print bigrams (if any)
    for my $i (0 .. (scalar(@unigrams) - 2)) {
      print "," . $unigrams[$i] . ";" . $unigrams[$i+1];
    }

    # Print trigrams (if any)
    for my $i (0 .. (scalar(@unigrams) - 3)) {
      print "," . $unigrams[$i] . ";" . $unigrams[$i+1] . ";" . $unigrams[$i+2];
    }

    # Print uniskipbigram (if any)
    for my $i (0 .. (scalar(@unigrams) - 3)) {
      print "," . $unigrams[$i] . ";" . $unigrams[$i+2];
    }

    # Print biskipbigram (if any)
    for my $i (0 .. (scalar(@unigrams) - 4)) {
      print "," . $unigrams[$i] . ";" . $unigrams[$i+3];
    }
    
    # uniskiptrigram
    for my $i (0 .. scalar(@unigrams) - 5) {
      print "," . $unigrams[$i] . ";" . $unigrams[$i+2] . ";" . $unigrams[$i+4];
    }

    print ",$lastclass\n";

    $lastclass = get_class($2) . "-" . get_rule($line[11]);
    @unigrams = ();
  } elsif ($1 eq "B") {
    $lastclass = get_class($2) . "-" . get_rule($line[11]);
  }

  my $word = lc $line[1];
  $word =~ s/'s/s/g;
  $word =~ s/^[0-9]+\.[0-9]*$/<NUMBER>/g;
  $word =~ s/^[0-9]+$/<NUMBER>/g;
  $word =~ s/''/<SYM>/g;
  $word =~ s/``/<SYM>/g;
  $word =~ s/["':;,\.#$%&*_`]/<SYM>/g;

  next unless $word =~ m/^[a-z\<][a-zA-Z_\-\>]*$/;

  my $pos = $line[3];
  $pos =~ s/''/_/;
  $pos =~ s/:/-/;

  push @unigrams, $word;
  push @postags, $pos;
}

if (scalar @unigrams > 0) {
  # Prints the unigrams and pos
  print join ",", @unigrams;

  # Print bigrams (if any)
  for my $i (0 .. (scalar(@unigrams) - 2)) {
    print "," . $unigrams[$i] . ";" . $unigrams[$i+1];
  }

  # Print trigrams (if any)
  for my $i (0 .. (scalar(@unigrams) - 3)) {
    print "," . $unigrams[$i] . ";" . $unigrams[$i+1] . ";" . $unigrams[$i+2];
  }

  # Print uniskipbigram (if any)
  for my $i (0 .. (scalar(@unigrams) - 3)) {
    print "," . $unigrams[$i] . ";" . $unigrams[$i+2];
  }

  # Print biskipbigram (if any)
  for my $i (0 .. (scalar(@unigrams) - 4)) {
    print "," . $unigrams[$i] . ";" . $unigrams[$i+3];
  }

  # uniskiptrigram
  for my $i (0 .. scalar(@unigrams) - 5) {
    print "," . $unigrams[$i] . ";" . $unigrams[$i+2] . ";" . $unigrams[$i+4];
  }

  print ",$lastclass\n";
}