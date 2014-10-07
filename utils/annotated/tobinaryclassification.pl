#!/usr/bin/env perl

use autodie;
use strict;
use warnings;
use List::MoreUtils qw(firstidx);

my $attrfile = shift @ARGV;
my $outdir = shift @ARGV;

my @attributes = `grep "^\@ATTRIBUTE" $attrfile`;

chomp @attributes;

my @classes = split ",", (split /\s+/, pop @attributes)[2];

$classes[0] =~ s/{//;
$classes[12] =~ s/}//;

my @files = ();

foreach my $class(@classes) {
  open(my $fh, ">", "$outdir/$class.arff");

  push @files, $fh;

  print $fh "\@RELATION $class\n\n";
  print $fh join "\n", @attributes;
  print $fh "\n\@ATTRIBUTE class-nll2rdf-$class {0,1}\n\n\@DATA\n";
}

my @instances = `egrep -v "^[@]|^\\s*\$" $attrfile`;
chomp @instances;

foreach my $instance(@instances) {
  my @values = split ",", $instance;
  my $instance_class = pop @values;
  
  foreach my $class(@classes) {
    my $idx = firstidx { $_ eq $class } @classes;
    my $fh = $files[$idx];
    
    print $fh join ",", @values;
    
    if ($class eq $instance_class) {
      print $fh ",1\n";
    } else {
      print $fh ",0\n";
    }
  }
}

foreach my $fh(@files) {
  close $fh;
}