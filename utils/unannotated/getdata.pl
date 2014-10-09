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
use POSIX;

my $dir = shift @ARGV;
my $featuresdir = shift @ARGV;
my $instances = shift @ARGV;

opendir(my $dh, $dir) or die "Couldn't open the directory";

my $examples = 0;
my @unigrams = ();
my @bigrams = ();
my @trigrams = ();
my $lastword = undef;
my $beforelastword = undef;
my @instance = ();

sub get_progress {
  my $totalexamples = 395;
  my $examplenumber = shift @_;
  my $percentage = $examplenumber * 100 / $totalexamples;

  my $totalbars = "=" x floor $percentage;
  my $totalempties = " " x (100 - floor $percentage);
  
  return "[". $totalbars . $totalempties . "]" . sprintf("%.2f%%", $percentage);
}

my @features = `cat $featuresdir/features.*.txt`;
chomp @features;

my %relevantfeatures = map { $_ => 1 } @features;

print STDERR "Reading and writing data examples\n";

while(readdir $dh) {
  next unless $_ !~ m/^\./;

  open(my $fh, "<", "$dir/$_") or die "Couldn't open file $dir/$_: $!";

  print STDERR "\r" . get_progress $examples;
  $examples += 1;

  my $filename = $_;
  $filename =~ s/\.conll//;

  my $instance_number = 0;

  while(<$fh>){
    chomp;

    if ($_ =~ m/^\s*$/) {
      # The data is only good if has at least one of the relevant features
      my %hintunigrams = map { $_ => 1 } grep { exists $relevantfeatures{$_} } @unigrams;
      my %hintbigrams = map { $_ => 1 } grep { exists $relevantfeatures{$_} } @bigrams;
      my %hinttrigrams = map { $_ => 1 } grep { exists $relevantfeatures{$_} } @trigrams;
      
      if (scalar(keys %hintunigrams) > 0 or scalar(keys %hintbigrams) > 0 or scalar(keys %hinttrigrams) > 0) {
        print join ",", @unigrams;
        print join ",", @bigrams;
        print join ",", @trigrams;

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

        print ",$filename-$instance_number\n";
        
        open(my $ih, ">", "$instances/$filename-$instance_number.txt") or die "Couldn't open instance file for writing: $!";
        my $instance = join " ", @instance;
        $instance =~ s/\s([.;:,])/$1/g;
        $instance =~ s/\-lrb\-\s/\(/g;
        $instance =~ s/\s\-rrb\-/\)/g;
        $instance =~ s/\`\`\s/\"/g;
        $instance =~ s/\s\'\'/\"/g;
        $instance =~ s/([:;])\s/$1\n/g;

        print $ih $instance . "\n";
        close $ih;
      }

      @unigrams = ();
      @bigrams = ();
      @trigrams = ();
      $beforelastword = undef;
      $lastword = undef;
      @instance = ();
      $instance_number++;
      next;
    }

    my @line = split /\s+/, $_;

    next if scalar(@line) != 10;

    my $word = lc $line[1];

    push @instance, $word; # Useful for Active Learning with the oracle

    $word =~ s/'s/s/g;
    $word =~ s/''//g;
    $word =~ s/[:;,\.\"]//g;

    my $pos = $line[3];
    $pos =~ s/''/_/;
    $pos =~ s/:/-/;

    next unless $word =~ m/^[a-zA-Z][a-zA-Z_\-]+$/;

    # my $validpos = $pos =~ m/^(JJ|NN|RB|VB)/; # We only take in consideration Adjectives, Nouns, Adverbs and Verbs in order to reduce the range of values (and avoid overload of the model)
    my $relevantword = exists $relevantfeatures{$word};
    my $relevantlastword = defined $lastword and exists $relevantfeatures{$lastword};
    my $relevantbeforelastword = defined $beforelastword and exists $relevantfeatures{$beforelastword};

    if($lastword && $beforelastword) {
      my $element = "$beforelastword;$lastword;$word";
      push @trigrams, $element if exists $relevantfeatures{$element} or $relevantword or
                                  $relevantlastword or $relevantbeforelastword;
    } 

    if($lastword) {
      my $element = "$lastword;$word";
      push @bigrams, $element if exists $relevantfeatures{$element} or $relevantword
                                 or $relevantlastword;
    } 

    push @unigrams, "$word" if $relevantword; # or $validpos;

    $beforelastword = $lastword;
    $lastword = $word;
  }
  
  close $fh;
}

print STDERR "\n";