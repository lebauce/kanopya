package Components;

use Dancer ':syntax';
use Dancer::Plugin::EscapeHTML;

use Entity::Component;
use Entity::ServiceProvider::Inside::Cluster;
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

get '/components' => sub {
    my $components = Entity::Component->getComponentsByCategory();
    template 'component', {
        title_page       => 'Systems - Components',
        eid              => session('EID'),
        components_list  => $components,
        object           => vars->{adm_object}
    };
};

get '/components/upload' => sub {
    template 'form_uploadcomponent', {
			title_page         => 'Systems - Components upload',
	}, { layout => ''};
};

post '/components/upload' => sub {
    my $adm = Administrator->new;
    my $file = request->uploads->{componentfile};
    my $content  = $file->content;
    my $filename = $file->filename;
    $file->copy_to("/tmp/$filename");

    eval {
        Operation->enqueue(
            priority => 200,
            type     => 'DeployComponent',
            params   => { file_path => "/tmp/$filename" },
        );
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'new component upload added to execution queue');
        redirect('/systems/components');
    }
};

get '/components/:instanceid/configure' => sub {
    
    my $component = Entity::Component->getInstance(id=>param('instanceid'));
    my $cluster_id = $component->getAttr(name=>'inside_id');
    my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster_id);
    my $componentdetail = $component->getComponentAttr();
    my $template = 'components/'.lc($componentdetail->{component_name}).$componentdetail->{component_version};
    my $template_params = {};
        
    my $config = $component->getConf();
    _deepEscapeHtml( $config );
    while( my ($key, $value) = each %$config) {
        $template_params->{$key} = $value;    
    }
    
    $template_params->{'component_instance_id'} = param('instanceid');
    $template_params->{'cluster_id'} = $cluster_id;
    $template_params->{'cluster_name'} = $ecluster->getAttr(name => 'cluster_name');

    template "$template", $template_params;
    
};

get '/components/:instanceid/saveconfig' => sub {
    my $component_id = param('instanceid'); 
    my $component = Entity::Component->getInstance(id=>$component_id);
    
    my $conf_str = param('conf'); # stringified conf
    my $conf = from_json( $conf_str );
    
    foreach ('cluster_id', 'component_name', 'component_id') { delete $conf->{$_}; }
    
    my $msg = "conf saved";
    eval {
        $component->setConf($conf);
    };
    if ($@) {
        $msg = "Error while saving:\n $@";
    }

    content_type('text/text');
    return $msg;
};

1;
