#!/usr/bin/env perl

use strict;
use warnings;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use POSIX qw( floor );
use String::Util qw( trim );

sub get_progress {
  my $totalexamples = shift @_;
  my $examplenumber = shift @_;
  my $percentage = $examplenumber * 100 / $totalexamples;

  my $totalbars = "=" x floor $percentage;
  my $totalempties = " " x (100 - floor $percentage);
  
  return "[". $totalbars . $totalempties . "]" . sprintf("%.2f%%", $percentage);
}

my $datafile = shift @ARGV;
my $dirpath = shift @ARGV;
my $oldarff = shift @ARGV;
my $filter = shift @ARGV;

$filter = 10 unless defined $filter;

print STDERR "Getting arff file for the unannotated corpus\n";

opendir(my $dh, $dirpath) or die "$dirpath is not a valid directory";
closedir $dh;

open(my $fh , "<", $datafile) or die "Couldn't open file $datafile: $!";

my @attributes = `grep "^\@ATTRIBUTE" $oldarff`;
chomp @attributes;
pop @attributes; # Remove the class attribute
my %totalattrs = map { $_ => 0 } @attributes;

my $totalexamples = trim(`wc -l $datafile | awk '{ print \$1 }'`);
my $currentexamples = 0;

open(my $ah, ">", "$dirpath/data/unannotated.nll2rdf.arff") or die "Couldn't create file $dirpath/data/unannotated.nll2rdf.arff: $!";

print $ah "\@RELATION unannotated-conditions\n\n";

while(<$fh>) {
  chomp;

  my @line = split ",", $_;

  pop @line; # Remove the instance identifier

  foreach my $attr (@line) {
    $totalattrs{$attr} += 1 if exists $totalattrs{$attr};
  }
}

close $fh;

# Filter the attributes (we ignore the attributes less than the filter)
my %filtered_attributes = map { $_ => 1 } (grep { $totalattrs{$_} > $filter } @attributes);

print $ah "\@ATTRIBUTE INSTANCE-ID STRING\n";

foreach my $attr (@attributes) {
  print $ah "\@ATTRIBUTE $attr NUMERIC\n";
}

print $ah "\@ATTRIBUTE unannotated-class-nll2rdf {0,1}\n"; # The class attribute is generic
print $ah "\n\@DATA\n";

open($fh , "<", $datafile) or die "Couldn't open file $datafile: $!";

while(<$fh>) {
  $currentexamples += 1;

  print STDERR "\r" . get_progress $totalexamples, $currentexamples;

  chomp;
  
  my %setofattrs = map { $_ => 0 } @attributes;

  my @line = split ",", $_;
  my $instanceid = pop @line;

  foreach my $attr (@line) {
    $setofattrs{$attr} += 1 if exists $filtered_attributes{$attr};
  }

  print $ah "'$instanceid'," . join(",", map { $setofattrs{$_} } sort keys %setofattrs) . ",?\n";
}

print STDERR "\nFinnished getting arff of unannotated corpus\n";