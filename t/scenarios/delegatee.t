#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'delegatee.log',
    layout => '%F %L %p %m%n'
});

my $log = get_logger("");

my $testing = 1;

use Kanopya::Database;
use General;

use Node;
use Entity::ServiceProvider;
use Entity::User::Customer;
use Entity::Combination::AggregateCombination;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;

use String::Random;

main();

sub main {
    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    my $rand = new String::Random;
            
    # Create a customer 
    my $customer = Entity::User::Customer->new(
        user_login     => 'customer',
        user_password  => 'customer',
        user_firstname => 'customer',
        user_lastname  => 'customer',
        user_email     => 'customer@customer.cu',
    );
    # Retrieve the admin 
    my $admin = Entity::User->find(hash => { user_login => 'admin' });

    # Create a cluster for the customer
    my $customercluster = Kanopya::Tools::Create->createCluster(user_id => $customer->id);

    # Retrieve a cluster on which the customer do not have any permissions
    my $admincluster = Entity::ServiceProvider::Cluster->find(hash => { user_id => $admin->id });

    ################################################
    # Check permissions on non entity CRUD methods #
    ################################################

    ######## As admin on an admin cluster ##########

    # Firstly loggin in to Admin
    Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

    # Create a node
    my $adminnode;
    lives_ok {
        $adminnode = Node->apiCall(
                         method => 'create',
                         params => {
                             service_provider_id => $admincluster->id,
                             node_hostname       => $rand->randpattern("cccccccc")
                         }
                     );
    } 'Create a node from apiCall as admin';

    # Retreive, update and remove the node
    lives_ok {
        Node->apiCall(method => 'get', params => { id => $adminnode->id });
    } 'Get a node from apiCall as admin';

    lives_ok {
        $adminnode->apiCall(method => 'update', params => { node_hostname => $rand->randpattern("cccccccc") });
    } 'Update the node from apiCall as admin';

    lives_ok {
        $adminnode->apiCall(
            method => 'update',
            params => {
                service_provider_id => $admincluster->id,
                node_hostname       => $rand->randpattern("cccccccc")
            }
        );
    } 'Update the node from apiCall with specifyied service_provider_id (delegatee attr) as admin';

    lives_ok {
        $adminnode->apiCall(method => 'remove', params => { dryrun => 1 });
    } 'Remove the node from apiCall as admin';

    ######## As customer on an admin cluster ##########

    # Then loggin in to customer
    Kanopya::Database::authenticate(login => 'customer', password => 'customer');

    # Create a node
    my $customernode;
    throws_ok {
        $customernode = Node->apiCall(
                            method => 'create',
                            params => {
                                service_provider_id => $admincluster->id,
                                node_hostname       => $rand->randpattern("cccccccc")
                            }
                        );
    } 'Kanopya::Exception::Permission::Denied',
      'Create a node from apiCall as customer';

    # Retreive, update and remove the node
    throws_ok {
        Node->apiCall(method => 'get', params => { id => $adminnode->id });
    } 'Kanopya::Exception::Permission::Denied',
      'Get a node from apiCall as customer';

    throws_ok {
        $adminnode->apiCall(method => 'update', params => { node_hostname => $rand->randpattern("cccccccc") });
    } 'Kanopya::Exception::Permission::Denied',
      'Update the node from apiCall as customer';

    throws_ok {
        $adminnode->apiCall(
            method => 'update',
            params => {
                service_provider_id => $admincluster->id,
                node_hostname       => $rand->randpattern("cccccccc")
            }
        );
    } 'Kanopya::Exception::Permission::Denied',
      'Update the node from apiCall with specifyied service_provider_id (delegatee attr) as customer';

    throws_ok {
        $adminnode->apiCall(method => 'remove', params => { dryrun => 1 });
    } 'Kanopya::Exception::Permission::Denied',
      'Remove the node from apiCall as customer';

    ######## As customer on a customer cluster ##########

    # Create a node
    lives_ok {
        $customernode = Node->apiCall(
                            method => 'create',
                            params => {
                                service_provider_id => $customercluster->id,
                                node_hostname       => $rand->randpattern("cccccccc")
                            }
                        );
    } 'Create a node from apiCall as customer';

    # Retreive, update and remove the node
    lives_ok {
        Node->apiCall(method => 'get', params => { id => $customernode->id });
    } 'Get a node from apiCall as customer';

    lives_ok {
        $customernode->apiCall(method => 'update', params => { node_hostname => $rand->randpattern("cccccccc") });
    } 'Update the node from apiCall as customer';

    throws_ok {
        $customernode->apiCall(
            method => 'update',
            params => {
                service_provider_id => $admincluster->id,
                node_hostname       => $rand->randpattern("cccccccc")
            }
        );
    } 'Kanopya::Exception::Permission::Denied',
      'Update the node from apiCall with specifyied service_provider_id (delegatee attr) as customer';

    lives_ok {
        $customernode->apiCall(method => 'remove', params => { dryrun => 1 });
    } 'Remove the node from apiCall as customer';

    ############################################################
    # Check permissions on entities that delegate CRUD methods #
    ############################################################

    ######## As admin on an admin cluster ##########

    # Firstly loggin in to Admin
    Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

    # Find a Clustermetric
    my $cm = Entity::Clustermetric->find(clustermetric_service_provider_id => $admincluster->id);

    # Create a AggregateCombination
    my $admincombination;
    lives_ok {
        $admincombination = Entity::Combination::AggregateCombination->apiCall(
                                method => 'create',
                                params => {
                                    service_provider_id           => $admincluster->id,
                                    aggregate_combination_formula => 'id'.($cm->id)
                                }
                            );
    } 'Create a AggregateCombination from apiCall as admin';

    # Retreive, update and remove the AggregateCombination
    lives_ok {
        Entity::Combination::AggregateCombination->apiCall(method => 'get', params => { id => $admincombination->id });
    } 'Get a AggregateCombination from apiCall as admin';

    lives_ok {
        Entity::Combination->apiCall(method => 'get', params => { id => $admincombination->id });
    } 'Get a Combination from apiCall as admin';

    lives_ok {
        $admincombination->apiCall(method => 'update');
    } 'Update the AggregateCombination from apiCall as admin';

    lives_ok {
        $admincombination->apiCall(method => 'update', params => { service_provider_id => $admincluster->id });
    } 'Update the AggregateCombination from apiCall with specifyied service_provider_id (delegatee attr) as admin';

    lives_ok {
        $admincombination->apiCall(method => 'remove');
    } 'Remove the AggregateCombination from apiCall as admin';

    lives_ok {
        $admincombination = Entity::Combination::AggregateCombination->apiCall(
                                method => 'create',
                                params => {
                                    service_provider_id           => $admincluster->id,
                                    aggregate_combination_formula => 'id'.($cm->id)
                                }
                            );
    } 'Create a AggregateCombination from apiCall as admin';

    lives_ok {
        $admincombination->apiCall(method => 'getDependencies');
    } 'Call an api method of AggregateCombination from apiCall as admin';

    ######## As customer on an admin cluster ##########

    # Then loggin in to customer
    Kanopya::Database::authenticate(login => 'customer', password => 'customer');

    # Create a AggregateCombination
    my $customercombination;
    throws_ok {
        $customercombination = Entity::Combination::AggregateCombination->apiCall(
                                   method => 'create',
                                   params => {
                                       service_provider_id           => $admincluster->id,
                                       aggregate_combination_formula => 'id'.($cm->id)
                                   }
                               );
    } 'Kanopya::Exception::Permission::Denied',
      'Create a AggregateCombination from apiCall as customer';

    # Retreive, update and remove the AggregateCombination
    throws_ok {
        Entity::Combination::AggregateCombination->apiCall(method => 'get', params => { id => $admincombination->id });
    } 'Kanopya::Exception::Permission::Denied',
      'Get a AggregateCombination from apiCall as customer';

    throws_ok {
        Entity::Combination->apiCall(method => 'get', params => { id => $admincombination->id });
    } 'Kanopya::Exception::Permission::Denied',
      'Get a Combination from apiCall as admin';

    throws_ok {
        $admincombination->apiCall(method => 'update');
    } 'Kanopya::Exception::Permission::Denied',
      'Update the AggregateCombination from apiCall as customer';

    throws_ok {
        $admincombination->apiCall(method => 'update', params => { service_provider_id => $admincluster->id });
    } 'Kanopya::Exception::Permission::Denied',
      'Update the AggregateCombination from apiCall with specifyied service_provider_id (delegatee attr) as customer';

    throws_ok {
        $admincombination->apiCall(method => 'remove');
    } 'Kanopya::Exception::Permission::Denied',
      'Remove the AggregateCombination from apiCall as customer';

    throws_ok {
        $admincombination->apiCall(method => 'getDependencies');
    } 'Kanopya::Exception::Permission::Denied',
      'Call an api method of AggregateCombination from apiCall as customer';

    ######## As customer on a customer cluster ##########

    # Create a AggregateCombination
    my $customercombination;
    lives_ok {
        $customercombination = Entity::Combination::AggregateCombination->apiCall(
                                method => 'create',
                                params => {
                                    service_provider_id           => $customercluster->id,
                                    aggregate_combination_formula => 'id'.($cm->id)
                                }
                            );
    } 'Create a AggregateCombination from apiCall as customer';

    # Retreive, update and remove the AggregateCombination
    lives_ok {
        Entity::Combination::AggregateCombination->apiCall(method => 'get', params => { id => $customercombination->id });
    } 'Get a AggregateCombination from apiCall as customer';

    lives_ok {
        Entity::Combination->apiCall(method => 'get', params => { id => $customercombination->id });
    } 'Get a Combination from apiCall as customer';

    lives_ok {
        $customercombination->apiCall(method => 'update');
    } 'Update the AggregateCombination from apiCall as customer';

    throws_ok {
        $customercombination->apiCall(method => 'update', params => { service_provider_id => $admincluster->id });
    } 'Kanopya::Exception::Permission::Denied',
      'Update the AggregateCombination from apiCall with specifyied service_provider_id (delegatee attr) as customer';

    lives_ok {
        $customercombination->apiCall(method => 'remove');
    } 'Remove the AggregateCombination from apiCall as customer';

    lives_ok {
        $customercombination = Entity::Combination::AggregateCombination->apiCall(
                                method => 'create',
                                params => {
                                    service_provider_id           => $customercluster->id,
                                    aggregate_combination_formula => 'id'.($cm->id)
                                }
                            );
    } 'Create a AggregateCombination from apiCall as customer';

    lives_ok {
        $customercombination->apiCall(method => 'getDependencies');
    } 'Call an api method of AggregateCombination from apiCall as customer';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
