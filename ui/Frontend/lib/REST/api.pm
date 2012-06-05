package REST::api;

use Dancer ':syntax';
use Dancer::Plugin::REST;

prefix undef;

use General;
use Entity;
use Operation;
use Workflow;

my $API_VERSION = "0.1";

prepare_serializer_for_format;

my %resources = (
    "activedirectory"          => "Entity::Connector::ActiveDirectory",
    "atftpd0"                  => "Entity::Component::Atftpd0",
    "apache2"                  => "Entity::Component::Apache2",
    "cluster"                  => "Entity::ServiceProvider::Inside::Cluster",
    "component"                => "Entity::Component",
    "connector"                => "Entity::Connector",
    "connectortype"            => "ConnectorType",
    "container"                => "Entity::Container",
    "containeraccess"          => "Entity::ContainerAccess",
    "entity"                   => "Entity",
    "entitycomment"            => "EntityComment",
    "externalcluster"          => "Entity::ServiceProvider::Outside::Externalcluster",
    "externalnode"             => "Externalnode",
    "filecontaineraccess"      => "Entity::ContainerAccess::FileContainerAccess",
    "fileimagemanager0"        => "Entity::Component::Fileimagemanager0",
    "gp"                       => "Entity::Gp",
    "haproxy1"                 => "Entity::Component::HAProxy1",
    "host"                     => "Entity::Host",
    "hostmodel"                => "Entity::Hostmodel",
    "iface"                    => "Entity::Iface",
    "infrastructure"           => "Entity::Infrastructure",
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
    "lvm2"                     => "Entity::Component::Lvm2",
    "lvmcontainer"             => "Entity::Container::LvmContainer",
    "managerparam"             => "Entity::ManagerParameter",
    "masterimage"              => "Entity::Masterimage",
    "memcached1"               => "Entity::Component::Memcached1",
    "message"                  => "Message",
    "mounttable1"              => "Entity::Component::Mounttable1",
    "mysql5"                   => "Entity::Component::Mysql5",
    "netapp"                   => "Entity::ServiceProvider::Outside::Netapp",
    "netappaggregate"          => "Entity::NetappAggregate",
    "netapplun"                => "Entity::Container::NetappLun",
    "netapplunmanager"         => "Entity::Connector::NetappLunManager",
    "netappvolume"             => "Entity::Container::NetappVolume",
    "netappvolumemanager"      => "Entity::Container::NetappVolumeManager",
    "network"                  => "Entity::Network",
    "nfscontaineraccessclient" => "Entity::NfsContainerAccessClient",
    "nfscontaineraccess"       => "Entity::ContainerAccess::NfsContainerAccess",
    "nfsd3"                    => "Entity::Component::Nfsd3",
    "node"                     => "Node",
    "openiscsi2"               => "Entity::Component::Openiscsi2",
    "opennebula3"              => "Entity::Component::Opennebula3",
    "permission"               => "Permissions",
    "php5"                     => "Entity::Component::Php5",
    "physicalhoster0"          => "Entity::Component::Physicalhoster0",
    "pleskpanel10"             => "Entity::ParallelsProduct::Pleskpanel10",
    "poolip"                   => "Entity::Poolip",
    "powersupplycard"          => "Entity::Powersupplycard",
    "powersupplycardmodel"     => "Entity::Powersupplycardmodel",
    "processormodel"           => "Entity::Processormodel",
    "puppetagent2"             => "Entity::Component::Puppetagent2",
    "puppetmaster2"            => "Entity::Component::Puppetmaster2",
    "openldap1"                => "Entity::Component::Openldap1",
    "openssh5"                 => "Entity::Component::Openssh5",
    "operation"                => "Operation",
    "outside"                  => "Entity::ServiceProvider::Outside",
    "scom"                     => "Entity::Connector::Scom",
    "scope"                    => "Scope",
    "scopeparameter"           => "ScopeParameter",
    "snmpd5"                   => "Entity::Component::Snmpd5",
    "serviceprovider"          => "Entity::ServiceProvider",
    "syslogng3"                => "Entity::Component::Syslogng3",
    "systemimage"              => "Entity::Systemimage",
    "tier"                     => "Entity::Tier",
    "ucsmanager"               => "Entity::Connector::UcsManager",
    "unifiedcomputingsystem"   => "Entity::ServiceProvider::Outside::UnifiedComputingSystem",
    "user"                     => "Entity::User",
    "vlan"                     => "Entity::Network::Vlan",
    "workflow"                 => "Workflow",
    "workflowdef"              => "WorkflowDef",
    "mockmonitor"              => "Entity::Connector::MockMonitor",
);

sub db_to_json {
    my $obj = shift;
    my $expand = shift || [];

    my $basedb;
    my $json;
    if ($obj->isa("BaseDB")) {
        $basedb = $obj;
        $json = $obj->toJSON;
    }
    else {
        $basedb = bless { _dbix => $obj }, "BaseDB";
        $json = $basedb->toJSON;
        my %columns = $obj->get_columns;
        for my $key (keys %columns) {
            if (defined $columns{$key}) {
                $json->{$key} = $columns{$key};
            }
        }
    }

    if (defined ($expand) and $expand) {
        for my $key (@$expand) {
            if ($basedb->{_dbix}->result_source->relationship_info($key)->{attrs}->{accessor} eq "multi") {
                my $children = [];
                for my $item ($basedb->{_dbix}->$key) {
                    push @$children, db_to_json($item);
                }
                $json->{$key} = $children;
            }
            else {
                $json->{$key} = db_to_json($basedb->getAttr(name => $key));
            }
        }
    }

    return $json;
}

sub format_results {
    my %args = @_;

    my $objs = [];
    my $class = $args{class};
    my $dataType = $args{dataType} || "";
    my $expand = $args{expand} || [];
    my $table;
    my $result;
    my %params = ();

    delete $args{class};
    delete $args{dataType};
    delete $args{expand};

    $params{page} = $args{page} || 1;
    delete $args{page};

    if (defined $args{rows}) {
        $params{rows} = $args{rows};
        delete $args{rows};
    }

    if (defined $args{order_by}) {
        $params{order_by} = $args{order_by};
        delete $args{order_by};
    }

    foreach my $attr (keys %args) {
        my @filter = split(',', $args{$attr});
        if (scalar (@filter) > 1) {
            my %filter = @filter;
            $args{$attr} = \%filter;
        }
    }

    if ($class->isa("DBIx::Class::ResultSet")) {
        my $results = $class->search_rs(\%args, \%params);
        while (my $obj = $results->next) {
            push @$objs, db_to_json($obj, $expand);
        }

        $result = {
            rows    => $objs,
            page    => $params{page} || 1,
            total   => (defined ($params{page}) or defined ($params{rows})) ?
                            $results->pager->total_entries : $results->count,
            records => scalar @$objs
        };
    }
    else {
        eval {
            require (General::getLocFromClass(entityclass => $class));
        };

        $result = $class->search(hash     => \%args,
                                 dataType => "hash",
                                 %params);

        for my $obj (@{$result->{rows}}) {
            push @$objs, $obj->toJSON();
        }

        $result->{rows} = $objs;
    }

    if ($dataType ne "jqGrid") {
        return $result->{rows};
    } else {
        return $result;
    }
}

sub setupREST {

    foreach my $resource (keys %resources) {
        my $class = $resources{$resource};

        resource "api/$resource" =>
            get    => sub {
                content_type 'application/json';

                require (General::getLocFromClass(entityclass => $class));

                my @expand = defined params->{expand} ? split(',', params->{expand}) : ();
                return to_json( db_to_json($class->get(id => params->{id}),
                                           \@expand) );
            },

            create => sub {
                content_type 'application/json';
                require (General::getLocFromClass(entityclass => $class));

                my $obj = { };
                my $hash = { };
                my $params = params;
                for my $attr (keys %$params) {
                    $hash->{$attr} = params->{$attr};
                }
                eval {
                    my $location = "EOperation::EAdd" . ucfirst($resource) . ".pm";
                    $location =~ s/\:\:/\//g;
                    require $location;
                    $obj = Operation->enqueue(
                        priority => 200,
                        type     => 'Add' . ucfirst($resource),
                        params   => $hash
                    );
                    $obj = Operation->get(id => $obj->getId)->toJSON;
                };
                if ($@) {
                    eval {
                        $obj = $class->new(params)->toJSON();
                    };
                    if ($@) {
                        my $exception = $@;
                        if (Kanopya::Exception::Permission::Denied->caught()) {
                           redirect '/permission_denied';
                        }
                        else {
                            $exception->rethrow();
                        }
                    }
                }

                return to_json($obj);
            },

            delete => sub {
                content_type 'application/json';
                require (General::getLocFromClass(entityclass => $class));

                my $obj = $class->get(id => params->{id});
                $obj->can("remove") ? $obj->remove() : $obj->delete();

                return to_json( { status => "success" } );
            },

            update => sub {
                content_type 'application/json';
                require (General::getLocFromClass(entityclass => $class));

                my $obj = $class->get(id => params->{id});
                my $params = params;
                for my $attr (keys %$params) {
                    if ($attr ne "id") {
                        $obj->setAttr(name  => $attr,
                                      value => params->{$attr});
                    }
                }
                $obj->save();

                return to_json( { status => "success" } );
            };

        get qr{ /api/$resource/([^/]+)/?(.*) }x => sub {
            content_type 'application/json';
            require (General::getLocFromClass(entityclass => $class));

            my ($id, $filters) = splat;
            my $obj = $class->get(id => $id);

            my @filters = split("/", $filters);
            my @objs;
            my $result;

            my %query = params('query');
            my $hash = \%query;

            for my $filter (@filters) {
                my $parent = $obj->{_dbix};

                RELATION:
                while (1) {
                    if ($parent->result_source->has_relationship($filter)) {
                        # TODO: prefetch filter so that we can just bless it
                        # $obj = bless { _dbix => $parent->$filter }, "Entity";

                        if ($parent->result_source->relationship_info($filter)->{attrs}->{accessor} eq "multi") {
                            my @rs = $parent->$filter->search_rs( { } );

                            my $json = format_results(class     => $parent->$filter->search_rs(),
                                                      dataType  => params->{dataType},
                                                      %$hash);

                            return to_json($json);
                        }
                        else {
                            my $dbix = $parent->$filter;

                            $obj = $dbix->has_relationship("class_type") ?
                                       Entity->get(
                                           id => $dbix->get_column(($dbix->result_source->primary_columns)[0])
                                       ) :
                                       $dbix; 

                            my @expand = defined params->{expand} ? split(',', params->{expand}) : ();
                            return to_json(db_to_json($obj, \@expand));
                        }

                        last RELATION;
                    }

                    last if (not $parent->can('parent'));
                    $parent = $parent->parent;
                }
            }
 
            return to_json($obj->toJSON);
        };

        post qr{ /api/$resource/(\d*)/(.*) }x => sub {
            content_type 'application/json';
            require (General::getLocFromClass(entityclass => $class));

            my ($id, $method) = splat;

            my $methods = $class->methods();

            if (not defined $methods->{$method}) {
                throw Kanopya::Exception::NotImplemented(error => "Method not implemented");
            }

            my $obj = $class->get(id => $id);
            my $params = params;
            my $ret = $obj->$method(%$params);

            eval {
                if ($ret->can("toJSON")) {
                    if ($ret->isa("Operation")) {
                        $ret = Operation->get(id => $ret->getId)->toJSON;
                    }
                    elsif ($ret->isa("Workflow")) {
                        $ret = Workflow->get(id => $ret->getId)->toJSON;
                    }
                }
            };

            return to_json($ret, { allow_nonref => 1, convert_blessed => 1, allow_blessed => 1 });
        };

        get '/api/' . $resource . '/?' => sub {
            content_type 'application/json';

            require (General::getLocFromClass(entityclass => $class));

            my $objs = [];
            my $class = $resources{$resource};
            my %query = params('query');
            my %params = (
                hash => \%query,
            );

            my $json = format_results(class     => $class,
                                      dataType  => params->{dataType},
                                      %query);

            return to_json($json);
        }
    }
}

get '/api/attributes/:resource' => sub {
    content_type 'application/json';

    my $class = $resources{params->{resource}};

    require (General::getLocFromClass(entityclass => $class));

    return to_json($class->toJSON(model => 1));
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

