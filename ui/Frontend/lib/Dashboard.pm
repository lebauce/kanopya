package Dashboard;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;

use Entity::Cluster;
use Entity::Component;

use Log::Log4perl "get_logger";

get '/dashboard' => sub {
    my $admin_components  = adminComponentsDef();
    my $components = Entity::Component->getComponentsByCategory();

    my @components_status = ();

    foreach my $group_count (@{$admin_components}) {
        my @res_group_count = ();
        foreach my $def (@{$group_count}) {
            my @details = ();
            my $up_count         = 0;
            my $services_count   = 0;
            foreach my $serv (@{$def->{comps}}) {
                my $status = getStatus({ proc_name => $serv->{name} });
                $up_count++ if ( $status eq 'Up' );
                $services_count++;
                push @details, {
                    name   => $serv->{name},
                    label  => $serv->{label},
                    status => $status
                };
            }
            push @res_group_count, {
                id      => $def->{id},
                label   => $def->{label},
                details => \@details,
                status  => ( $services_count > 0 && $up_count == $services_count
                    ? 'Up'
                    : ( $up_count > 0 ? 'Broken' : 'Down') )
            };
        }
        push  @components_status, { group_count => \@res_group_count };
    }

    template 'dashboard', {
        title_page        => 'Dashboard',
        components_status => \@components_status,
    };
};

=head1 adminComponentsDef

Only returns a structure classifying admin services by category.

=cut

sub adminComponentsDef {
    return [
        [{
            id    => 'Database',
            label => 'Database server',
            comps => [{
                label => 'mysql',
                name  => 'mysql'}
            ]},
        {
            id    => 'Boot',
            label => 'Boot server',
            comps => [{
                label => 'ntpd',
                name  => 'ntpd'
            },
            {
                label => 'dhcpd',
                name  => 'dhcpd'
            },
            {
                label => 'atftpd',
                name  => 'atftpd'
            }]
          },],
          [{
              id    => 'Harddisk',
              label => 'NAS server',
              comps => [{
                  label => 'ietd',
                  name  => 'ietd'
              },
              {
                  label => 'nfsd',
                  name  => 'nfsd'
              },
              {
                  label => 'mountd',
                  name  => 'rpc.mountd'
              },
              {
                  label => 'statd',
                  name  => 'rpc.statd'
              }]
          },
          {
              id    => 'Execute',
              label => 'Executor',
              comps => [{
                  label => 'executor',
                  name  => 'kanopya-executor'
              },
              {
                  label => 'state-manager',
                  name  => 'kanopya-state-manager'
              }]
          },],
          [{
              id    => 'Monitor',
              label => 'Monitor',
              comps => [{
                  label => 'collector',
                  name  => 'kanopya-collector'
              },
              {
                  label => 'grapher',
                  name  => 'kanopya-grapher'
              }]
          },
          {
              id    => 'Orchestrator',
              label => 'Orchestrator',
              comps => [{
                  label => 'orchestrator',
                  name  => 'kanopya-orchestrator'
              }]
          },]
    ];
}

=head1 getStatus

Use inverse quote to execute a pidof, and know the status

=cut

sub getStatus {
    my ( $args ) = @_;

    my $status  = `pidof $args->{proc_name}` ? 'Up' : 'Down';

    return $status;
}

1;
