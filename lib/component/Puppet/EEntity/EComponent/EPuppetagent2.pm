#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
package EEntity::EComponent::EPuppetagent2;
use base "EEntity::EComponent";

use strict;
use warnings;

use General;
use EEntity;
use Kanopya::Exceptions;

use Template;
use Hash::Merge;
use Log::Log4perl "get_logger";
my $log = get_logger("");

my $merge = Hash::Merge->new('LEFT_PRECEDENT');


sub configureNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'mount_point', 'host' ]);

    if ($self->puppetagent2_mode eq 'kanopya') {
        # create, sign and push a puppet certificate on the image
        $log->info('Puppent agent component configured with kanopya puppet master');
        my $puppetmaster = EEntity->new(entity => $self->getPuppetMaster);

        $puppetmaster->createHostCertificate(
            mount_point => $args{mount_point},
            host_fqdn   => $args{host}->node->fqdn
        );
    }

    # Generation of /etc/default/puppet
    my $conf = $self->getConf();
    my $data = { 
        puppetagent2_bootstart => 'yes',
        puppetagent2_options   => $conf->{puppetagent2_options},
    };
    
    my $file = $self->generateNodeFile(
        host          => $args{host},
        file          => '/etc/default/puppet',
        template_dir  => 'components/puppetagent',
        template_file => 'default_puppet.tt',
        data          => $data,
        mount_point   => $args{mount_point}
    );

    # Generation of puppet.conf
    $data = { 
        puppetagent2_masterserver => $conf->{puppetagent2_masterfqdn},
    };

    $file = $self->generateNodeFile( 
        host          => $args{host},
        file          => '/etc/puppet/puppet.conf',
        template_dir  => 'components/puppetagent',
        template_file => 'puppet.conf.tt',
        data          => $data,
        mount_point   => $args{mount_point}
    );

    $file = $self->generateNodeFile(
        host          => $args{host},
        file          => '/etc/puppet/auth.conf',
        template_dir  => 'components/puppetagent',
        template_file => 'auth.conf.tt',
        data          => $data,
        mount_point   => $args{mount_point}
    );

    $self->addInitScripts(
        mountpoint => $args{mount_point},
        scriptname => 'puppet',
    );
}

sub postStartNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    $self->applyConfiguration(nodes => [ $args{host}->node ]);
}

sub postStopNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    $self->applyConfiguration(nodes => [ $args{host}->node ]);
}

sub stopNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    $log->info('Remove the certificate on the puppet master');
    my $puppetmaster = EEntity->new(entity => $self->getPuppetMaster);
    $puppetmaster->removeHostCertificate(host_fqdn => $args{host}->node->fqdn);
}

sub applyConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         optional => { 'nodes' => $self->getActiveNodes(), 'tags'  => [] });

    my $econtext = EEntity->new(data => $self->getPuppetMaster)->getEContext;

    my $ret = -1;
    my $timeout = 360;
    my @nodes = map { $_->fqdn } @{ $args{nodes} };
    do {
        if ($ret != -1) {
            sleep 5;
            $timeout -= 5;
        }
        $log->info("Configuring node(s) " . join(',', @nodes) . ", tag(s) " . join(',', @{ $args{tags} }));

        my $command = "puppet kick --configtimeout=900 --ignoreschedules --foreground ";
        $command .= "--parallel " . (scalar @nodes);
        map { $command .= " --tag " . $_; } @{ $args{tags} };
        map { $command .= " --host $_" } @nodes;

        $ret = $econtext->execute(command => $command, timeout => 900);
        while ($ret->{stdout} =~ /([\w.\-]+) finished with exit code (\d+)/g) {
            # If the host is down or not reachable, the exit code is 2
            # If the host is already applying manifest, the exit code is 3
            # In both cases, puppet kick returns 3 so we filter the broken hosts
            # and the hosts that have already applied the manifest
            if ($2 != 3) {
                @nodes = grep{ $_ ne $1 } @nodes;
            }
        }
    } while ($timeout > 0 && (scalar @nodes));
}

sub isUp {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    $self->applyConfiguration(nodes => [ $args{node} ]);

    # Build the nodes to reconfigure by browsing the node components and thier dependencies.
    # Sort nodes to reconfigure by corresponding puppetagent component to optimize the number
    # of calls to applyConfiguration.
    # TODO: Need to reconfigure all active nodes of the current node components ?
    my $reconfigure = {};
    for my $component ($args{node}->components) {
        for my $dependency (@{ $component->getDependentComponents}) {
            for my $node (@{ $dependency->getActiveNodes }) {
                my $agent = $node->getComponent(category => "Configurationagent");
                my $entry = { agent      => $agent,
                              nodes      => { $node->id => $node },
                              components => { $component->id => $component } };

                $reconfigure->{$agent->id} = $merge->merge($reconfigure->{$agent->id}, $entry);
            }
        }
    }

    # Reconfigure the required nodes
    for my $toreconfiure (values %{ $reconfigure }) {
        # Build the list of tags from components list
        my @dependentnodes = values $reconfigure->{nodes};
        my @tags = map { 'kanopya::' . lc($_->component_type->component_name) }
                       values $reconfigure->{components};

        # Reconfigure the nodes
        EEntity->new(entity => $toreconfiure->{agent})->applyConfiguration(nodes => \@dependentnodes,
                                                                           tags  => \@tags);
    }

    # Reconfigure the current node if we have reconfigured the dependencies
    if (scalar (keys %{ $reconfigure })) {
        $self->applyConfiguration(nodes => [ $args{node} ]);
    }

    return 1;
}

1;
