package Distributions;

use Dancer ':syntax';

use Administrator;
use Entity::Distribution;
use Operation;

use Log::Log4perl "get_logger";

prefix '/systems';

my $log = get_logger("webui");

# Obtain every distributions object and attribute.
# After that, send it to distributions template.
sub _distributions {
    my @edistributions = Entity::Distribution->getDistributions(hash => {});
    my $distributions = [];

    foreach my $m (@edistributions) {
        my $tmp     = {};
        my $methods = $m->getPerms();

        $tmp->{distribution_id}      = $m->getAttr(name => 'distribution_id');
        $tmp->{distribution_name}    = $m->getAttr(name => 'distribution_name');
        $tmp->{distribution_version} = $m->getAttr(name => 'distribution_version');
        $tmp->{distribution_desc}    = $m->getAttr(name => 'distribution_desc');
        $tmp->{'can_setperm'}        = 1 if ( $methods->{'setperm'}->{'granted'} );

        push (@$distributions, $tmp);
    }
    return $distributions;
}

# Distributions template.
get '/distributions' => sub {
    template 'distributions', {
        title_page         => 'Systems - Distributions',
        eid                => session('EID'),
        distributions_list => _distributions(),
        object             => vars->{adm_object}
    };
};

get '/distributions/upload' => sub {
    template 'form_uploaddistribution', {
        title_page         => 'Systems - Distributions upload',
        eid                => session('EID'),
        object             => vars->{adm_object}
    };
};

get '/distributions/:distributionid' => sub {
    # Call for Entity components for Distributions details.
    my $edistribution = Entity::Distribution->get(id => params->{distributionid});
    my $components_list = $edistribution->getProvidedComponents();
    my $nb = scalar(@$components_list);

    # Ṕass the text and arrays to the Distribution template.
    template 'distributions_details', {
        title_page            => "Systems - Distribution's overview",
        distribution_id       => $edistribution->getAttr(name => 'distribution_id'),
        distribution_name     => $edistribution->getAttr(name => 'distribution_name'),
        distribution_version  => $edistribution->getAttr(name => 'distribution_version'),
        distribution_desc     => $edistribution->getAttr(name => 'distribution_desc'),
        components_list       => $components_list,
        components_count      => $nb + 1,
    };
};



post '/distributions/upload' => sub {
    my $adm = Administrator->new;
    my $file = request->uploads->{distributionfile};
    my $content  = $file->content;
    my $filename = $file->filename;
    $file->copy_to("/tmp/$filename");
       
    eval {
        Operation->enqueue(
            priority => 200,
            type     => 'DeployDistribution',
            params   => { file_path => "/tmp/$filename" },
        );
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';    
        }
        else { $exception->rethrow(); }
    }
    else {    
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'new distribution upload added to execution queue'); 
        redirect '/distributions';
    }     
};

1;
