package Linux0Mount;
use base 'BaseDB';

use constant ATTR_DEF => {
    linux0_mount_device => {
        label        => 'Device',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    linux0_mount_point => {
        label        => 'Mount point',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    linux0_mount_filesystem => {
        label        => 'Filesystem',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    linux0_mount_options => {
        label        => 'Options',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    linux0_mount_dumpfreq => {
        label        => 'Dump',
        type         => 'string',
        pattern      => '^\d$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    linux0_mount_passnum => {
        label        => 'Pass',
        type         => 'string',
        pattern      => '^\d$',
        is_mandatory => 1,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

1;
