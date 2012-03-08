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
    my $connector = Entity::Connector->get(id => param('instanceid'));
    my $cluster_id = $connector->getAttr(name => 'service_provider_id');
    my $cluster = Entity::ServiceProvider::Outside::Externalcluster->get(id => $cluster_id);
    my $connector_type = $connector->getConnectorType();
    my $template = 'connectors/' . lc($connector_type->{connector_name});
        
    my $config = $connector->getConf();
    _deepEscapeHtml( $config );
    
    my $template_params = $config;
    
    $template_params->{'connector_instance_id'} = param('instanceid');
    $template_params->{'cluster_id'} = $cluster_id;
    $template_params->{'cluster_name'} = $cluster->getAttr(name => 'externalcluster_name');

    template "$template", $template_params;
    
};

get '/connectors/:instanceid/saveconfig' => sub {
    my $connector_id = param('instanceid'); 
    my $connector = Entity::Connector->get( id => $connector_id );
    
    my $conf_str = param('conf'); # stringified conf
    my $conf = from_json( $conf_str );
    
    foreach ('cluster_id', 'connector_name', 'connector_id') { delete $conf->{$_}; }
    
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

1;
