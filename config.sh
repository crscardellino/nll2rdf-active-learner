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

echo "Installing perlbrew"
\curl -L http://install.perlbrew.pl | bash

echo "Adding source ~/perl5/perlbrew/etc/bashrc"

if [ -f ~/.bashrc ];
then
  echo "# Source to perlbrew" >> ~/.bashrc
  echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.bashrc
  source ~/.bashrc
elif [ -f ~/.profile ]
  echo "# Source to perlbrew" >> ~/.profile
  echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.profile
  source ~/.profile
else
  echo "# Source to perlbrew" >> ~/.bash_profile
  echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.bash_profile
  source ~/.bash_profile
fi

echo "Installing perl 5.16"
perlbrew install `perlbrew available | egrep -o "perl-5.16.*"`

echo "Changing perl version to use"
perlbrew use `perlbrew list | egrep -o "perl-5.20.*"`

echo "Installing cpanm"
perlbrew install-cpanm

echo "Installing the modules"
bash install_modules.sh