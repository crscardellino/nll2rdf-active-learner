#!/usr/bin/env perl

use strict;
use warnings;

my %set = ();

while(<STDIN>){
  chomp;
  
  my @line = split ",", $_;
  
  my $class = pop @line;

  foreach my $feature (@line) {
    $set{$feature} = 1;
  }
}

print join ",", sort keys %set;