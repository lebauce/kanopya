package REST::api;

use Dancer ':syntax';
use Dancer::Plugin::REST;

prefix undef;

use General;
use Entity;

prepare_serializer_for_format;

my %resources = ( "host"            => "Entity::Host",
                  "cluster"         => "Entity::ServiceProvider::Inside::Cluster",
                  "user"            => "Entity::User",
                  "masterimage"     => "Entity::Masterimage",
                  "systemimage"     => "Entity::Systemimage",
                  "processormodel"  => "Entity::Processormodel",
                  "hostmodel"       => "Entity::Hostmodel",
                  "permission"      => "Permissions",
                  "operation"       => "Operation",
                  "message"         => "Message",
                  "entity"          => "Entity",
                  "inside"          => "Entity::ServiceProvider::Inside",
                  "externalcluster" => "Entity::ServiceProvider::Outside::Externalcluster",
                  "serviceprovider" => "Entity::ServiceProvider",
                  "vlan"            => "Entity::Network::Vlan" );

sub setupREST {

    foreach my $resource (keys %resources) {
        my $class = $resources{$resource};

        resource "api/$resource" =>
            get    => sub {
                content_type 'application/json';
                return to_json( Entity->get(id => params->{id})->toJSON );
            },

            create => sub {
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
                    Operation->enqueue(
                        priority => 200,
                        type     => 'Add' . ucfirst($resource),
                        params   => $hash
                    );
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
                Entity->get(id => params->{id})->delete();
                return to_json( { response => "ok" } );
            },

            update => sub {
                my $obj = Entity->get(id => params->{id});
                my $params = params;
                for my $attr (keys %$params) {
                    if ($attr ne "id") {
                        $obj->setAttr(name  => $attr,
                                      value => params->{$attr});
                    }
                }
                $obj->save();
            };

        get qr{ /api/$resource/([^/]+)/?(.*) }x => sub {
            content_type 'application/json';

            my ($id, $filters) = splat;
            my $obj = Entity->get(id => $id);

            my @filters = split("/", $filters);
            my @objs;
            my $result;

            for my $filter (@filters) {
                my $parent = $obj->{_dbix};

                RELATION:
                while (1) {
                    if ($parent->result_source->has_relationship($filter)) {
                        # TODO: prefetch filter so that we can just bless it
                        # $obj = bless { _dbix => $parent->$filter }, "Entity";

                        if ($parent->result_source->relationship_info($filter)->{attrs}->{accessor} eq "multi") {
                            my @dbix = $parent->$filter;
                            foreach my $item (@dbix) {
                                my $class = BaseDB::classFromDbix($item);
                                require (General::getLocFromClass(entityclass => $class));
                                $obj = bless { _dbix => $item }, $class;
                                push @objs, $obj->toJSON;
                            }

                            return to_json( \@objs );
                        }
                        else {
                            my $dbix = $parent->$filter;
                            $obj = Entity->get(id => $dbix->get_column(($dbix->result_source->primary_columns)[0]));
                        }

                        last RELATION;
                    }

                    last if (not $parent->can('parent'));
                    $parent = $parent->parent;
                }
            }
 
            return to_json($obj->toJSON);
        };

        get '/api/' . $resource => sub {
            content_type 'application/json';

            require (General::getLocFromClass(entityclass => $class));

            my $objs = [];
            my $class = $resources{$resource};
            my %query = params('query');
            my %params = (
                hash => \%query,
            );

            $params{page} = params->{page} || undef;
            delete $params{hash}->{page};
            
            if (defined params->{rows}) {
                $params{rows} = params->{rows};
                delete $params{hash}->{rows};
            }
            if (defined params->{order_by}) {
                $params{order_by} = params->{order_by};
                delete $params{hash}->{order_by};
            }
            if (defined params->{dataType}) {
                $params{dataType} = params->{dataType};
                delete $params{hash}->{dataType};
            }

            foreach my $attr (keys %{$params{hash}}) {
                my @filter = split(',', $params{hash}->{$attr});
                if (scalar (@filter) > 1) {
                    my %filter = @filter;
                    $params{hash}->{$attr} = \%filter;
                }
            }

            if (defined (params->{dataType}) and params->{dataType} eq "jqGrid") {
                my $result = $class->search(%params);
                for my $obj (@{$result->{rows}}) {
                    push @$objs, $obj->toJSON();
                }

                return to_json( {
                    rows    => $objs,
                    page    => $result->{page} || 1,
                    total   => $result->{total},
                    records => scalar @$objs
                } );
            }
            else {
                for my $obj ($class->search(%params)) {
                    push @$objs, $obj->toJSON();
                }

                return to_json($objs);
            }
        }
    }
}

get '/api/attributes/:resource' => sub {
    content_type 'application/json';

    my $class = $resources{params->{resource}};

    require (General::getLocFromClass(entityclass => $class));

    return to_json($class->toJSON(model => 1));
};

setupREST;

true;

