#!/usr/bin/env bash

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

echo "Installing autodie"
cpanm autodie

echo "Installing File::Basename"
cpanm File::Basename

echo "Installing File::Spec"
cpanm File::Spec

echo "Installing Getopt::Long"
cpanm Getopt::Long

echo "Installing List::MoreUtils"
cpanm List::MoreUtils

echo "Installing List::Util"
cpanm List::Util

echo "Installing POSIX"
cpanm POSIX

echo "Installing Statistics::Descriptive"
cpanm Statistics::Descriptive

echo "Installing Statistics::Descriptive::Weighted"
cpanm Statistics::Descriptive::Weighted

echo "Installing String::Util"
cpanm String::Util