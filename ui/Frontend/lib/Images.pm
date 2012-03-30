package Images;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;

use Administrator;
use Entity::ServiceProvider;
use Entity::Masterimage;
use Entity::Systemimage;
use General;

prefix '/systems';

# retrieve systemimages list
sub _systemimages {

    my @esystemimages = Entity::Systemimage->getSystemimages(hash => {});
    my $systemimages = [];

    foreach my $s (@esystemimages) {
        my $tmp = {};
        $tmp->{systemimage_id}   = $s->getAttr(name => 'systemimage_id');
        $tmp->{systemimage_name} = $s->getAttr(name => 'systemimage_name');
        $tmp->{systemimage_desc} = $s->getAttr(name => 'systemimage_desc');
        $tmp->{active} = $s->getAttr(name => 'active');
        push (@$systemimages, $tmp);
    }

    return $systemimages;
}

# retrieve data managers
sub _datamanagers {
    my @datamanagers = Entity::ServiceProvider->findManager(category => 'Storage');
    return @datamanagers;
}

# retrieve storage providers list
sub _storage_providers {
    my @storages = _datamanagers();
    my %temp;
    foreach my $s (@storages) {
        $temp{ $s->{service_provider_id} } = 0;
    }
    
    my $sp = [];
    foreach my $id (keys %temp) {
        my $tmp = {};
        my $sp_entity = Entity::ServiceProvider->get(id => $id);
        $tmp->{id} = $id;
        $tmp->{name} = $sp_entity->toString();
        
        push (@$sp, $tmp);
    }
    return $sp;
}


get '/images' => sub {

    my $can_create;
    my $methods = Entity::Systemimage->getPerms();
    if($methods->{'create'}->{'granted'}) { $can_create = 1 }

    my @masterimgs = Entity::Masterimage->getMasterimages(hash => {});
    if(not scalar(@masterimgs)) { $can_create = 0 }

    template 'images', {
        title_page         => 'Systems - System images',
        systemimages_list  => _systemimages(),
        can_create         => $can_create,
    };
};

get '/images/add' => sub {
    my @esystemimages = Entity::Systemimage->getSystemimages(hash => {});
    my @masterimages = Entity::Masterimage->getMasterimages(hash => {});
    
    my $systemimage = [];
    foreach my $s (@esystemimages){
        my $tmp = {};
        $tmp->{id} = $s->getAttr(name => 'systemimage_id');
        $tmp->{name} = $s->getAttr(name => 'systemimage_name');
        push (@$systemimage, $tmp); 
    }
    
    my $masterimgs = [];
    foreach my $d (@masterimages){
        my $tmp = {};
        $tmp->{id} = $d->getAttr(name => 'masterimage_id');
        $tmp->{name} = $d->getAttr(name =>'masterimage_name');
        push (@$masterimgs, $tmp);        
    }
    
    my $storages = _storage_providers();
    
    # disk managers list and parameters is managed by javascript with
    # /images/diskmanagers/:storageid and
    # /images/diskmanagers/:storageid/subform/:diskmanagerid
    
    template 'form_addimages', {
        title_page            => 'Systems - System images creation',
        systemimages_list     => $systemimage,
        masterimages_list     => $masterimgs,
        storageproviders_list => $storages
    }, { layout => '' };
};

post '/images/add' => sub {
    my $adm = Administrator->new;
    # system image create from another system image (clone)
    # masterimage_id query parameter contains system image source id 
    
    my $parameters = params;
    
    # convert input size in bytes
    my $sizeinbyte = General::convertToBytes(
        value => $parameters->{systemimage_size}, 
        units => $parameters->{systemimage_size_unit}
    ); 
    
    delete $parameters->{systemimage_size};
    delete $parameters->{systemimage_size_unit};
    
    my $systemimage_name = $parameters->{systemimage_name};
    delete $parameters->{systemimage_name};
    
    my $systemimage_desc = $parameters->{systemimage_desc};
    delete $parameters->{systemimage_desc};
        
    my $storage_provider_id = $parameters->{storage_provider_id};
    delete $parameters->{storage_provider_id};
    
    my $disk_manager_id = $parameters->{disk_manager_id};
    delete $parameters->{disk_manager_id};
    
    my $source = $parameters->{source};
    delete $parameters->{source};
    
    my $masterimage_id = $parameters->{masterimage_id};
    delete $parameters->{masterimage_id};
    
    my $systemimage_id = $parameters->{systemimage_id};
    delete $parameters->{systemimage_id};
    
    if($source eq 'systemimage') {
        eval {
            my $esystemimage = Entity::Systemimage->get(id => $systemimage_id);
            $esystemimage->clone(
                systemimage_name    => $systemimage_name,
                systemimage_desc    => $systemimage_desc,
                systemimage_size    => $sizeinbyte,
                storage_provider_id => $storage_provider_id,
                disk_manager_id     => $disk_manager_id,
                %$parameters
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
            $adm->addMessage(from    => 'Administrator',
                             level   => 'info',
                             content => 'new system image clone adding to execution queue'); 
            redirect '/systems/images';
        }         
         
    } # system image creation from a masterimage
    elsif($source eq 'masterimage') {    
        eval {
            Entity::Systemimage->create(
                systemimage_name    => $systemimage_name,
                systemimage_desc    => $systemimage_desc,
                systemimage_size    => $sizeinbyte,
                masterimage_id      => $masterimage_id,
                storage_provider_id => $storage_provider_id,
                disk_manager_id     => $disk_manager_id,
                %$parameters
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
            $adm->addMessage(from => 'Administrator', level => 'info', content => 'new system image operation adding to execution queue'); 
            redirect '/systems/images';
        }
    }
};

get '/images/:imageid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $esystemimage = Entity::Systemimage->get(id => params->{imageid});
        $esystemimage->remove();
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
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'system image removing adding to execution queue'); 
        redirect '/systems/images';
    } 
};

get '/images/:imageid/activate' => sub {
    my $adm = Administrator->new;
    eval {
        my $esystemimage = Entity::Systemimage->get(id => params->{imageid});
        $esystemimage->activate();
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
        $adm->addMessage(from    => 'Administrator',
                         level   => 'info',
                         content => 'system image activation adding to execution queue'); 
        redirect '/systems/images/'.params->{imageid};
    } 

};

get '/images/:imageid/deactivate' => sub {
    my $adm = Administrator->new;
    my $esystemimage;
    eval {
        $esystemimage = Entity::Systemimage->get(id => params->{imageid});
        $esystemimage->deactivate();
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
        my $msg = "System Image '".$esystemimage->getAttr(name => 'systemimage_name')."' deactivation enqueued";
        $adm->addMessage(from => 'Administrator', level => 'info', content => $msg); 
        redirect '/systems/images/'.params->{imageid};
    }
};

get '/images/:imageid/installcomponent' => sub {
    #~ my $adm = Administrator->new;
    #~ my $systemimage_id = params->{imageid};
    #~ my ($edistribution, $esystemimage, $systemimage_components, $distribution_components);
    #~ eval {
        #~ $esystemimage = Entity::Systemimage->get(id => $systemimage_id);
        #~ $systemimage_components = $esystemimage->getInstalledComponents();
        #~ $edistribution = Entity::Distribution->get(id => $esystemimage->getAttr(name => 'distribution_id'));
        #~ $distribution_components = $edistribution->getProvidedComponents();
    #~ };
    #~ if($@) {
        #~ my $exception = $@;
        #~ if(Kanopya::Exception::Permission::Denied->caught()) {
            #~ $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            #~ redirect '/permission_denied';    
        #~ }
        #~ else { $exception->rethrow(); }
    #~ }
    #~ else {    
        #~ my $components = []; 
        #~ foreach my $dc  (@$distribution_components) {    
            #~ my $found = 0;
            #~ foreach my $sic (@$systemimage_components) {
                #~ if($sic->{component_type_id} eq $dc->{component_type_id}) { $found = 1; }
            #~ }
            #~ if(not $found) { push @$components, $dc; };
        #~ } 
        #~ 
        #~ template 'form_installcomponents', {
            #~ title_page          => 'Systems - System images creation',
            #~ systemimage_id   => $systemimage_id,
            #~ systemimage_name => $esystemimage->getAttr(name => 'systemimage_name'),
            #~ components_list  => $components
        #~ }, { layout => '' };
    #~ }
};

post '/images/:imageid/installcomponent' => sub {
    #~ my $adm = Administrator->new;    
    #~ eval {
        #~ my $esystemimage = Entity::Systemimage->get(id => params->{imageid});
        #~ $esystemimage->installComponent(component_type_id => params->{component_type_id});
    #~ };
    #~ if($@) {
        #~ my $exception = $@;
        #~ if(Kanopya::Exception::Permission::Denied->caught()) {
            #~ $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            #~ redirect '/permission_denied';    
        #~ }
        #~ else { $exception->rethrow(); }
    #~ }
    #~ else {    
        #~ $adm->addMessage(from => 'Administrator', level => 'info', content => 'new component installation added to execution queue'); 
        #~ redirect '/systems/images/'.params->{imageid};
    #~ } 
};

get '/images/:imageid' => sub {

    my $activate;
    my $active;
    my $systemimage_usage;

    my $esystemimage = Entity::Systemimage->get(id => param('imageid'));
    my $methods = $esystemimage->getPerms();

    $active = $esystemimage->getAttr(name => 'active');
    
    my $components_list = $esystemimage->getInstalledComponents();
    my $nb = scalar(@$components_list);
    foreach my $c (@$components_list) {
        delete $c->{component_type_id};
    }
    
    my $container = $esystemimage->getDevice();
    my $storage = Entity::ServiceProvider->get(id => $container->getAttr(name => 'service_provider_id'));
    my $manager = $storage->getManager(id => $container->getAttr(name => 'disk_manager_id'));

    template 'images_details', {
        title_page            => "Systems - System image's overview",
        activate              => $activate,
        active                => $active,
        can_setperm           => $methods->{'setperm'}->{'granted'},
        can_activate          => $methods->{'activate'}->{'granted'} && !$active,
        can_deactivate        => $methods->{'deactivate'}->{'granted'} && $active,
        can_delete            => $methods->{'remove'}->{'granted'} && ! $active,
        can_installcomponent  => $methods->{'installcomponent'}->{'granted'} && ! $active,
        systemimage_usage     => $systemimage_usage,     
        systemimage_id        => param('imageid'),     
        systemimage_name      => $esystemimage->getAttr(name => 'systemimage_name'), 
        systemimage_desc      => $esystemimage->getAttr(name => 'systemimage_desc'), 
        components_list       => $components_list,
        components_count      => $nb + 1,
        storage_provider_name => $storage->toString(),
        disk_manager_name     => $manager->toString(),
     };
};

get '/images/diskmanagers/:storageid' => sub {
    my $id = param('storageid');
    my $str = '';
    my @managers = _datamanagers();
    foreach my $manager (@managers) {
        if($manager->{service_provider_id} eq $id) {
            $str .= '<option value="'.$manager->{id}.'">'.$manager->{name}.'</option>';
        }
    }
    
    content_type('text/html');
    return $str;
};

get '/images/diskmanagers/:storageid/subform/:diskmanagerid' => sub {
    my $storageid = param('storageid');
    my $managerid = param('diskmanagerid');
    my $sp = Entity::ServiceProvider->get(id => $storageid);
    my $diskmanager = $sp->getManager(id => $managerid);
    if($diskmanager->can('getConf')) {
        my $template;
        if($diskmanager->isa('Entity::Component')) {
            my $componentdetail = $diskmanager->getComponentAttr();
            $template = 'components/'.lc($componentdetail->{component_name}).$componentdetail->{component_version}.'_subform_addimage.tt';
        } elsif($diskmanager->isa('Entity::Connector')) {
            my $connectordetail = $diskmanager->getConnectorType();
            $template = 'connectors/'.lc($connectordetail->{connector_name}).'_subform_addimage.tt';
        }

        my $template_params = {};

        my $config = $diskmanager->getConf();
        content_type('text/html');
        template "$template", $config, {layout => undef};
    } else {
        return 'not yet implemented';
    }
};
