package REST::api;

use Dancer ':syntax';
use Dancer::Plugin::REST;
use POSIX qw(ceil);

prefix undef;

use General;
use BaseDB;
use Entity;
use Entity::Operation;
use Entity::Workflow;
use Kanopya::Exceptions;
use Kanopya::Version;

use version;
use Log::Log4perl "get_logger";
use Data::Dumper;
use TryCatch;

my $log = get_logger("");
my $errmsg;

our $API_VERSION = version->declare("0.1");


prepare_serializer_for_format;
set serializer => 'Mutable';

our %resources = (
    "activedirectory"          => "Entity::Component::ActiveDirectory",
    "alert"                    => "Alert",
    "amqp"                     => "Entity::Component::Amqp",
    "aggregatecombination"     => "Entity::Combination::AggregateCombination",
    "aggregatecondition"       => "Entity::AggregateCondition",
    "aggregaterule"            => "Entity::Rule::AggregateRule",
    "apache2"                  => "Entity::Component::Apache2",
    "apache2virtualhost"       => "Apache2Virtualhost",
    "billinglimit"             => "Entity::Billinglimit",
    "billingpolicy"            => "Entity::Policy::BillingPolicy",
    "cinder"                   => "Entity::Component::Openstack::Cinder",
    "classtype"                => "ClassType",
    "cluster"                  => "Entity::ServiceProvider::Cluster",
    "clustermetric"            => "Entity::Clustermetric",
    "collectorindicator"       => "Entity::CollectorIndicator",
    "combination"              => "Entity::Combination",
    "component"                => "Entity::Component",
    "componenttype"            => "ClassType::ComponentType",
    "componenttypecategory"    => "ComponentTypeCategory",
    "container"                => "Entity::Container",
    "containeraccess"          => "Entity::ContainerAccess",
    "customer"                 => "Entity::User::Customer",
    "dashboard"                => "Dashboard",
    "debian"                   => "Entity::Component::Linux::Debian",
    "entity"                   => "Entity",
    "entitycomment"            => "EntityComment",
    "entityright"              => "Entityright",
    "entitytimeperiod"         => "EntityTimePeriod",
    "externalcluster"          => "Entity::ServiceProvider::Externalcluster",
    "filecontaineraccess"      => "Entity::ContainerAccess::FileContainerAccess",
    "fileimagemanager0"        => "Entity::Component::Fileimagemanager0",
    "glance"                   => "Entity::Component::Openstack::Glance",
    "gp"                       => "Entity::Gp",
    "haproxy"                  => "Entity::Component::Haproxy1",
    "haproxy1listen"           => "Haproxy1Listen",
    "harddisk"                 => "Harddisk",
    "host"                     => "Entity::Host",
    "hostingpolicy"            => "Entity::Policy::HostingPolicy",
    "hostmodel"                => "Entity::Hostmodel",
    "hpc7000"                  => "Entity::ServiceProvider::Hpc7000",
    "hpcmanager"               => "Entity::Component::HpcManager",
    "hypervisor"               => "Entity::Host::Hypervisor",
    "iface"                    => "Entity::Iface",
    "indicator"                => "Entity::Indicator",
    "indicatorset"             => "Indicatorset",
    "interface"                => "Entity::Interface",
    "ip"                       => "Ip",
    "ipmicredentials"          => "IpmiCredentials",
    "iscsicontaineraccess"     => "Entity::ContainerAccess::IscsiContainerAccess",
    "iscsi"                    => "Entity::Component::Iscsi",
    "iscsiportal"              => "IscsiPortal",
    "iscsitarget1"             => "Entity::Component::Iscsi::Iscsitarget1",
    "kanopyaaggregator"        => "Entity::Component::KanopyaAggregator",
    "kanopyacollector"         => "Entity::Component::Kanopyacollector1",
    "kanopyaexecutor"          => "Entity::Component::KanopyaExecutor",
    "kanopyafront"             => "Entity::Component::KanopyaFront",
    "kanopyaopenstacksync"     => "Entity::Component::KanopyaOpenstackSync",
    "kanopyamailnotifier"      => "Entity::Component::KanopyaMailNotifier",
    "kanopyarulesengine"       => "Entity::Component::KanopyaRulesEngine",
    "keepalived1"              => "Entity::Component::Keepalived1",
    "keepalived1vrrpinstance"  => "Keepalived1Vrrpinstance",
    "kernel"                   => "Entity::Kernel",
    "keystone"                 => "Entity::Component::Openstack::Keystone",
    "linux"                    => "Entity::Component::Linux",
    "linuxmount"               => "LinuxMount",
    "lvm2vg"                   => "Lvm2Vg",
    "lvm2"                     => "Entity::Component::Lvm2",
    "lvmcontainer"             => "Entity::Container::LvmContainer",
    "managercategory"          => "ComponentCategory::ManagerCategory",
    "masterimage"              => "Entity::Masterimage",
    "memcached1"               => "Entity::Component::Memcached1",
    "message"                  => "Message",
    "mockmonitor"              => "Entity::Component::MockMonitor",
    "mysql5"                   => "Entity::Component::Mysql5",
    "netapp"                   => "Entity::ServiceProvider::Netapp",
    "netappaggregate"          => "Entity::NetappAggregate",
    "netapplun"                => "Entity::Container::NetappLun",
    "netapplunmanager"         => "Entity::Component::NetappLunManager",
    "netappvolume"             => "Entity::Container::NetappVolume",
    "netappvolumemanager"      => "Entity::Component::NetappVolumeManager",
    "netconf"                  => "Entity::Netconf",
    "netconfiface"             => "NetconfIface",
    "netconfinterface"         => "NetconfInterface",
    "netconfpoolip"            => "NetconfPoolip",
    "netconfrole"              => "Entity::NetconfRole",
    "network"                  => "Entity::Network",
    "networkpolicy"            => "Entity::Policy::NetworkPolicy",
    "nfscontaineraccessclient" => "Entity::NfsContainerAccessClient",
    "nfscontaineraccess"       => "Entity::ContainerAccess::NfsContainerAccess",
    "nfsd3"                    => "Entity::Component::Nfsd3",
    "nodemetriccombination"    => "Entity::Combination::NodemetricCombination",
    "nodemetriccondition"      => "Entity::NodemetricCondition",
    "nodemetricrule"           => "Entity::Rule::NodemetricRule",
    "node"                     => "Node",
    "notificationsubscription" => "NotificationSubscription",
    "novacompute"              => "Entity::Component::Vmm::NovaCompute",
    "novacontroller"           => "Entity::Component::Virtualization::NovaController",
    "openiscsi2"               => "Entity::Component::Openiscsi2",
    "opennebula3"              => "Entity::Component::Virtualization::Opennebula3",
    "opennebula3repository"    => "Entity::Repository::Opennebula3Repository",
    "opennebula3hypervisor"    => "Entity::Host::Hypervisor::Opennebula3Hypervisor",
    "opennebula3vm"            => "Entity::Host::VirtualMachine::Opennebula3Vm",
    "openstackrepository"      => "Entity::Repository::OpenstackRepository",
    "openstackhypervisor"      => "Entity::Host::Hypervisor::OpenstackHypervisor",
    "openstackvm"              => "Entity::Host::VirtualMachine::OpenstackVm",
    "openssh5"                 => "Entity::Component::Openssh5",
    "oldoperation"             => "OldOperation",
    "operation"                => "Entity::Operation",
    "operationtype"            => "Operationtype",
    "orchestrationpolicy"      => "Entity::Policy::OrchestrationPolicy",
    "parampreset"              => "ParamPreset",
    "php5"                     => "Entity::Component::Php5",
    "physicalhoster0"          => "Entity::Component::Physicalhoster0",
    "policy"                   => "Entity::Policy",
    "poolip"                   => "Entity::Poolip",
    "processormodel"           => "Entity::Processormodel",
    "profile"                  => "Profile",
    "puppetagent2"             => "Entity::Component::Puppetagent2",
    "puppetmaster2"            => "Entity::Component::Puppetmaster2",
    "neutron"                  => "Entity::Component::Openstack::Neutron",
    "quota"                    => "Quota",
    "redhat"                   => "Entity::Component::Linux::Redhat",
    "repository"               => "Entity::Repository",
    "rule"                     => "Entity::Rule",
    "sco"                      => "Entity::Component::Sco",
    "scom"                     => "Entity::Component::Scom",
    "scope"                    => "Scope",
    "scopeparameter"           => "ScopeParameter",
    "snmpd5"                   => "Entity::Component::Snmpd5",
    "scalabilitypolicy"        => "Entity::Policy::ScalabilityPolicy",
    "serviceprovider"          => "Entity::ServiceProvider",
    "serviceprovidertype"      => "ClassType::ServiceProviderType",
    "serviceprovidermanager"   => "ServiceProviderManager",
    "servicetemplate"          => "Entity::ServiceTemplate",
    "storage"                  => "Entity::Component::Storage",
    "storagepolicy"            => "Entity::Policy::StoragePolicy",
    "suse"                     => "Entity::Component::Linux::Suse",
    "syslogng3"                => "Entity::Component::Syslogng3",
    "systemimage"              => "Entity::Systemimage",
    "systempolicy"             => "Entity::Policy::SystemPolicy",
    "tag"                      => "Entity::Tag",
    "tftpd"                    => "Entity::Component::Tftpd",
    "timeperiod"               => "Entity::TimePeriod",
    "ucsmanager"               => "Entity::Component::UcsManager",
    "unifiedcomputingsystem"   => "Entity::ServiceProvider::UnifiedComputingSystem",
    "user"                     => "Entity::User",
    "userextension"            => "UserExtension",
    "userprofile"              => "UserProfile",
    "virtualmachine"           => "Entity::Host::VirtualMachine",
    "virtualization"           => "Entity::Component::Virtualization",
    "vlan"                     => "Entity::Vlan",
    "vsphere5"                 => "Entity::Component::Virtualization::Vsphere5",
    "vsphere5repository"       => "Entity::Repository::Vsphere5Repository",
    "workflow"                 => "Entity::Workflow",
    "workflowdef"              => "Entity::WorkflowDef",
    "workflowdefrule"          => "WorkflowDefRule",
);

sub classFromResource {
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'resource' ]);

    if (not $resources{$args{resource}}) {
        throw Kanopya::Exception::Internal::UnknownResource(
            error => 'Unknown ressource name: ' . $args{resource}
        );
    }
    return $resources{$args{resource}};
}

sub handleNullParam {
    my $param = shift;
    if (! defined $param || !length($param)) {
        return undef;
    }
    elsif (($param eq "''") or ($param eq "\"\"")) {
        return '';
    }
    else {
        return $param;
    }
}

sub getResources {
    my %args = @_;

    my $objs = [];
    my $table;
    my $result;
    my $rows;
    my %params = ();

    my %query = %{$args{query}};
    my $class = classFromResource(resource => $args{resource});

    delete $query{splat};

    if (defined $query{dataType}) {
        if ($query{dataType} eq "jqGrid") {
            $query{dataType} = "hash";
        }
        $params{dataType} = $query{dataType};
        delete $query{dataType};
    }

    if (defined $query{page}) {
        $params{page} = $query{page};
        delete $query{page};
    }

    if (defined $query{deep}) {
        $params{deep} = $query{deep};
        delete $query{deep};
    }

    if (defined $query{rows}) {
        $params{rows} = $query{rows};
        delete $query{rows};
    }

    if (defined $query{order_by}) {
        $params{order_by} = $query{order_by};
        delete $query{order_by};
    }

    if (defined $query{expand}) {
        my @prefetch = split(',', $query{expand});
        $params{prefetch} = \@prefetch;
        delete $query{expand};
    }
    elsif (not defined $params{prefetch}) {
        $params{prefetch} = [];
    }

    # Handle custom search options
    my @customs = grep { $_ =~ '^custom\.' } keys %query;
    for my $custom (map { s/^custom\.//g; $_; } @customs) {
        if (not defined $params{custom}) {
            $params{custom} = {};
        }
        $params{custom}->{$custom} = delete $query{'custom.' . $custom};
    }

    foreach my $attr (keys %query) {
        my @filter = split(',', $query{$attr}, -1);
        if (scalar (@filter) > 1) {
            $filter[1] = handleNullParam($filter[1]);
            my %filter = @filter;
            $query{$attr} = \%filter;
        }
        else {
            $query{$attr} = handleNullParam($query{$attr});
        }
    }

    eval {
        require (General::getLocFromClass(entityclass => $class));
    };

    if ($args{filters}) {
        $result = $class->searchRelated(id       => $args{id},
                                        filters  => $args{filters},
                                        hash     => \%query,
                                        %params);
    } else {
        $result = $class->search(hash => \%query, %params);
    }

    $rows = (defined ($params{dataType}) && $params{dataType} eq "hash") ? $result->{rows} : $result;
    if (ref $rows eq "ARRAY") {
        for my $obj (@$rows) {
            push @$objs, $obj->toJSON(virtuals => 1,
                                      expand   => $params{prefetch},
                                      deep     => $params{deep});
        }
    }
    else {
        return $result->toJSON(virtuals => 1,
                               expand   => $params{prefetch},
                               deep     => $params{deep});
    }

    if (defined ($params{dataType}) && $params{dataType} eq "hash") {
        $result->{rows} = $objs;
        return $result;
    }
    else {
        return $objs;
    }
}

sub jsonify {
    my ($var, %args) = @_;

    # Jsonify the non scalar only
    if (ref($var) and (ref($var) ne "HASH") and (ref($var) ne "ARRAY")) {
        if ($var->can("toJSON")) {
            my $json;
            if ($var->isa("Entity::Operation")) {
                try {
                    my $e = Entity::Operation->apiCall(method => 'get', params => { id => $var->id });
                    $json = $e->toJSON(%args);
                }
                catch (Kanopya::Exception::Internal::NotFound $err) {
                    # Case happens when calling delete from the api
                    $json = {};
                }
                catch ($err) {
                    $err->rethrow();
                }
            }
            elsif ($var->isa("Entity::Workflow")) {
                try {
                    my $e = Entity::Workflow->apiCall(method => 'get', params => { id => $var->id });
                    $json = $e->toJSON(%args);
                }
                catch (Kanopya::Exception::Internal::NotFound $err) {
                    # Case happens when calling delete from the api
                    $json = {};
                }
                catch ($err) {
                    $err->rethrow();
                }
                return $json;
            }
            else {
                $json = $var->toJSON(%args);
            }
            return $json;
        }
    }
    return $var;
}

sub attributes {
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'resource', 'params' ]);

    my $class = classFromResource(resource => $args{resource});
    require (General::getLocFromClass(entityclass => $class));

    return $class->toJSON(%{ $args{params} });
}

sub setupREST {
    my %args = @_;

    foreach my $resource (keys %resources) {
        my $class = classFromResource(resource => $resource);

        resource "api/$resource" =>
            get    => sub {
                require (General::getLocFromClass(entityclass => $class));

                my @expand = defined params->{expand} ? split(',', params->{expand}) : ();
                my $obj = $class->apiCall(method => 'get', params => { id => params->{id}, prefetch => \@expand });

                return $obj->toJSON(expand => \@expand,
                                    deep => params->{deep});
            },

            create => sub {
                require (General::getLocFromClass(entityclass => $class));
                my $obj = {};
                my $hash = {};
                my %params = params;
                if (request->content_type && (split(/;/, request->content_type))[0] eq "application/json") {
                    %params = %{ from_json(request->body) };
                } else {
                    %params = params;
                }

                return jsonify($class->apiCall(method => 'create', params => \%params));
            },

            delete => sub {
                require (General::getLocFromClass(entityclass => $class));

                my $result = $class->get(id => params->{id})->apiCall(method => 'remove');

                return ref($result) ? jsonify($result) : { status => "success" };
            },

            update => sub {
                require (General::getLocFromClass(entityclass => $class));

                my %params;
                my $obj = $class->get(id => delete params->{id});
                if (request->content_type && (split(/;/, request->content_type))[0] eq "application/json") {
                    %params = %{from_json(request->body)};
                } else {
                    %params = params;
                    delete $params{splat};
                }

                $obj->apiCall(method => 'update', params => \%params);

                return { status => "success" };
            };

        get qr{ /api/$resource/([^/]+)/?(.*) }x => sub {
            require (General::getLocFromClass(entityclass => $class));

            my ($id, $filters) = splat;
            my @filters = split("/", $filters);
            my %params = params;

            return getResources(resource => $resource,
                                id       => $id,
                                query    => \%params,
                                filters  => \@filters);
        };

        post qr{ /api/$resource/(.*) }x => sub {
            require (General::getLocFromClass(entityclass => $class));

            my ($id, $obj, $method);
            my @query = split('/', (splat)[0]);

            if (scalar @query > 1) {
                ($id, $method) =  @query;
                $obj = $class->get(id => $id);
            }
            else {
                $method = $query[0];
                $obj = $class;
            }

            my $methods = $obj->_methodsDefinition;
            my @expand = defined params->{expand} ? split(',', params->{expand}) : ();

            if (not defined $methods->{$method}) {
                throw Kanopya::Exception::NotImplemented(error => "Method not implemented");
            }

            my %params;
            if (request->content_type && (split(/;/, request->content_type))[0] eq "application/json") {
                %params = %{from_json(request->body)};
            } else {
                %params = params;
                delete $params{splat};
            }

            my $ret = $obj->apiCall(method => $method, params => \%params);

            if (ref($ret) eq "ARRAY") {
                my @jsons;
                for my $elem (@{$ret}) {
                    push @jsons, jsonify($elem, expand => \@expand);
                }
                $ret = \@jsons;
            } elsif ($ret) {
                $ret = jsonify($ret, expand => \@expand);
            } else {
                $ret = jsonify({});
            }

            return $ret;
        };

        get '/api/' . $resource . '/?' => sub {
            require (General::getLocFromClass(entityclass => $class));

            my %params = params;

            return getResources(resource => $resource,
                                query    => \%params);
        }
    }
}

options '/api/:resource' => sub {
    my %params = params;
    return attributes(resource => delete $params{resource}, params => \%params);
};

get '/api/attributes/:resource' => sub {
    my %params = params;
    return attributes(resource => delete $params{resource}, params => \%params);
};

post '/api/attributes/:resource' => sub {
    my %params;
    my $resource = delete params->{resource};
    if (request->content_type && (split(/;/, request->content_type))[0] eq "application/json") {
        %params = %{ from_json(request->body) };
    } else {
        %params = params;
    }
    return attributes(resource => $resource, params => \%params);
};

get '/api' => sub {
    my @resources = keys %resources;

    return {
        version     => Kanopya::Version::version,
        api_version => version->parse($API_VERSION)->normal,
        resources   => \@resources
    };
};

setupREST;

true;

