#!/usr/bin/env fish
# {cron,whatever}job updates pathogen plugins automatically
# 
# Copyright 2015 Roman Hargrave <roman@hargrave.info>
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

# Path to `pathogen.fish`
set pathogen_bin (dirname (status -f))/pathogen.fish

if test -e $pathogen_bin
	source $pathogen_bin
	pathogen update
else
	echo "Pathogen plugin not found in `$pathogen_bin`"
	exit 1
end
