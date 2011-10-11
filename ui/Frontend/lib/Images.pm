package Images;

use Dancer ':syntax';

use Entity::Systemimage;
use Entity::Distribution;

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

get '/images/:imageid' => sub {

    my $activate;
    my $active;
    my $can_setperm; 
    my $can_activate;
    my $can_deactivate;
    my $can_delete; 
    my $can_installcomponent;
    my $distribution;
    my $systemimage_usage;

    my $esystemimage = Entity::Systemimage->get(id => params->{imageid});
    my $methods = $esystemimage->getPerms();
    if($methods->{'setperm'}->{'granted'}) { $can_setperm = 1 }

    
    eval {    
        my $edistro = Entity::Distribution->get(id => $esystemimage->getAttr(name => 'distribution_id'));
        $distribution = $edistro->getAttr(name =>'distribution_name')." ".$edistro->getAttr(name => 'distribution_version');
    };
    if(not $esystemimage->getAttr(name => 'active')) {
        if($methods->{'activate'}->{'granted'}) { $can_activate = 1 }
        if($methods->{'remove'}->{'granted'}) { $can_delete = 1 }
    } else {
        if($methods->{'deactivate'}->{'granted'}) { $can_deactivate = 1 }
        $active = 1;
    }
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
    if(not $methods->{'installcomponent'}->{'granted'}) { $can_installcomponent = 1 }

    template 'images_details', {
        title_page       => "Systems - System image's overview",
        activate         => $activate,              
        can_setperm      => $can_setperm,           
        can_activate     => $can_activate,          
        can_deactivate   => $can_deactivate,        
        can_delete       => $can_delete,            
        can_installcomponent  =>  $can_installcomponent,  
        distribution          => $distribution,          
        systemimage_usage     => $systemimage_usage,     
        systemimage_id => $esystemimage->getAttr(name => 'systemimage_id'),     
        systemimage_name => $esystemimage->getAttr(name => 'systemimage_name'), 
        systemimage_desc => $esystemimage->getAttr(name => 'systemimage_desc'), 
        components_list => $components_list,                                    
        components_count => $nb + 1,                                            
     };
};    

