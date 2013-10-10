package Entity::Component::Haproxy1::Haproxy1Listen;
use base "BaseDB";

use strict;
use warnings;

use constant ATTR_DEF => {
    listen_name => {
        label       => 'Listen name',
        type        => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    listen_ip => {
        label       => 'Listen ip',
        type        => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    listen_port => {
        label       => 'Listen port',
        type        => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
        size         => 5
    },
    listen_mode => {
        label       => 'Listen mode',
        type        => 'enum',
        options      => ['tcp','http'],
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    listen_balance => {
        label       => 'Listen balance',
        type        => 'enum',
        options      => ['roundrobin'],
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    listen_component_id => {
        label       => 'Component',
        type        => 'relation',
        relation    => 'single',
        is_mandatory => 1,
        is_editable => 1
    },
    listen_component_port => {
        label       => 'Component port',
        type        => 'integer',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1,
        size         => 5
    },
};

sub getAttrDef { return ATTR_DEF; }

1;
