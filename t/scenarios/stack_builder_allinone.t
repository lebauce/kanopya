#!/usr/bin/perl -w

=head1 SCOPE

This test follow theses steps :
- Get the stackbuiler component,
- Prepare Kanopya for using it (creates a dedicated user, and add some IP adresses)
- build a stack with it, with topology "All In One",
- Start the stack with it,
- Test existance of Hiera yaml files for password override,
- Test existance of OS API password in NovaController component,
- Extract passwords from Hiera override files
- Test if OS API password from Hiera and NovaController component are the same,
- Test if Hiera send the sames variables as defined in file,
- Test if password are correct on node openrc.sh and nova.conf
- Test connetction to OpenStack API with Kanopya classes
- And finally stop the stack

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;

use Entity::ServiceProvider::Cluster;
use Entity::Network;
use Entity::User::Customer::StackBuilderCustomer;

use OpenStack::API;

use Data::Dumper;

use YAML qw'LoadFile';

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'INFO',
    file   => 'stack_builder_allinone.t.log',
    layout => '%F %L %p %m%n'
});


my $testing = 0;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    ##WorkAround PMS : add another IP address for Kanopya
    my $ip = Entity::Network->find()->network_addr;
    $ip =~ s/\.0$/\.253/;
    `ip addr add $ip/24 dev eth1`;
    $ip =~ s/\.253$/\.254/;
    `ip addr add $ip/24 dev eth1`;

    lives_ok {
        my $masterimage = Kanopya::Tools::Register::registerMasterImage();
    } 'Register master image';

    my $builder;
    lives_ok {
       $builder = Entity::ServiceProvider::Cluster->getKanopyaCluster->getComponent(
                      name => "KanopyaStackBuilder"
                  );
    } 'Get the StackBuilder component';

    my $customer;
    lives_ok {
        $customer = Entity::User::Customer::StackBuilderCustomer->findOrCreate(
            user_login     => 'stack_builder_test',
            user_password  => 'stack_builder_test',
            user_firstname => 'Stack Buil',
            user_lastname  => 'Er test',
            user_email     => 'kpouget@hederatech.com',
        );
    } 'Create a customer stack_builder_test for the owner of the stack';

    my $stack = {
        stack_id => 123,
        services => [
            # Service "PMS Full Controller"
            {
                cpu        => 2,
                ram        => 1073741824,
                components => [
                    {
                        component_type => 'Keystone',
                        conf => {}
                    },
                    {
                        component_type => 'Neutron',
                        conf => {
                            extra => {
                                network => '172.18.42.0/24'
                            }
                        }
                    },
                    {
                        component_type => 'Glance',
                        conf => {
                            extra => {
                                images => {}
                            }
                        }
                    },
                    {
                        component_type => 'Apache',
                        conf => {}
                    },
                    {
                        component_type => 'NovaController',
                        conf => {}
                    },
                    {
                        component_type => 'Cinder',
                        conf => {}
                    },
                    {
                        component_type => 'Lvm',
                        conf => {}
                    },
                    {
                        component_type => 'Amqp',
                        conf => {}
                    },
                    {
                        component_type => 'Mysql',
                        conf => {}
                    },
                ],
            },
            # Service "PMS Compute"
            {
                cpu             => 2,
                ram             => 1073741824,
                cluster_min_node => 2,
                components => [
                    {
                        component_type => 'NovaCompute',
                        conf => {}
                    },
                ],
            },
        ],
        iprange  => Entity::Network->find()->network_addr . "/24"
    };

    my $build_stack;
    lives_ok {
       $build_stack = $builder->buildStack(stack => $stack, owner_id => $customer->id);
       Kanopya::Tools::Execution->executeOne(entity => $build_stack);
    } 'Run workflow BuildStack';

    lives_ok {
        # Find controller cluster, and associed files
        my $controller = Entity::ServiceProvider::Cluster->find(hash => {'service_template.service_name' =>  'PMS AllInOne Controller'});

        my $host = my $fqdn = $controller->getNodeHostname(node_number => 1) . '.';
        $fqdn .= $controller->cluster_domainname;

        my $filename = '/var/lib/kanopya/clusters/override/' . $fqdn . '.yaml';
        if (! -e $filename) {
            throw Kanopya::Exception (error => 'Hiera yaml file for cluster ' . $controller->cluster_name .
                                               ', ' . $filename . ', is not found');
        }

        # Get OS API password
        my $novacontroller = Entity::Component->find(hash => {
                                            'component_type.component_name' => 'NovaController',
                                            'service_provider_id' => $controller->id,
                                        });
        if (!defined $novacontroller->api_password) {
            throw Kanopya::Exception (error => 'API password for cluster' . $controller->cluster_name .
                                               ' is not defined !');
        }

        # Extract some "tests passwords" from Hiera yaml backend
        my $hieravars = LoadFile($filename);

        if ($hieravars->{'kanopya::openstack::keystone::admin_password'} ne $novacontroller->api_password || $hieravars->{'kanopya::openstack::nova::controller::keystone_password'} eq '') {
            throw Kanopya::Exception (error => 'Some variables are badly defined on Hiera files !');
        }

        # Test Hiera variables
        my $hiera = `hiera -c /etc/puppet/hiera.yaml 'kanopya::openstack::keystone::admin_password' 'clientcert=$fqdn' 'host=$host' 'cluster=$controller->cluster_name'`;
        chomp($hiera);
        my $apipass = quotemeta($novacontroller->api_password);
        if ($hiera !~ m/$apipass/) {
            throw Kanopya::Exception (error => 'API password for cluster' . $controller->cluster_name .
                                               ' is not correct on Hiera !'
                                     );
        }

        while ((my $var, my $pass) = each %$hieravars) {
            my $pass = quotemeta($pass);
            $hiera = `hiera -c /etc/puppet/hiera.yaml '$var' 'clientcert=$fqdn' 'host=$host' 'cluster=$controller->cluster_name'`;
            if ($hiera !~ m/$pass/) {
                throw Kanopya::Exception (error => 'Password ' . $var . ' for cluster' . $controller->cluster_name .
                                                   ' is not correct in Hiera !'
                                         )
            }
        }

        # Test somes values on host
        my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster();
        my $kanopyahost = EEntity->new(data =>  @{$kanopya->getHosts()}[0]);
        my $controllerhost = EEntity->new(data =>  @{$controller->getHosts()}[0]);

        ## Needed for build a context out of Executor
        my $context = EContext->new(src_host => $kanopyahost,
                                    dst_host => $controllerhost,
                                    key      => '/var/lib/kanopya/private/kanopya_rsa' );

        my $command = 'grep OS_PASSWORD /root/openrc.sh';
        my $openrcpassword = $context->execute(command => $command);
        if ($openrcpassword->{stdout} !~ m/$apipass/) {
            throw Kanopya::Exception (error => 'API password for cluster' . $controller->cluster_name .
                                               ' is not correct on openrc file');
        }

        $command = 'grep ^admin_password /etc/nova/nova.conf';
        my $novakeystonepassword = $context->execute(command => $command);
        my $novakeystoneonhiera = quotemeta($hieravars->{'kanopya::openstack::nova::controller::keystone_password'});
        if ($novakeystonepassword->{stdout} !~ m/$novakeystoneonhiera/) {
            throw Kanopya::Exception (error => 'Nova password on keystone for cluster' . $controller->cluster_name .
                                               ' is not correct on /etc/nova/nova.conf');
        }

        # Connect to the OpenStack API and try it
        my $apicredentials = {
            auth => {
                passwordCredentials => {
                    username    => 'admin',
                    password    => $apipass,
                },
                tenantName      => "openstack"
            }
        };
    
        my $apiconfig = {
            verify_ssl => 0,
            identity => {
                url     => 'http://'.$fqdn.':5000/v2.0'
            },
        };
    
        my $api = OpenStack::API->new(credentials => $apicredentials,
                                      config      => $apiconfig);

        my $response = $api->endpoints;
        if( ! exists $response->{api}->{config} ||
                ! keys $response->{api}->{config} ) {
                throw Kanopya::Exception::Execution::API(
                        error         => 'Openstack API call returns no endpoints'
                    )
        }


    }

    my $end_stack;
    lives_ok {
       $end_stack = $builder->endStack(stack_id => 123, owner_id => $customer->id);
       Kanopya::Tools::Execution->executeOne(entity => $end_stack);
    } 'Run workflow EndStack';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
