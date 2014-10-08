#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;

my $tagdir = shift @ARGV;
die "You have to provide a valid directory of the tagged corpus" unless defined $tagdir;

my $outputdir = shift @ARGV;
$outputdir = "/tmp/" unless defined $outputdir;

my $filter = shift @ARGV;
$filter = 0 unless defined $filter;

my $directory = dirname (__FILE__);

print STDERR "Creating arff data file with filter $filter for annotated corpus\n";

my $rc = system "find $tagdir -type f -name \"*.conll\" -print0 | xargs -0 cat | perl $directory/getdata.pl $filter > /tmp/annotated.nll2rdf.data";

die "Error in processing the corpus: $!" if ($rc >> 8) != 0;

$rc = system "perl $directory/getattributes.pl < /tmp/annotated.nll2rdf.data > /tmp/annotated.nll2rdf.bag";

die "Error in processing the features: $!" if ($rc >> 8) != 0;

$rc = system "perl $directory/generatearff.pl /tmp/annotated.nll2rdf.data $filter < /tmp/annotated.nll2rdf.bag > $outputdir/data/annotated.nll2rdf.arff";

die "Error in creating the arff file: $!" if ($rc >> 8) != 0;

$rc = system "perl $directory/tobinaryclassification.pl $outputdir/data/annotated.nll2rdf.arff $outputdir/data/binary";  
die "Error in creating the binary files: $!" if ($rc >> 8) != 0;
