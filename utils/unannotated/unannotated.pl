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
use File::Basename qw/ basename /;
use List::Util qw/ sum /;
use POSIX qw/ floor /;

sub get_progress {
  my $totalexamples = shift @_;
  my $examplenumber = shift @_;
  my $percentage = $examplenumber * 100 / $totalexamples;

  my $totalbars = "=" x floor $percentage;
  my $totalempties = " " x (100 - floor $percentage);
  
  return "[". $totalbars . $totalempties . "]" . sprintf("%.0f%%", $percentage);
}

sub trim {
  my $s = shift;
  $s =~ s/^\s+|\s+$//g;
  return $s;
}

my $untagdir = shift @ARGV;
die "You have to provide a valid directory of the unannotated corpus" unless defined $untagdir;

my $arff = shift @ARGV;
die "You have to provide a valid arff file" unless defined $arff;

my $iteration = shift @ARGV;
die "You have to provide a valid iteration" unless defined $iteration;

my $filter = shift @ARGV;
$filter = 25 unless defined $filter;

# To store instances
my $instances = "/tmp/nll2rdf.tmp/instances/iteration$iteration";
mkdir $instances;
mkdir "$instances/tagged";


# Get the relevant features
my @features = `cat /tmp/nll2rdf.tmp/features/features.$iteration.txt`;
chomp @features;
my %features = map { $_ => 1 } @features;

print STDERR "Getting instances from unannotated corpus with filter $filter\n";

my @corpus_files = `find $untagdir -type f -name "*.conll"`;
chomp @corpus_files;

my $current_example = 0;
my $total_examples = scalar(@corpus_files);
print STDERR get_progress $total_examples, $current_example;

open(my $uh, ">", "/tmp/nll2rdf.tmp/unannotated.data");

foreach my $filename(@corpus_files) {
  open(my $fh, "<", "$filename");
  $filename = basename $filename;
  $filename =~ s/\.conll//;

  $current_example++;
  print STDERR "\r" . get_progress $total_examples, $current_example;

  my $instance_number = 0;
  my $itemword;
  my $lastword;
  my $beforelastword;
  my @unigrams = ();
  my @bigrams = ();
  my @trigrams = ();
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
      # The data is only good if has at least one of the relevant features
      my @filtered_unigrams = grep { exists $features{$_} } @unigrams;
      my @filtered_bigrams = grep { exists $features{$_} } @bigrams;
      my @filtered_trigrams = grep { exists $features{$_} } @trigrams;

      my @skipgrams = ();
      for my $i (0 .. (scalar(@unigrams) - 3)) {
        push @skipgrams, $unigrams[$i] . ";" . $unigrams[$i+2];
      }

      for my $i (0 .. (scalar(@unigrams) - 4)) {
        push @skipgrams, $unigrams[$i] . ";" . $unigrams[$i+3];
      }

      my @triskipbigram = ();
      for my $i (0 .. (scalar(@unigrams) - 5)) {
        push @skipgrams, $unigrams[$i] . ";" . $unigrams[$i+4];
      }

      for my $i (0 .. scalar(@unigrams) - 5) {
        push @skipgrams, $unigrams[$i] . ";" . $unigrams[$i+2] . ";" . $unigrams[$i+4];
      }

      my @filtered_skipgrams = grep { exists $features{$_} } @skipgrams;

      if (scalar(@filtered_unigrams) > 0 or scalar(@filtered_bigrams) > 0
          or scalar(@filtered_trigrams) > 0 or scalar(@filtered_skipgrams) > 0) {
        print $uh join(",", @unigrams) . "," if scalar(@unigrams) > 0;
        print $uh join(",", @bigrams) . "," if scalar(@bigrams) > 0;
        print $uh join(",", @trigrams) . "," if scalar(@trigrams) > 0;
        print $uh join(",", @skipgrams) . "," if scalar(@filtered_skipgrams) > 0;

        print $uh "$filename-$instance_number\n";

        if ($isitem) {
          pop @instance if(scalar(@instance) > 1); # Remove the item word
          pop @instance if(scalar(@instance) > 1) and $instance[$#instance] eq '-LRB-';
        }

        open(my $ih, ">", "$instances/$filename-$instance_number.txt") or die "Couldn't open instance file for writing: $!";
        my $inst = join " ", @instance;
        $inst =~ s/\s([.;:,])/$1/g;
        $inst =~ s/\-LRB\-\s/\(/g;
        $inst =~ s/\s\-RRB\-/\)/g;
        $inst =~ s/\`\`\s/\"/g;
        $inst =~ s/\s\'\'/\"/g;
        $inst =~ s/\s\'s/\'s/g;
        $inst =~ s/([:;])\s/$1\n/g;

        $instance_number++;

        print $ih $inst . "\n";
        close $ih;
      }

      @instance = ();
      @unigrams = ();
      @bigrams = ();
      @trigrams = ();
      $beforelastword = undef;
      $lastword = undef;
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

    my $relevantword = exists $features{$word};
    my $relevantlastword = (defined $lastword and exists $features{$lastword});
    my $relevantbeforelastword = (defined $beforelastword and exists $features{$beforelastword});

    if($lastword && $beforelastword) {
      my $element = "$beforelastword;$lastword;$word";
      push @trigrams, $element if (exists $features{$element} or $relevantword or
                                  $relevantlastword or $relevantbeforelastword);
    } 

    if($lastword) {
      my $element = "$lastword;$word";
      push @bigrams, $element if (exists $features{$element} or $relevantword
                                 or $relevantlastword);
    } 

    push @unigrams, "$word" if $relevantword;

    $beforelastword = $lastword;
    $lastword = $word;
    $itemword = $word;
  }
  
  close $fh;
}

close $uh;

print STDERR "\nGetting data from unannotated instances\n";

open($uh, "<", "/tmp/nll2rdf.tmp/unannotated.data");

my @attributes = `grep "^\@ATTRIBUTE" $arff | awk '{ print \$2 }'`;
chomp @attributes;
pop @attributes; # Remove the class attribute
my %totalattrs = map { $_ => 0 } @attributes;

$total_examples = trim `wc -l /tmp/nll2rdf.tmp/unannotated.data | awk '{ print \$1 }'`;
$current_example = 0;
print STDERR get_progress $total_examples, $current_example;

open(my $ah, ">", "/tmp/nll2rdf.tmp/unannotated.csv");

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

while(<$uh>) {
  $current_example++;
  print STDERR "\r" . get_progress $total_examples, $current_example;

  chomp;
  
  my %setofattrs = map { $_ => 0 } @attributes;

  my @line = split ",", $_;
  my $instanceid = pop @line;

  foreach my $attr (@line) {
    $setofattrs{$attr} += 1 if exists $filtered_attributes{$attr};
  }

  if(sum(values %setofattrs) > $filter) {
    print $ah "'$instanceid'," . join(",", map { $setofattrs{$_} } sort keys %setofattrs) . ",0\n";
  }
}

close $ah;
close $uh;
print STDERR "\n";