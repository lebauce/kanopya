package Services;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;

use Entity::ServiceProvider::Externalcluster;

prefix '/kio';

# Seem to be DEPRECATRED => TODO check and remove
ajax '/services/:serviceid/nodes/update' => sub {
    content_type 'json';

    my %res;
    my $node_count;

    eval {
        my $cluster = Entity::ServiceProvider::Externalcluster->methodCall(method => 'get', params => { id => param('serviceid') });
             
        my $rep = $cluster->methodCall(method => 'updateNodes', params => { password => param('password') });

        $node_count       = $rep->{node_count};
        my $created_nodes = $rep->{created_nodes};
             
        foreach my $node (@$created_nodes){
            Entity::NodemetricRule::setAllRulesUndefForANode(
                cluster_id     => param('serviceid'),
                node_id        => $node->{id},
            );   
        }    
             
    };   
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
#            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            $res{redirect} = '/permission_denied';
        }    
        else { $res{msg} = "$exception"; }
    }    
    else {
#        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster successfully update nodes');
        $res{msg} = "$node_count node" . ( $node_count > 1 ? 's' : '') . " retrieved.";
    }    
    
    to_json \%res;
};

1;