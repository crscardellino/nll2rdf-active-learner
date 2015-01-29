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

use autodie qw/ open close opendir closedir /;
use strict;
use warnings;
use File::Basename qw/ basename dirname /;
use lib dirname(__FILE__);
use Utils qw/ get_progress /;

my $untagdir = shift @ARGV;
die "You have to provide a valid directory of the unannotated corpus" unless defined $untagdir;

# Instances storage
my $instancesdir = "/tmp/nll2rdf.tmp/instances/";

# We preprocess the corpus getting all the possible instances (we'll filter them afterwards)
print STDERR "Preprocessing unannotated corpus to get all candidate instances\n";

my @corpus_files = `find $untagdir -type f -name "*.conll"`;
chomp @corpus_files;

my $current_example = 0;
my $total_examples = scalar(@corpus_files);
print STDERR get_progress $total_examples, $current_example;

open(my $ih, ">", "/tmp/nll2rdf.tmp/instances.data");

foreach my $filename(@corpus_files) {
  open(my $fh, "<", "$filename");
  $filename = basename $filename;
  $filename =~ s/\.conll//;

  $current_example++;
  print STDERR "\r" . get_progress $total_examples, $current_example;

  my $instance_number = 0;
  my $itemword;
  my @unigrams = ();
  my @instance = ();

  while(<$fh>){
    chomp;

    my @line = split /\s+/, $_;

    my $newinstance = ((scalar(@line) <= 1) or ($_ =~ m/^\s*$/));
    $newinstance = ($newinstance or $line[1] =~ m/[;:]/);
    $newinstance = ($newinstance or $line[1] =~ m/[;:]/);
    my $isitem = 0;

    if (defined $line[1] and defined($itemword) and ($itemword =~ m/^[a-z](i*|[xv]?)$/)) {
      $isitem = (lc($line[1]) eq '-rrb-');
    }

    $newinstance = ($newinstance or $isitem);

    if ($newinstance) {
      # Array of ngrams and skipgrams
      my @grams = ();

      # Bigrams
      for my $i (0 .. (scalar(@unigrams) - 2)) {
        push @grams, $unigrams[$i] . ";" . $unigrams[$i+1];
      }

      # Trigrams
      for my $i (0 .. (scalar(@unigrams) - 3)) {
        push @grams, $unigrams[$i] . ";" . $unigrams[$i+1] . ";" . $unigrams[$i+2];
      }

      # Uniskipbigrams
      for my $i (0 .. (scalar(@unigrams) - 3)) {
        push @grams, $unigrams[$i] . ";" . $unigrams[$i+2];
      }

      # Biskipbigrams
      for my $i (0 .. (scalar(@unigrams) - 4)) {
        push @grams, $unigrams[$i] . ";" . $unigrams[$i+3];
      }

      # Triskipbigrams
      for my $i (0 .. (scalar(@unigrams) - 5)) {
        push @grams, $unigrams[$i] . ";" . $unigrams[$i+4];
      }

      # Uniskiptrigrams
      for my $i (0 .. scalar(@unigrams) - 5) {
        push @grams, $unigrams[$i] . ";" . $unigrams[$i+2] . ";" . $unigrams[$i+4];
      }

      print $ih join(",", @unigrams) . "," if scalar(@unigrams) > 0;
      print $ih join(",", @grams) . "," if scalar(@grams) > 0;

      print $ih "$filename-$instance_number\n";

      if ($isitem) {
        pop @instance if(scalar(@instance) > 1); # Remove the item word
        pop @instance if(scalar(@instance) > 1) and $instance[$#instance] eq '-LRB-';
      }

      open(my $jh, ">", "$instancesdir/$filename-$instance_number.txt") or die "Couldn't open instance file for writing: $!";
      my $inst = join " ", @instance;
      $inst =~ s/\s([.;:,])/$1/g;
      $inst =~ s/\-LRB\-\s/\(/g;
      $inst =~ s/\s\-RRB\-/\)/g;
      $inst =~ s/\`\`\s/\"/g;
      $inst =~ s/\s\'\'/\"/g;
      $inst =~ s/\s\'s/\'s/g;
      $inst =~ s/([:;])\s/$1\n/g;

      $instance_number++;

      print $jh $inst . "\n";
      close $jh;

      @instance = ();
      @unigrams = ();
      next;
    }

    next if scalar(@line) != 10;

    push @instance, $line[1]; # Useful for Active Learning with the oracle

    my $word = lc $line[1];
    $word =~ s/'s/<POSS>/g;
    $word =~ s/^[0-9]+\.[0-9]*$/<NUMBER>/g;
    $word =~ s/^[0-9]+$/<NUMBER>/g;
    $word =~ s/''/<SYM>/g;
    $word =~ s/``/<SYM>/g;
    $word =~ s/["':;,\.#$%&*_`]/<SYM>/g;

    unless($word =~ m/^[a-z\<][a-zA-Z\-\>]*$/) {
      $itemword = $word;
      next;
    }

    push @unigrams, $word;

    $itemword = $word;
  }
  
  close $fh;
}

print STDERR "\n";

close $ih;
