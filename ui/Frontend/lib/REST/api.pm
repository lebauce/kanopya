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

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

my $API_VERSION = "0.1";

prepare_serializer_for_format;

my %resources = (
    "activedirectory"          => "Entity::Connector::ActiveDirectory",
    "alert"                    => "Alert",
    "aggregator"               => "Aggregator",
    "atftpd0"                  => "Entity::Component::Atftpd0",
    "aggregatecombination"     => "Entity::Combination::AggregateCombination",
    "aggregatecondition"       => "Entity::AggregateCondition",
    "aggregaterule"            => "Entity::AggregateRule",
    "apache2"                  => "Entity::Component::Apache2",
    "apache2virtualhost"       => "Entity::Component::Apache2::Apache2Virtualhost",
    "billinglimit"             => "Entity::Billinglimit",
    "classtype"                => "ClassType",
    "cluster"                  => "Entity::ServiceProvider::Inside::Cluster",
    "clustermetric"            => "Entity::Clustermetric",
    "collectorindicator"       => "Entity::CollectorIndicator",
    "combination"              => "Entity::Combination",
    "component"                => "Entity::Component",
    "componenttype"            => "ComponentType",
    "connector"                => "Entity::Connector",
    "connectortype"            => "ConnectorType",
    "container"                => "Entity::Container",
    "containeraccess"          => "Entity::ContainerAccess",
    "customer"                 => "Entity::User::Customer",
    "dashboard"                => "Dashboard",
    "debian"                   => "Entity::Component::Debian",
    "entity"                   => "Entity",
    "entitycomment"            => "EntityComment",
    "entityright"              => "Entityright",
    "externalcluster"          => "Entity::ServiceProvider::Outside::Externalcluster",
    "externalnode"             => "Externalnode",
    "filecontaineraccess"      => "Entity::ContainerAccess::FileContainerAccess",
    "fileimagemanager0"        => "Entity::Component::Fileimagemanager0",
    "gp"                       => "Entity::Gp",
    "haproxy1"                 => "Entity::Component::HAProxy1",
    "host"                     => "Entity::Host",
    "hostmodel"                => "Entity::Hostmodel",
    "hypervisor"               => "Entity::Host::Hypervisor",
    "iface"                    => "Entity::Iface",
    "indicator"                => "Entity::Indicator",
    "indicatorset"             => "Indicatorset",
    "interface"                => "Entity::Interface",
    "interfacerole"            => "Entity::InterfaceRole",
    "inside"                   => "Entity::ServiceProvider::Inside",
    "ip"                       => "Ip",
    "iptables1"                => "Entity::Component::Iptables1",
    "iscsicontaineraccess"     => "Entity::ContainerAccess::IscsiContainerAccess",
    "iscsitarget1"             => "Entity::Component::Iscsitarget1",
    "kanopyacollector1"        => "Entity::Component::Kanopyacollector1",
    "keepalived1"              => "Entity::Component::Keepalived1",
    "kernel"                   => "Entity::Kernel",
    "linux"                    => "Entity::Component::Linux",
    "linuxmount"               => "Entity::Component::Linux::LinuxMount",
    "lvm2vg"                   => "Entity::Component::Lvm2::Lvm2Vg",
    "lvm2"                     => "Entity::Component::Lvm2",
    "lvmcontainer"             => "Entity::Container::LvmContainer",
    "mailnotifier0"            => "Entity::Component::Mailnotifier0",
    "managerparam"             => "Entity::ManagerParameter",
    "masterimage"              => "Entity::Masterimage",
    "memcached1"               => "Entity::Component::Memcached1",
    "message"                  => "Message",
    "mockmonitor"              => "Entity::Connector::MockMonitor",
    "mounttable1"              => "Entity::Component::Mounttable1",
    "mysql5"                   => "Entity::Component::Mysql5",
    "netapp"                   => "Entity::ServiceProvider::Outside::Netapp",
    "netappaggregate"          => "Entity::NetappAggregate",
    "netapplun"                => "Entity::Container::NetappLun",
    "netapplunmanager"         => "Entity::Connector::NetappLunManager",
    "netappvolume"             => "Entity::Container::NetappVolume",
    "netappvolumemanager"      => "Entity::Connector::NetappVolumeManager",
    "netconf"                  => "Entity::Netconf",
    "network"                  => "Entity::Network",
    "nfscontaineraccessclient" => "Entity::NfsContainerAccessClient",
    "nfscontaineraccess"       => "Entity::ContainerAccess::NfsContainerAccess",
    "nfsd3"                    => "Entity::Component::Nfsd3",
    "nodemetriccombination"    => "Entity::Combination::NodemetricCombination",
    "nodemetriccondition"      => "Entity::NodemetricCondition",
    "nodemetricrule"           => "Entity::NodemetricRule",
    "node"                     => "Externalnode::Node",
    "notificationsubscription" => "NotificationSubscription",
    "openiscsi2"               => "Entity::Component::Openiscsi2",
    "openldap1"                => "Entity::Component::Openldap1",
    "opennebula3"              => "Entity::Component::Opennebula3",
    "opennebula3repository"    => "Opennebula3Repository",
    "opennebula3hypervisor"    => "Opennebula3Hypervisor",
    "openssh5"                 => "Entity::Component::Openssh5",
    "operation"                => "Entity::Operation",
    "operationtype"            => "Operationtype",
    "orchestrator"             => "Orchestrator",
    "outside"                  => "Entity::ServiceProvider::Outside",
    "parampreset"              => "ParamPreset",
    "permission"               => "Permissions",
    "php5"                     => "Entity::Component::Php5",
    "physicalhoster0"          => "Entity::Component::Physicalhoster0",
    "pleskpanel10"             => "Entity::ParallelsProduct::Pleskpanel10",
    "policy"                   => "Entity::Policy",
    "poolip"                   => "Entity::Poolip",
    "processormodel"           => "Entity::Processormodel",
    "profile"                  => "Profile",
    "puppetagent2"             => "Entity::Component::Puppetagent2",
    "puppetmaster2"            => "Entity::Component::Puppetmaster2",
    "quota"                    => "Quota",
    "redhat"                   => "Entity::Component::Redhat",
    "sco"                      => "Entity::Connector::Sco",
    "scom"                     => "Entity::Connector::Scom",
    "scope"                    => "Scope",
    "scopeparameter"           => "ScopeParameter",
    "snmpd5"                   => "Entity::Component::Snmpd5",
    "serviceprovider"          => "Entity::ServiceProvider",
    "serviceprovidermanager"   => "ServiceProviderManager",
    "servicetemplate"          => "Entity::ServiceTemplate",
    "suse"                     => "Entity::Component::Suse",
    "syslogng3"                => "Entity::Component::Syslogng3",
    "systemimage"              => "Entity::Systemimage",
    "ucsmanager"               => "Entity::Connector::UcsManager",
    "unifiedcomputingsystem"   => "Entity::ServiceProvider::Outside::UnifiedComputingSystem",
    "user"                     => "Entity::User",
    "userextension"            => "UserExtension",
    "userprofile"              => "UserProfile",
    "vlan"                     => "Entity::Network::Vlan",
    "vsphere5"                 => "Entity::Component::Vsphere5",
    "workflow"                 => "Entity::Workflow",
    "workflowdef"              => "Entity::WorkflowDef",
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

    $rows = (defined ($params{dataType}) && $params{dataType} eq "hash") ?
                $result->{rows} : $result;
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
    } else {
        return $objs;
    }
}

sub jsonify {
    my $var = shift;

    # Jsonify the non scalar only
    if (ref($var) and ref($var) ne "HASH") {
        if ($var->can("toJSON")) {
            if ($var->isa("Entity::Operation")) {
                return Entity::Operation->methodCall(method => 'get', params => { id => $var->id })->toJSON;
            }
            elsif ($var->isa("Entity::Workflow")) {
                return Entity::Workflow->methodCall(method => 'get', params => { id => $var->id })->toJSON;
            } else {
                return $var->toJSON();
            }
        }
    }
    return $var;
}

sub setupREST {

    foreach my $resource (keys %resources) {
        my $class = classFromResource(resource => $resource);

        resource "api/$resource" =>
            get    => sub {
                content_type 'application/json';
                require (General::getLocFromClass(entityclass => $class));

                my @expand = defined params->{expand} ? split(',', params->{expand}) : ();
                my $obj = $class->methodCall(method => 'get', params => { id => params->{id}, prefetch => \@expand });
                return to_json($obj->toJSON(expand => \@expand,
                                            deep   => params->{deep}));
            },

            create => sub {
                content_type 'application/json';
                require (General::getLocFromClass(entityclass => $class));
                my $obj = {};
                my $hash = {};
                my %params = params;
                if (request->content_type && (split(/;/, request->content_type))[0] eq "application/json") {
                    %params = %{from_json(request->body)};
                } else {
                    %params = params;
                }
                $obj = jsonify($class->methodCall(method => 'create', params => \%params));

                return to_json($obj);
            },

            delete => sub {
                content_type 'application/json';
                require (General::getLocFromClass(entityclass => $class));

                my $obj = $class->get(id => params->{id});
                $obj->methodCall(method => 'remove');

                return to_json( { status => "success" } );
            },

            update => sub {
                content_type 'application/json';
                require (General::getLocFromClass(entityclass => $class));

                my %params = params;
                my $obj = $class->get(id => params->{id});
                if (request->content_type && (split(/;/, request->content_type))[0] eq "application/json") {
                    %params = %{from_json(request->body)};
                } else {
                    %params = params;
                }

                $obj->methodCall(method => 'update', params => \%params);

                return to_json( { status => "success" } );
            };

        get qr{ /api/$resource/([^/]+)/?(.*) }x => sub {
            content_type 'application/json';
            require (General::getLocFromClass(entityclass => $class));

            my ($id, $filters) = splat;
            my @filters = split("/", $filters);
            my %params = params;

            return to_json(getResources(resource => $resource,
                                        id       => $id,
                                        query    => \%params,
                                        filters  => \@filters));
        };

        post qr{ /api/$resource/(.*) }x => sub {
            content_type 'application/json';
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

            my $methods = $obj->getMethods();

            if (not defined $methods->{$method}) {
                throw Kanopya::Exception::NotImplemented(error => "Method not implemented");
            }

            my %params;
            if (request->content_type && (split(/;/, request->content_type))[0] eq "application/json") {
                %params = %{from_json(request->body)};
            } else {
                %params = params;
            }

            my $ret = $obj->methodCall(method => $method, params => \%params);

            if (ref($ret) eq "ARRAY") {
                my @jsons;
                for my $elem (@{$ret}) {
                    push @jsons, jsonify($elem);
                }
                $ret = \@jsons;
            } elsif ($ret) {
                $ret = jsonify($ret);
            } else {
                $ret = jsonify({});
            }

            return to_json($ret, { allow_nonref => 1, convert_blessed => 1, allow_blessed => 1 });
        };

        get '/api/' . $resource . '/?' => sub {
            content_type 'application/json';
            require (General::getLocFromClass(entityclass => $class));

            my %params = params;
            return to_json(getResources(resource => $resource,
                                        query    => \%params));
        }
    }
}

get '/api/attributes/:resource' => sub {
    content_type 'application/json';

    my $class = classFromResource(resource => params->{resource});

    require (General::getLocFromClass(entityclass => $class));

    return to_json($class->toJSON(model => 1,
                                  no_relations => params->{no_relations}));
};

get '/api' => sub {
    content_type 'application/json';

    my @resources = keys %resources;

    return to_json({
        version   => $API_VERSION,
        resources => \@resources
    });
};

setupREST;

true;

