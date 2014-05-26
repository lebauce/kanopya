use strict;
use warnings;

=pod
=begin classdoc

Persistent class for database migrations.

This is just a data holder for the name.

Copyright © 2014 Hedera Technology SAS

@see <package>DatabaseMigration::Transient</package> for the full functionality.

=end classdoc
=cut

package DatabaseMigration;

use parent 'BaseDB';

use constant ATTR_DEF => {
    name => {
        pattern      => '^.+$',
        is_mandatory => 1,
        is_extended  => 0
    }
};

sub getAttrDef {
    return ATTR_DEF;
}

sub methods { 
    return {};        
}

=pod
=begin classdoc

@constructor

@param name String The name of this migration.

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;
    General::checkParams(args     => \%args,
                         required => [ 'name' ]);
    return $class->SUPER::new(name => $args{name});
}

1;