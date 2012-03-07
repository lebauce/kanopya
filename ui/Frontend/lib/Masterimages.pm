package Masterimages;

use Dancer ':syntax';

use Administrator;
use General;
use Entity::Masterimage;
use Operation;

use Log::Log4perl "get_logger";

prefix '/systems';

my $log = get_logger("webui");

# Obtain every master image object and attribute.

sub _masterimages {
    my @masterimages = Entity::Masterimage->getMasterimages(hash => {});
    my $master_images = [];

    foreach my $m (@masterimages) {
        my $tmp     = {};
        my $methods = $m->getPerms();

        $tmp->{masterimage_id}      = $m->getAttr(name => 'masterimage_id');
        $tmp->{masterimage_name}    = $m->getAttr(name => 'masterimage_name');
        $tmp->{masterimage_os}      = $m->getAttr(name => 'masterimage_os');
        $tmp->{masterimage_desc}    = $m->getAttr(name => 'masterimage_desc');
        $tmp->{'can_setperm'}        = 1 if ( $methods->{'setperm'}->{'granted'} );

        push (@$master_images, $tmp);
    }
    return $master_images;
}

# Master images template.
get '/masterimages' => sub {
    template 'masterimages', {
        title_page         => 'Systems - Master Images',
        masterimages_list => _masterimages(),
    };
};

get '/masterimages/upload' => sub {
    template 'form_uploadmasterimage', {
        title_page         => 'Systems - Master Image upload',
    }, { layout => '' };
};

get '/masterimages/:masterimageid' => sub {
    # Call for Entity components for Distributions details.
    my $masterimage = Entity::Masterimage->get(id => params->{masterimageid});
    my $components_list = $masterimage->getProvidedComponents();
    my $nb = scalar(@$components_list); 
   
    my $methods = $masterimage->getPerms();
    
    my $size = sprintf("%.3f G", General::convertFromBytes(value => $masterimage->getAttr(name => 'masterimage_size'), units => 'G'));
    
    # Ṕass the text and arrays to the Distribution template.
    template 'masterimages_details', {
        title_page       => "Systems - Master image overview",
        masterimage_id   => $masterimage->getAttr(name => 'masterimage_id'),
        masterimage_name => $masterimage->getAttr(name => 'masterimage_name'),
        masterimage_desc => $masterimage->getAttr(name => 'masterimage_desc'),
        masterimage_file => $masterimage->getAttr(name => 'masterimage_file'),
        masterimage_os   => $masterimage->getAttr(name => 'masterimage_os'),
        masterimage_size => $size,
        can_setperm      => $methods->{'setperm'}->{'granted'},
        can_delete       => $methods->{'remove'}->{'granted'},
        components_list  => $components_list,
        components_count => $nb + 1,
    };
};

post '/masterimages/upload' => sub {
    my $adm = Administrator->new;
    my $file = request->uploads->{file};
    my $content  = $file->content;
    my $filename = $file->filename;
    $file->copy_to("/tmp/$filename");
       
    eval {
        Operation->enqueue(
            priority => 200,
            type     => 'DeployMasterimage',
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
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'new master image upload added to execution queue');
        redirect('/systems/masterimages');
    }
};

get '/masterimages/:masterimageid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $masterimage = Entity::Masterimage->get(id => params->{masterimageid});
        $masterimage->remove();
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
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'master image removing adding to execution queue'); 
        redirect '/systems/masterimages';
    } 
};

1;
