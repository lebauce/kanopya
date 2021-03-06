# EntityComment.pm  

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Hedera Technology sas.

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
# Created 16 july 2010


=pod
=begin classdoc

Base class for EntityComment

=end classdoc
=cut

package EntityComment;
use base "BaseDB";

use strict;
use warnings;

use Kanopya::Exceptions;
use General;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    entity_comment => {
        pattern => '.*',
        is_mandatory => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

1;
