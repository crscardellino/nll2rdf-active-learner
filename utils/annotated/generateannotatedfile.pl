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

my $tagdir = shift @ARGV;
die "You have to provide a valid directory of the tagged corpus" unless defined $tagdir;

my $outputdir = shift @ARGV;
$outputdir = "/tmp/" unless defined $outputdir;

my $filter = shift @ARGV;
$filter = 0 unless defined $filter;

my $oldfeaturesdir = shift @ARGV;

my $directory = dirname (__FILE__);

print STDERR "Creating arff data file with filter $filter for annotated corpus\n";

my $rc = system "find $tagdir -type f -name \"*.conll\" -print0 | xargs -0 cat | perl $directory/getdata.pl > /tmp/annotated.nll2rdf.data";
die "Error in processing the corpus: $!" if ($rc >> 8) != 0;

if (defined $oldfeaturesdir) {
  $rc = system "perl $directory/getmanualdata.pl $oldfeaturesdir $outputdir/instances/tagged >> /tmp/annotated.nll2rdf.data";
  die "Error in processing the manually tagged instances: $!" if ($rc >> 8) != 0;
}

$rc = system "perl $directory/getattributes.pl < /tmp/annotated.nll2rdf.data > /tmp/annotated.nll2rdf.bag";
die "Error in processing the features: $!" if ($rc >> 8) != 0;

$rc = system "perl $directory/generatearff.pl /tmp/annotated.nll2rdf.data $filter < /tmp/annotated.nll2rdf.bag > $outputdir/data/annotated.nll2rdf.arff";
die "Error in creating the arff file: $!" if ($rc >> 8) != 0;

$rc = system "perl $directory/tobinaryclassification.pl $outputdir/data/annotated.nll2rdf.arff $outputdir/data/binary";  
die "Error in creating the binary files: $!" if ($rc >> 8) != 0;
