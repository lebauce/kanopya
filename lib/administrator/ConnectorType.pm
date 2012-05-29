package     ConnectorType;
use base    'BaseDB';

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger('administrator');

use constant ATTR_DEF => {
  connector_name        => {
    pattern         => '^.*$',
    is_mandatory    => 0,
    is_extended     => 0,
    is_editable     => 0
  },
  connector_version     => {
    pattern         => '^\d*$',
    is_mandatory    => 0,
    is_extended     => 0,
    is_editable     => 0
  },
  connector_category    => {
    pattern         => '^.*$',
    is_mandatory    => 0,
    is_extended     => 0,
    is_editable     => 0
  }
};

sub getAttrDef { return ATTR_DEF; }
