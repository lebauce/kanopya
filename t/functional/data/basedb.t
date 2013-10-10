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
    file   => 'basedb.log',
    layout => '%F %L %p %m%n'
});
my $log = get_logger("");

my $testing = 1;

use BaseDB;
use Kanopya::Database;
use General;
use Entity;
use Entity::User;
use Entity::Host;
use Entity::Policy::HostingPolicy;
use Lvm2Vg;
use Entity::Component::Physicalhoster0;
use ClassType;
use ClassType::DataModelType;


Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    test_component_inner_classes();
    test_concrete_class_without_table();
    test_get_many_to_many();
    test_search_on_virtual_attributes();

    test_process_attributes();
    test_new_and_update();
    test_dbix();
    test_promote_demote();

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}


sub test_promote_demote {
    # Search on component inner classes

    my $classtype = ClassType::DataModelType->find(
                        hash => { class_type => "Entity::DataModel::AnalyticRegression::LinearRegression" }
                    );

    lives_ok {
        my $demoted = ClassType->demote(demoted => $classtype);

        if (ref($demoted) ne "ClassType") {
            die "Promoted object $demoted should be of type <ClassType>";
        }
    } 'Demote ClassType::DataModelType to ClassType';

    $classtype = ClassType->find(
                     hash => { class_type => "Entity::DataModel::AnalyticRegression::LinearRegression" }
                 );

    lives_ok {
        my $promoted = ClassType::DataModelType->promote(
                           promoted                    => $classtype,
                           data_model_type_label       => "--",
                           data_model_type_description => "___",
                       );

        if (ref($promoted) ne "ClassType::DataModelType") {
            die "Promoted object $promoted should be of type <ClassType::DataModelType>";
        }
    } 'Promote ClassType to ClassType::DataModelType';

    my $host = Node->find()->host;
    my $sp   = Entity::ServiceProvider::Cluster->find();

    throws_ok {
        Entity->demote(demoted => $host);
    } 'Kanopya::Exception::DB', 'Demote a Entity::Host to Entity with remaning node';

    lives_ok {
        # Firstly delete the node
        $host->node->delete();

        Entity->demote(demoted => $host);

        if (! $host->isa('Entity')) {
            die "Demoted host should be an Entity, not <$host>";
        }
        elsif ($host->isa('Entity::Host')) {
            die "Demoted host should be an Entity, not <$host>";
        }
        elsif ($host->class_type->class_type ne 'Entity') {
            die "Demoted host should have class type Entity, not <" . $host->class_type->class_type . ">";
        }
    } 'Demote a Entity::Host to Entity';

    lives_ok {
        $host = Entity::Host->promote(promoted           => $host,
                                      host_core          => 1,
                                      host_manager_id    => Entity::Component::Physicalhoster0->find()->id,
                                      host_ram           => 1024,
                                      host_serial_number => "abcd");

        if (! $host->isa('Entity::Host')) {
            die "Promoted host should be an Entity::Host, not <$host>";
        }
        elsif ($host->class_type->class_type ne 'Entity::Host') {
            die "Promoted host should have class type Entity::Host, not <" . $host->class_type->class_type . ">";
        }
    } 'Promote a Entity to Entity::Host';
}


sub test_dbix {
    # Search on component inner classes

    my $host = Entity::Host->find();
    my $sp   = Entity::ServiceProvider::Cluster->find();

    throws_ok {
        my $dbix = $host->_dbixParent(classname => "NotExists");
    } 'Kanopya::Exception::Internal', 'Try to get parent dbix at non existant level of the hierarchy';

    lives_ok {
        for my $level ($host->_classHierarchy) {
            my $dbixclass = ref($host->_dbixParent(classname => $level));
            if (BaseDB->_className(class => $dbixclass) ne $level) {
                die "Requested dbix at level <$level> has wrong class type <$dbixclass>"
            }
        }
    } 'Get parent dbix at each level of the hierarchy for Entity::Host';

    lives_ok {
        for my $level ($sp->_classHierarchy) {
            my $dbixclass = ref($sp->_dbixParent(classname => $level));
            if (BaseDB->_className(class => $dbixclass) ne $level) {
                die "Requested dbix at level <$level> has wrong class type <$dbixclass>"
            }
        }
    } 'Get parent dbix at each level of the hierarchy for Entity::ServiceProvider::Cluster';
    
    my $host_to_delete = Entity::Host->new(host_manager_id    => Entity::Component::Physicalhoster0->find()->id,
                                           host_serial_number => "1",
                                           host_core          => 1,
                                           host_ram           => 1024);

    my $host_to_trunc = Entity::Host->new(host_manager_id    => Entity::Component::Physicalhoster0->find()->id,
                                          host_serial_number => "1",
                                          host_core          => 1,
                                          host_ram           => 1024);

    throws_ok {
        my $id = $host_to_delete->id;
        $host_to_delete->delete();

        Entity::Host->get(id => $id);
    } 'Kanopya::Exception::Internal::NotFound', 'Remove a host and try to get it.';

    lives_ok {
        $host_to_trunc->delete(trunc => "Entity::Host");

        if (BaseDB->_className(class => ref($host_to_trunc->_dbix)) ne "Host") {
            die "Instance dbix class type should be Entity after truncate, not <" . BaseDB->_className(class => ref($host_to_trunc->_dbix)) . ">"
        }
    } 'Truncate a Entity::Host to Entity, and check the truncated the resulting class';

    lives_ok {
        $host_to_trunc->delete(trunc => "Entity");

        if (BaseDB->_className(class => ref($host_to_trunc->_dbix)) ne "Entity") {
            die "Instance dbix class type should be Entity after truncate, not <" . BaseDB->_className(class => ref($host_to_trunc->_dbix)) . ">"
        }
    } 'Truncate a Entity::Host to Entity, and check the truncated the resulting class';
}

sub test_new_and_update {
    # Search on component inner classes

    my $class = "Entity::Host";
    throws_ok {
        $class->new();
    } 'Kanopya::Exception::Internal::IncorrectParam', 'Create Entity::Host with empty attributes';

    my $attrs = {
        host_manager_id    => Entity::Component::Physicalhoster0->find()->id,
        host_serial_number => "1",
        host_core          => 1,
        host_ram           => 1024
    };

    lives_ok {
        $class->new(%$attrs);
    } 'Create Entity::Host with proper attributes';

    my $hostmanager = Entity::Component::Physicalhoster0->find();
    $attrs = {
        host_manager       => $hostmanager,
        host_serial_number => "1",
        host_core          => 1,
        host_ram           => 1024
    };

    lives_ok {
        my $host = $class->new(%$attrs);
    } 'Create Entity::Host with host_manager relation as object';

    $attrs = {
        host_manager_id    => $hostmanager->id,
        host_serial_number => "1",
        host_core          => 1,
        host_ram           => 1024,
        comment            => 'test_comment'
    };

    my $host;
    lives_ok {
        $host = $class->new(%$attrs);
        if ($host->comment ne 'test_comment') {
            die "Virtual attrbiute comment has not been set."
        }
    } 'Create Entity::Host with editable virtual attribute <comment>';

    lives_ok {
        $host->update(host_core => 2);
        if ($host->host_core != 2) {
            die "Attribute host_core has not been updated."
        }
    } 'Update Entity::Host attributes';

    lives_ok {
        $host->update(host_core => 4, class_type_id => 1);
        if ($host->host_core != 2 && $host->class_type->id != 1) {
            die "Attribute host_core and class_type_id has not been updated."
        }
    } 'Update Entity::Host attributes from diferent hierarchy levels';

    throws_ok {
        $host->update(host_manager_id => undef);
    } 'Kanopya::Exception::Internal::WrongValue', 'Update Entity::Host with undefined mandatory attr';

    lives_ok {
        $host->update(comment => 'test_comment_updated');
        if ($host->comment ne 'test_comment_updated') {
            die "Virtual attrbiute comment has not been updated."
        }
    } 'Update Entity::Host with editable virtual attribute <comment>';
}


sub test_process_attributes {
    # Search on component inner classes

    my $class = "Entity::Host";
    throws_ok {
        $class->checkAttributes(attrs => {});
    } 'Kanopya::Exception::Internal::IncorrectParam', 'Process empty attributes for Entity::Host';

    my $attrs = {
        host_manager_id    => Entity::Component::Physicalhoster0->find()->id,
        host_serial_number => "1",
        host_core          => 1,
        host_ram           => 1024
    };

    lives_ok {
        $class->checkAttributes(attrs => $attrs);
    } 'Process proper attributes for Entity::Host';

    $attrs->{host_ram} = 'test';
    throws_ok {
        $class->checkAttributes(attrs => $attrs);
    } 'Kanopya::Exception::Internal::WrongValue', 'Process wrong value in attributes for Entity::Host';

    $attrs->{test} = 'test';
    throws_ok {
        $class->checkAttributes(attrs => $attrs);
    } 'Kanopya::Exception::Internal::IncorrectParam', 'Process incorrect attribute for Entity::Host';

    my $hostmanager = Entity::Component::Physicalhoster0->find();
    $attrs = {
        host_manager       => $hostmanager,
        host_serial_number => "1",
        host_core          => 1,
        host_ram           => 1024
    };

    lives_ok {
       my $hierarchy = $class->checkAttributes(attrs => $attrs);

       if (! defined $hierarchy->{host}->{host_manager_id} || $hierarchy->{host}->{host_manager_id} ne $hostmanager->id) {
           die "Relation attribute <host_manager> has not been precessed as <host_manager_id>"
       }
    } 'Process proper attributes for Entity::Host with host_manager relation as object';
}


sub test_component_inner_classes {
    # Search on component inner classes

    lives_ok {
        for my $innnerclass (Lvm2Vg->search()) {
            if (not $innnerclass->isa("Lvm2Vg")) {
               throw Kanopya::Exception::Internal(
                         error => "Search on component inner class Lvm2Vg return wrong object type $innnerclass"
                     );
            }
        }
    } 'Search on component inner classes';
}

sub test_concrete_class_without_table {
    # Search on concrete classes without tables

    lives_ok {
        for my $hostingpolicy (Entity::Policy::HostingPolicy->search()) {
            if (not $hostingpolicy->isa("Entity::Policy::HostingPolicy")) {
               throw Kanopya::Exception::Internal(
                         error => "Search on concrete policy return wrong policy type $hostingpolicy"
                     );
            }
        }
    } 'Search on concrete classes without tables';
}

sub test_get_many_to_many {
    # Test comparison operators for strings
    my $iface = Entity::Iface->find();
    lives_ok {
        my @netconfs = $iface->netconfs;
        if (scalar(@netconfs) && ! defined $netconfs[0]) {
            die "Netconfs array should have defined values.";
        }

    } 'Get the <netconfs> many to many relation values on iface from many_to_many link';

    lives_ok {
        my @netconf_ifaces = $iface->netconf_ifaces;
        if (scalar(@netconf_ifaces) && ! defined $netconf_ifaces[0]) {
            die "Netconf_ifecs array should have defined values.";
        }

    } 'Get the <netconfs> many to many relation values on iface without many_to_many link';

    my $host = Entity::Host->find();
    lives_ok {
        my @components = $host->node->components;
        if (! scalar(@components)) {
            die "Components array should have values.";
        }
        for my $comp (@components) {
            if (! defined $comp) {
                die "Components array should have defined values only";
            }
        }
    } 'Get the <components> many to many relation values on node from many_to_many link';

    # TODO: The following code should work but not...
    #       Can't call method "priority" on an undefined value at basedb.t line 377.       

#    $host = Entity::Host->find();
#    lives_ok {
#        my @components = sort { $a->component->priority <=> $b->component->priority } $host->node->component_nodes;
#    } 'Get the <components> many to many relation values on node without many_to_many link';

}


sub test_search_on_virtual_attributes {
    # Test comparison operators for strings
    my $ip = Entity::Host->find()->admin_ip;
    throws_ok {
        Entity::Host->find(hash => { admin_ip => '0.0.0.0' });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no hosts for virtual attribute admin_ip = 0.0.0.0';

    lives_ok {
        Entity::Host->find(hash => { admin_ip => $ip });
    } 'Search return one host for virtual attribute admin_ip => ' . $ip;

    throws_ok {
        Entity::Host->find(hash => { admin_ip => { '<>' => $ip } });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no hosts for virtual attribute admin_ip <> ' . $ip;

    lives_ok {
        Entity::Host->find(hash => { admin_ip => { '<>' => '0.0.0.0' } });
    } 'Search return one host for virtual attribute admin_ip <> 0.0.0.0';

    lives_ok {
        Entity::Host->find(hash => { admin_ip => { '>' => '0.0.0.0' } });
    } 'Search return one host for virtual attribute admin_ip > 0.0.0.0';

    lives_ok {
        Entity::Host->find(hash => { admin_ip => { '>=' => '0.0.0.0' } });
    } 'Search return one host for virtual attribute admin_ip >= 0.0.0.0';

    throws_ok {
        Entity::Host->find(hash => { admin_ip => { '<' => 10 } });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no hosts for virtual attribute admin_ip < 0.0.0.0';

    throws_ok {
        Entity::Host->find(hash => { admin_ip => { '<=' => 10 } });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no hosts for virtual attribute admin_ip <= 0.0.0.0';

    lives_ok {
        Entity::Host->find(hash => { admin_ip => { '>=' => $ip } });
    } 'Search return one host for virtual attribute admin_ip >= ' . $ip;

    lives_ok {
        Entity::Host->find(hash => { admin_ip => { '<=' => $ip } });
    } 'Search return one host for virtual attribute admin_ip <= ' . $ip;

    my @splited = split (/\./, $ip);
    my $begin = $splited[0];
    my $end = $splited[3];

    lives_ok {
        Entity::Host->find(hash => { admin_ip => { 'LIKE' => $begin . '%' } });
    } 'Search return one host for virtual attribute admin_ip LIKE ' . $begin . '%';

    throws_ok {
        Entity::Host->find(hash => { admin_ip => { 'LIKE' => '9999999999%' } });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no hosts for virtual attribute LIKE 9999999999%';

    lives_ok {
        Entity::Host->find(hash => { admin_ip => { 'LIKE' =>  '%' . $end } });
    } 'Search return one host for virtual attribute admin_ip LIKE %' . $end;

    throws_ok {
        Entity::Host->find(hash => { admin_ip => { 'LIKE' => '%9999999999' } });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no hosts for virtual attribute LIKE %9999999999';

    throws_ok {
        Entity::Host->find(hash => { admin_ip => { 'NOT LIKE' => $begin . '%' } });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no hosts for virtual attribute NOT LIKE ' . $begin . '%';

    throws_ok {
        Entity::Host->find(hash => { admin_ip => { 'NOT LIKE' => '%' . $end } });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no hosts for virtual attribute NOT LIKE %' . $end;

    lives_ok {
        Entity::Host->find(hash => { admin_ip => { 'NOT LIKE' =>  '%999999999' } });
    } 'Search return one host for virtual attribute admin_ip NOT LIKE %99999999';

    lives_ok {
        Entity::Host->find(hash => { admin_ip => { 'NOT LIKE' =>  '999999999%' } });
    } 'Search return one host for virtual attribute admin_ip NOT LIKE 99999999%';

    # Test comparison operators for int
    my $component = Entity::Component::Physicalhoster0->find();
    my $priority  = $component->priority;
    my $higherpriority = $priority + 100;
    my $lowerpriority  = $priority - 1;

    throws_ok {
        Entity::Component->find(hash => { priority => $higherpriority });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no component for virtual attribute priority = ' . $higherpriority;

    lives_ok {
        Entity::Component->find(hash => { priority => $priority });
    } 'Search return one component for virtual attribute priority = ' . $priority;

    lives_ok {
        Entity::Component->find(hash => { priority => { '<>' => $higherpriority } });
    } 'Search return one component for virtual attribute priority = ' . $priority;

    lives_ok {
        Entity::Component->find(hash => { priority => { '<' => $higherpriority } });
    } 'Search return one component for virtual attribute priority < ' . $higherpriority;

    lives_ok {
        Entity::Component->find(hash => { priority => { '<=' => $higherpriority } });
    } 'Search return one component for virtual attribute priority <= ' . $higherpriority;

    throws_ok {
        Entity::Component->find(hash => { priority => { '>' => $higherpriority } });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no component for virtual attribute priority > ' . $higherpriority;

    throws_ok {
        Entity::Component->find(hash => { priority => { '>=' => $higherpriority } });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no component for virtual attribute priority >= ' . $higherpriority;
}

