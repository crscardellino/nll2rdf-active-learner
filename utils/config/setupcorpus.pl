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

mkdir "/tmp/nll2rdf.tmp/taggedcorpus";
my $rc = system "tar Jxf /tmp/nll2rdf.tmp/taggedcorpus.tar.xz -C /tmp/nll2rdf.tmp/taggedcorpus";
die if ($rc >> 8) != 0;

mkdir "/tmp/nll2rdf.tmp/untaggedcorpus";
$rc = system "tar Jxf /tmp/nll2rdf.tmp/untaggedcorpus.tar.xz -C /tmp/nll2rdf.tmp/untaggedcorpus";
die if ($rc >> 8) != 0;