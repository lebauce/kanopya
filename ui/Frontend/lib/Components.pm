package Components;

use Dancer ':syntax';

use Entity::Component;
use Entity::Cluster;
use Operation;

use Log::Log4perl "get_logger";

prefix '/systems';

my $log = get_logger("webui");

get '/components' => sub {
    my $components = Entity::Component->getComponentsByCategory();
    template 'components', {
        title_page       => 'Systems - Components',
        eid              => session('EID'),
        components_list  => $components,
        object           => vars->{adm_object}
    };
};

get '/components/upload' => sub {
    template 'form_uploadcomponent', {}, { layout => ''};
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
        redirect '/components';
    }
};

1;
