package Apache2Virtualhost;
use base 'BaseDB';
use strict;
use warnings;

use constant ATTR_DEF => {
    apache2_virtualhost_servername => {
        label        => 'Server Name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    apache2_virtualhost_sslenable => {
        label        => 'Enable SSL',
        type         => 'boolean',
        is_mandatory => 1,
        is_editable  => 1,
    },
    apache2_virtualhost_serveradmin => {
        label        => 'Email',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    apache2_virtualhost_documentroot => {
        label        => 'Document Root',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    apache2_virtualhost_log => {
        label        => 'Access Log file',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    apache2_virtualhost_errorlog => {
        label        => 'Errors Log file',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

1;
