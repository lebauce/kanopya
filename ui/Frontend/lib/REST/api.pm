package REST::api;

use Dancer ':syntax';
use Dancer::Plugin::REST;

prefix undef;

use General;
use Entity;

prepare_serializer_for_format;

my %resources = ( "host"           => "Entity::Host",
                  "cluster"        => "Entity::ServiceProvider::Inside::Cluster",
                  "user"           => "Entity::User",
                  "masterimage"    => "Entity::Masterimage",
                  "systemimage"    => "Entity::Systemimage",
                  "processormodel" => "Entity::Processormodel",
                  "hostmodel"      => "Entity::Hostmodel",
                  "permission"     => "Permissions",
                  "operation"      => "Operation",
                  "message"        => "Message",
                  "vlan"           => "Entity::Network::Vlan" );

sub setupREST {

    foreach my $resource (keys %resources) {
        resource "api/$resource" =>
            get    => sub {
                content_type 'application/json';
                return to_json( Entity->get(id => params->{id})->toJSON );
            },

            create => sub {
                my $class = $resources{$resource};
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
                         $class->new(params);
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
            },

            delete => sub {
                 Entity->get(id => params->{id})->remove();
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

        get '/api/' . $resource => sub {
            content_type 'application/json';

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

            require (General::getLocFromClass(entityclass => $class));

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

    my $class = $resources{host};

    return to_json($class->toJSON(model => 1));
};

setupREST;

true;

