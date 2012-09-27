package Opennebula3Repository;
use base 'BaseDB';

use constant ATTR_DEF => {
    repository_name => {
        label        => 'Name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    container_access_id => {
        label        => 'Container access',
        type         => 'relation',
        relation     => 'single',
        is_mandatory => 1,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

1;
