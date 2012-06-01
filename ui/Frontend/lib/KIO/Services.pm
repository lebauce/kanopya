package Services;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;

use Administrator;
use Entity::ServiceProvider::Outside::Externalcluster;

prefix '/kio';

ajax '/services/:serviceid/nodes/update' => sub {
    content_type 'json';
    my $adm = Administrator->new;                                                                                                                                                                                                              
    my %res;
    my $node_count;

    eval {
        my $cluster = Entity::ServiceProvider::Outside::Externalcluster->get(id => param('serviceid'));
             
        my $rep = $cluster->updateNodes(password => param('password'));
             
        $node_count       = $rep->{node_count};
        my $created_nodes = $rep->{created_nodes};
             
        foreach my $node (@$created_nodes){
            NodemetricRule::setAllRulesUndefForANode(
                cluster_id     => param('serviceid'),
                node_id        => $node->{id},
            );   
        }    
             
    };   
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            $res{redirect} = '/permission_denied';
        }    
        else { $res{msg} = "$exception"; }
    }    
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster successfully update nodes');
        $res{msg} = "$node_count node" . ( $node_count > 1 ? 's' : '') . " retrieved.";
    }    
    
    to_json \%res;
};

1;