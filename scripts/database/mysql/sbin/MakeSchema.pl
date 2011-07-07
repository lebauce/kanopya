# MakeSchema.pl This file allows to generate/update ORM modules
#    Copyright © 2011 Hedera Technology SAS
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
# Created 14 july 2010
use DBIx::Class::Schema::Loader qw/ make_schema_at /;

use lib '/opt/kanopya/lib/administrator';

  make_schema_at(
      'AdministratorDB::Schema',
      { debug => 1,
        dump_directory => '/opt/kanopya/lib/administrator',
	overwrite_modifications => 1,
      },
      [ 'dbi:mysql:administrator:localhost:3306', 'root', 'Hedera@123'],
  );

