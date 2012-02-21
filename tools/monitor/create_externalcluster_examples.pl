use Data::Dumper;
use 'Administrator';
use 'Entity::ServiceProvider::Outside::Externalcluster';
use 'Entity::Connector::ActiveDirectory';
use 'Entity::Connector::Scom';

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    
my $cluster = Entity::ServiceProvider::Outside::Externalcluster->new(
    externalcluster_name => "vw_cluster",
    );
        
#    my @clusters = Entity::ServiceProvider::Outside::Externalcluster->search(hash => {externalcluster_name => "vWorkspace"});
#    my $cluster = pop @clusters;
    
my $ad_connector = Entity::Connector::ActiveDirectory->new(
    ad_host => "WIN-09DSUKS61DT",
    ad_user => 'administrator@hedera.forest',
    ad_pwd  => 'H3d3r4#234',
    ad_nodes_base_dn => "cn=Computers,dc=hedera,dc=forest"
    );
    
$cluster->addConnector(connector => $ad_connector);

my $scom_connector = Entity::Connector::Scom->new(
    scom_ms_name => "WIN-09DSUKS61DT.hedera.forest",
    );
    
$cluster->addConnector(connector => $scom_connector);
        
$cluster->updateNodes();
    
my $nodes = $cluster->getNodes();
    
print Dumper $nodes;

