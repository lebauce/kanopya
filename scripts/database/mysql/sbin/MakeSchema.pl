# MakeSchema.pl This file allows to generate/update ORM modules
# Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010
use DBIx::Class::Schema::Loader qw/ make_schema_at /;

use lib '/opt/kanopya/lib/administrator';

  make_schema_at(
      'AdministratorDB::Schema',
      { debug => 1,
        dump_directory => '/opt/kanopya/lib/administrator',
        components => '+AdministratorDB::EntityBase',
        #additional_base_classes => '+AdministratorDB::EntityBase',
      },
      [ 'dbi:mysql:administrator:localhost:3306', 'root', 'Hedera@123'],
  );

