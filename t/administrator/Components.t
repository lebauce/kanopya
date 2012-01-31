#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/component.t.log', layout=>'%F %L %p %m%n'});
use Data::Dumper;

use_ok ('Executor');
use_ok ('Administrator');
use_ok ('Entity::Cluster');
use_ok ('Entity::Component');
use_ok ('Entity::Systemimage');
use_ok ('Entity::Distribution');


eval {
    #BEGIN { $ENV{DBIC_TRACE} = 1 }

    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;
    my $db = $adm->{db};

    $db->txn_begin;

    # Firstly manually insert a system image into database.
    my ($dist, $sysimg);
    lives_ok {
        $dist = Entity::Distribution->new(distribution_name    => 'disttest',
                                          distribution_version => '1');

        $sysimg = Entity::Systemimage->new(systemimage_name => 'test',
                                           systemimage_desc => 'test',
                                           distribution_id  => $dist->getAttr(name => 'distribution_id'));
    } 'Manually add dummy systemimage';

    # Then create a cluster to add components in.
    my @args = ();
    my $executor = new_ok('Executor', \@args, 'Instantiate an executor');

    lives_ok {
        Entity::Cluster->create(
            cluster_name     => "foobar",
            cluster_min_node => "1",
            cluster_max_node => "1",
            cluster_priority => "100",
            cluster_si_location => "diskless",
            cluster_si_access_mode => "ro",
            cluster_si_shared => "0",
            cluster_domainname => "test.org",
            cluster_nameserver => "0.0.0.0",
            cluster_basehostname => "test",
            systemimage_id   => $sysimg->getAttr(name => 'systemimage_id'),
        );
    } 'AddCluster operation enqueue';

    lives_ok { $executor->execnround(run => 1); } 'AddCluster operation execution succeed';

    my ($cluster, $cluster_id);
    lives_ok {
        $cluster = Entity::Cluster->getCluster('hash' => { cluster_name => 'foobar' });
    } 'retrieve cluster via cluster name.';

	lives_ok {
        $cluster_id = $cluster->getAttr(name => 'cluster_id')
    } 'get Attribute cluster_id';

    # Then instanciate component of each type, add then to the cluster.
    my $comp_types_rs = $adm->{db}->resultset('ComponentType')->search();
    while ( my $comp_type = $comp_types_rs->next ) {
        my $comp_name = $comp_type->get_column('component_name');
        my $comp_version = $comp_type->get_column('component_version');

        my $comp_class= "Entity::Component::" . $comp_name . $comp_version;

        use_ok ($comp_class);

        my ($comp_instance, $comp_id, $comp_from_id, $cluster_from_comp);
        lives_ok {
            $comp_instance = $comp_class->new();
            $comp_id = $comp_instance->getAttr(name => 'component_id');
        } $comp_class . ' component instanciation.';

        lives_ok {
            $comp_instance->insertDefaultConfiguration();
        } $comp_class . ' insert default configuration.';

        lives_ok {
            $cluster->addComponent(component => $comp_instance);
        } $comp_class . ' add to cluster.';

        lives_ok {
            $comp_from_id = Entity::Component->getInstance(id => $comp_id);
            $cluster_from_comp = $comp_from_id->getAttr(name => 'cluster_id')
        } $comp_class . ' get instance from id.';

        cmp_ok ($cluster_from_comp, '==', $cluster_id, $comp_class . ' cluster relation id.')
    }

    $db->txn_rollback;
};
if($@) {
    my $error = $@;
    print Dumper $error;
};

