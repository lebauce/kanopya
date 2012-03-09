package Connectors;

use Dancer ':syntax';
use Dancer::Plugin::EscapeHTML;

use Entity::Connector;
use Entity::ServiceProvider::Outside::Externalcluster;
use Data::Dumper;
use Operation;

use Log::Log4perl "get_logger";

prefix '/systems';

my $log = get_logger("webui");

sub _deepEscapeHtml {
    my $data = shift;
    
    while( my ($key, $value) = each %$data) {
        if (ref $value eq "ARRAY") {
            foreach (@$value) { _deepEscapeHtml( $_ ); }
        } else {
            $data->{$key} = escape_html( $value );
        }
    }
}

get '/connectors/:instanceid/configure' => sub {
    my $connector = Entity::Connector->get( id => param('instanceid') );
    my $serviceprovider_id = $connector->getAttr(name=>'outside_id');
    my $serviceprovider = Entity::ServiceProvider->get(id => $serviceprovider_id);
    my $connector_type = $connector->getConnectorType();
    my $template = 'connectors/'.lc($connector_type->{connector_name});
        
    my $config = $connector->getConf();
    _deepEscapeHtml( $config );
    
    my $template_params = $config;

    $template_params->{'connector_instance_id'} = param('instanceid');
    $template_params->{'serviceprovider_id'} = $serviceprovider_id;
    $template_params->{'serviceprovider_tostring'} = $serviceprovider->toString();

    template "$template", $template_params;
    
};

get '/connectors/:instanceid/saveconfig' => sub {
    my $connector_id = param('instanceid'); 
    my $connector = Entity::Connector->get( id => $connector_id );
    
    my $conf_str = param('conf'); # stringified conf
    my $conf = from_json( $conf_str );
    
    foreach ('serviceprovider_id', 'connector_id') { delete $conf->{$_}; }
    
    my $msg = "conf saved";
    eval {
        $connector->setConf($conf);
    };
    if ($@) {
        $msg = "Error while saving:\n $@";
    }

    content_type('text/text');
    return $msg;
};

get '/connectors/:instanceid/checkconfig' => sub {
    my $connector_id = param('instanceid'); 
    my $connector = Entity::Connector->get( id => $connector_id );
    
    my $conf_str = param('conf'); # stringified conf
    my $conf = from_json( $conf_str );
    foreach ('serviceprovider_id', 'connector_id') { delete $conf->{$_}; }
    
    my $msg;
    eval {
        $msg = $connector->checkConf($conf);
    };
    if ($@) {
        $msg = "Fail for following reason:\n $@";
    }
    my %res = (msg => $msg);
    
    to_json( \%res );
};

1;
