#!/usr/bin/perl -W

#    Copyright © 2011 Hedera Technology SAS
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

use lib qw(/opt/kanopya/scripts/install);

use Kanopya::Database;
use PopulateDB;

# Catch warnings to clean the setup output (this warnings are not kanopya code related)
$SIG{__WARN__} = sub {
    my $warn_msg = $_[0];
};

my %args = ();

login();

$args{db} = Kanopya::Database::schema;

registerClassTypes(%args);
registerUsers(%args);

1;
