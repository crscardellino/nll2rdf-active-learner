#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use lib dirname(__FILE__);
use Constants;

my $filter = shift @ARGV;
$filter = 0 unless defined $filter;

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

    # Print bigrams (if any) and bigrams of pos and bigrams with word replacements
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
  $word =~ s/''/_/g;
  $word =~ s/:/-/g;

  next unless $word =~ m/[a-zA-Z_\-]+/;

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