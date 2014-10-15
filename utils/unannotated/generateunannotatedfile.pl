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

my $untagdir = shift @ARGV;
die "You have to provide a valid directory of the unannotated corpus" unless defined $untagdir;

my $featuresdir = shift @ARGV;
die "You have to provide a valid features directory" unless defined $featuresdir;

my $oldarff = shift @ARGV;
die unless defined $oldarff;

my $outputdir = shift @ARGV;
die unless defined $outputdir;

my $filter = shift @ARGV;
$filter = 10 unless defined $filter;

my $directory = dirname (__FILE__);

print STDERR "Creating instances file with filter $filter for unannotated corpus\n";

my $rc = system "perl $directory/getdata.pl $untagdir $featuresdir $outputdir/instances > $outputdir/data/unannotated.nll2rdf.data";
die "Error in processing the corpus: $!" if ($rc >> 8) != 0;

$rc = system "perl $directory/getcsv.pl $outputdir/data/unannotated.nll2rdf.data $outputdir $oldarff $filter";
die "Error in creating arff files: $!" if ($rc >> 8) != 0;