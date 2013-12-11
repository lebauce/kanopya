package IpmiCredentials;
use base 'BaseDB';

use strict;
use warnings;
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {
    host_id => {
        pattern      => '^\d+',
        is_delegatee => 1,
        is_mandatory => 1,
    },
    ipmi_credentials_ip_addr => {
       pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
       label        => 'IPMI IP Address',
       is_mandatory => 1,
       is_editable  => 1
    },
    ipmi_credentials_user => {
        pattern      => '^\w*$',
        type         => 'string',
        label        => 'IPMI Username',
        is_mandatory => 1,
        is_editable  => 1
    },
    ipmi_credentials_password => {
        label        => 'Password',
        type         => 'password',
        pattern      => '^.+$',
        is_mandatory => 1,
        is_editable  => 1
    },

};

sub getAttrDef { return ATTR_DEF; }

sub methods { return {}; }

1;
