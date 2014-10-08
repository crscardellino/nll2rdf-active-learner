#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;

my $untagdir = shift @ARGV;
die "You have to provide a valid directory of the unannotated corpus" unless defined $untagdir;

my $featuresdir = shift @ARGV;
die "You have to provide a valid features directory" unless defined $featuresdir;

my $oldarff = shift @ARGV;
die unless defined $oldarff;

my $outputdir = shift @ARGV;
$outputdir = "/tmp/" unless defined $outputdir;

my $filter = shift @ARGV;
$filter = 10 unless defined $filter;

my $directory = dirname (__FILE__);

print STDERR "Creating instances file with filter $filter for unannotated corpus\n";

my $rc = system "perl $directory/getdata.pl $untagdir $featuresdir $outputdir/instances > /tmp/unannotated.nll2rdf.data";
die "Error in processing the corpus: $!" if ($rc >> 8) != 0;

$rc = system "perl $directory/getcsv.pl /tmp/unannotated.nll2rdf.data $outputdir $oldarff $filter";
die "Error in creating arff files: $!" if ($rc >> 8) != 0;