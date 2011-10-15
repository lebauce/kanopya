package Images;

use Dancer ':syntax';

use Administrator;
use Entity::Systemimage;
use Entity::Distribution;

prefix '/systems';

sub _systemimages {

    my @esystemimages = Entity::Systemimage->getSystemimages(hash => {});
    my $systemimages = [];

    foreach my $s (@esystemimages) {
        my $tmp = {};
        $tmp->{systemimage_id}   = $s->getAttr(name => 'systemimage_id');
        $tmp->{systemimage_name} = $s->getAttr(name => 'systemimage_name');
        $tmp->{systemimage_desc} = $s->getAttr(name => 'systemimage_desc');

        eval {
            my $edistro = Entity::Distribution->get(id => $s->getAttr(name => 'distribution_id'));
            $tmp->{distribution} = $edistro->getAttr(name =>'distribution_name')." ".$edistro->getAttr(name => 'distribution_version');
        };

        $tmp->{active} = $s->getAttr(name => 'active');
        if($tmp->{active}) {
            $tmp->{systemimage_usage} = $s->getAttr(name => 'systemimage_dedicated') ? 'dedicated' : 'shared';
        } else {
            $tmp->{systemimage_usage} = '';
        }
        push (@$systemimages, $tmp);
    }

    return $systemimages;
}

get '/images' => sub {

    my $can_create;
    my $methods = Entity::Systemimage->getPerms();
    if($methods->{'create'}->{'granted'}) { $can_create = 1 }

    my @edistros = Entity::Distribution->getDistributions(hash => {});
    if(not scalar(@edistros)) { $can_create = 0 }

    template 'images', {
        title_page         => 'Systems - System images',
        systemimages_list => _systemimages(),
        can_create         => $can_create,
    };
};

get '/images/add' => sub {
    my @esystemimages = Entity::Systemimage->getSystemimages(hash => {});
    my @edistros = Entity::Distribution->getDistributions(hash => {});
    
    my $systemimage = [];
    foreach my $s (@esystemimages){
        my $tmp = {};
        $tmp->{id} = $s->getAttr(name => 'systemimage_id');
        $tmp->{name} = $s->getAttr(name => 'systemimage_name');
        push (@$systemimage, $tmp); 
    }
    
    my $distro = [];
    foreach my $d (@edistros){
        my $tmp = {};
        $tmp->{id} = $d->getAttr(name => 'distribution_id');
        $tmp->{name} = join(' ',$d->getAttr(name =>'distribution_name'), $d->getAttr(name =>'distribution_version'));
        push (@$distro, $tmp);        
    }
    
    template 'form_addimages', {
        title_page          => 'Systems - System images creation',
        systemimages_list   => $systemimage,
        distributions_list  => $distro
    }, { layout => '' };
};

post '/images/add' => sub {
    my $adm = Administrator->new;
    # system image create from another system image (clone)
    # distribution_id query parameter contains system image source id 
    if(params->{source} eq 'systemimage') {
        eval {
            my $esystemimage = Entity::Systemimage->get(id => params->{systemimage_id});
            $esystemimage->clone(
                systemimage_name => params->{systemimage_name},
                systemimage_desc => params->{systemimage_desc},
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
            $adm->addMessage(from => 'Administrator', level => 'info', content => 'new system image clone adding to execution queue'); 
            redirect '/systems/images';
        }         
         
    } # system image creation from a distribution
    elsif(params->{source} eq 'distribution') {    
        eval {
            my $esystemimage = Entity::Systemimage->new(
                systemimage_name => params->{systemimage_name},
                 systemimage_desc => params->{systemimage_desc},
                 distribution_id => params->{distribution_id}, 
            );        
             $esystemimage->create(); 
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
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'system image activation adding to execution queue'); 
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
    my $adm = Administrator->new;
    my $systemimage_id = params->{imageid};
    my ($edistribution, $esystemimage, $systemimage_components, $distribution_components);
    eval {
        $esystemimage = Entity::Systemimage->get(id => $systemimage_id);
        $systemimage_components = $esystemimage->getInstalledComponents();
        $edistribution = Entity::Distribution->get(id => $esystemimage->getAttr(name => 'distribution_id'));
        $distribution_components = $edistribution->getProvidedComponents();
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
        my $components = []; 
        foreach my $dc  (@$distribution_components) {    
            my $found = 0;
            foreach my $sic (@$systemimage_components) {
                if($sic->{component_id} eq $dc->{component_id}) { $found = 1; }
            }
            if(not $found) { push @$components, $dc; };
        } 
        
        template 'form_installcomponents', {
            title_page          => 'Systems - System images creation',
            systemimage_id   => $systemimage_id,
            systemimage_name => $esystemimage->getAttr(name => 'systemimage_name'),
            components_list  => $components
        }, { layout => '' };
    }
};

post '/images/:imageid/installcomponent' => sub {
    my $adm = Administrator->new;    
    eval {
        my $esystemimage = Entity::Systemimage->get(id => params->{imageid});
        $esystemimage->installComponent(component_id => params->{component_id});
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
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'new component installation added to execution queue'); 
        redirect '/systems/images/'.params->{imageid};
    } 
};

get '/images/:imageid' => sub {

    my $activate;
    my $active;
    my $distribution;
    my $systemimage_usage;

    my $esystemimage = Entity::Systemimage->get(id => param('imageid'));
    my $methods = $esystemimage->getPerms();
   
    eval {    
        my $edistro = Entity::Distribution->get(id => $esystemimage->getAttr(name => 'distribution_id'));
        $distribution = $edistro->getAttr(name =>'distribution_name')." ".$edistro->getAttr(name => 'distribution_version');
    };

    $active = $esystemimage->getAttr(name => 'active');
       
    if($active) {
        $systemimage_usage = $esystemimage->getAttr(name => 'systemimage_dedicated') ? 'dedicated' : 'shared';
    } else {
        $systemimage_usage = '';
    }
    
    my $components_list = $esystemimage->getInstalledComponents();
    my $nb = scalar(@$components_list);
    foreach my $c (@$components_list) {
        delete $c->{component_id};
    }

    template 'images_details', {
        title_page            => "Systems - System image's overview",
        activate              => $activate,
        active                => $active,
        can_setperm           => $methods->{'setperm'}->{'granted'},
        can_activate          => $methods->{'activate'}->{'granted'} && !$active,
        can_deactivate        => $methods->{'deactivate'}->{'granted'} && $active,
        can_delete            => $methods->{'remove'}->{'granted'} && ! $active,
        can_installcomponent  => $methods->{'installcomponent'}->{'granted'} && ! $active,
        distribution          => $distribution,          
        systemimage_usage     => $systemimage_usage,     
        systemimage_id        => param('imageid'),     
        systemimage_name      => $esystemimage->getAttr(name => 'systemimage_name'), 
        systemimage_desc      => $esystemimage->getAttr(name => 'systemimage_desc'), 
        components_list       => $components_list,
        components_count      => $nb + 1,
     };
};
