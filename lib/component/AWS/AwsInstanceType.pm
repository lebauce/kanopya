#    Copyright © 2014 Hedera Technology SAS
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

package AwsInstanceType;
use base BaseDB;

use strict;
use warnings;

use General;
use Kanopya::Database;

use constant ATTR_DEF => {
    name => {
        label        => 'Instance Type name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 0
    },
    ram => {
        label        => 'Size in bytes',
        type         => 'bigint',
        size         => 17,
        is_mandatory => 1,
        is_editable  => 0
    },
    cpu => {
        label        => 'Number of cores',
        type         => 'integer',
        size         => 3,
        is_mandatory => 1,
        is_editable  => 0
    },
    # In AWS, even if Instance Storage is 0, you can always use EBS storage.
    storage => {
        label        => 'Instance Storage in bytes',
        type         => 'bigint',
        size         => 17,
        is_mandatory => 1,
        is_editable  => 0        
    }
};

# We will have a small number of objects that might get requested several times. So we cache the instances.
my %cache = ();

=pod
=begin classdoc

Class method for getting the instance for the given name. This method uses caching.
Throws an exception if the name is not found.

@param name (String) The Instance Type name.

@return An AwsInstanceType object.

=end classdoc
=cut

sub getType {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'name' ]);
    my $name = $args{name};
    
    if (not defined $cache{$name}) {
        $cache{$name} = $class->find(hash => { name => $name });
    }
    return $cache{$name};
}


sub getAttrDef { return ATTR_DEF; }

=pod
=begin classdoc

Class method for getting all type names.

@return (Arrayref of Strings)

=end classdoc
=cut

sub getAllNames {
    my $dbh = Kanopya::Database::dbh;
    
    my @names = ();
    my $results = $dbh->selectall_arrayref('SELECT name FROM aws_instance_type');
    foreach my $data (@$results) {
        push @names, $data->[0];
    }
    return \@names;
}

1;
