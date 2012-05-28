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
package EEntity::EComponent::ELinux0;
use base 'EEntity::EComponent';

use strict;
use warnings;
use Log::Log4perl 'get_logger';
use Data::Dumper;

my $log = get_logger('executor');
my $errmsg;

# generate configuration files on node
sub addNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['cluster','host','mount_point']);

    $self->generateHostname(%args);
    $self->generateFstab(%args);
    $self->generateResolvconf(%args);
    $self->generateUdevPersistentNetRules(%args);
    
    # TODO recupérer le kanopya domainname
    # depuis la conf ? le cluster kanopya ?
    $self->generateHosts(%args, kanopya_domainname => 'kanopya.localdomain');
    

}

sub generateHostname {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host','mount_point', 'cluster' ]);

    my $hostname = $args{host}->getAttr(name => 'host_hostname');
    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/hostname',
        template_dir  => '/templates/internal',
        template_file => 'hostname.tt',
        data          => { hostname => $hostname }
    );
    
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc'
    );
}

sub generateFstab {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => ['cluster','host','mount_point']);
    
    my $data = $self->_getEntity()->getConf();

    foreach my $row (@{$data->{mountdefs}}) {
        delete $row->{linux0_id};
    }

    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/fstab',
        template_dir  => '/templates/components/linux',
        template_file => 'fstab.tt',
        data          => $data 
    );
          
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc'
    );

    my $automountnfs = 0;
    for my $mountdef (@{$data->{mountdefs}}) {
        my $mountpoint = $mountdef->{linux0_mount_point};
        $self->getExecutorEContext->execute(command => "mkdir -p $args{mount_point}/$mountpoint");
        
        if ($mountdef->{linux0_mount_filesystem} eq 'nfs') {
            $automountnfs = 1;
        }
    }
    
    if ($automountnfs) {
        my $grep_result = $self->getExecutorEContext->execute(
                              command => "grep \"ASYNCMOUNTNFS=no\" $args{mount_point}/etc/default/rcS"
                          );

        if (not $grep_result->{stdout}) {
            $self->getExecutorEContext->execute(
                command => "echo \"ASYNCMOUNTNFS=no\" >> $args{mount_point}/etc/default/rcS"
            );
        }
    }                     
}

sub generateHosts {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster','host','mount_point', 'kanopya_domainname' ]);

    $log->info('Generate /etc/hosts file');

    my $nodes = $args{cluster}->getHosts();
    my @hosts_entries = ();

    # we add each nodes 
    foreach my $node (values %$nodes) {
        my $tmp = { 
            hostname   => $node->getAttr(name => 'host_hostname'),
            domainname => $args{kanopya_domainname},
            ip         => $node->getAdminIp 
        };

        push @hosts_entries, $tmp;
    }

    # we ask components for additional hosts entries
    my $components = $args{cluster}->getComponents(category => 'all');
    foreach my $component (values %$components) {
        my $entries = $component->getHostsEntries();
        if(defined $entries) {
            foreach my $entry (@$entries) {
                push @hosts_entries, $entry;
            }
        }
    }

    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/hosts',
        template_dir  => '/templates/internal',
        template_file => 'hosts.tt',
        data          => { hosts => \@hosts_entries }
    );
    
    $self->getExecutorEContext->send(
        src => $file,
        dest => $args{mount_point}.'/etc/hosts'
    );
}

sub generateResolvconf {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['cluster','host', 'mount_point' ]);

    my @nameservers = ();

    for my $attr ('cluster_nameserver1','cluster_nameserver2') {
        push @nameservers, {
            ipaddress => $args{cluster}->getAttr(name => $attr)
        };
    }

    my $data = {
        domainname => $args{cluster}->getAttr(name => 'cluster_domainname'),
        nameservers => \@nameservers,
    };

    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/resolv.conf',
        template_dir  => '/templates/internal',
        template_file => 'resolv.conf.tt',
        data          => $data
    );
    
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/resolv.conf'
    );
}

sub generateUdevPersistentNetRules {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host','cluster','mount_point' ]);

    my @interfaces = ();
    
    for my $iface ($args{host}->_getEntity()->getIfaces()) {
        my $tmp = {
            mac_address   => lc($iface->getAttr(name => 'iface_mac_addr')),
            net_interface => $iface->getAttr(name => 'iface_name')
        };
        push @interfaces, $tmp;
    }
       
    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/udev/rules.d/70-persistent-net.rules',
        template_dir  => '/templates/internal',
        template_file => 'udev_70-persistent-net.rules.tt',
        data          => { interfaces => \@interfaces }
    );
    
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/udev/rules.d'
    );
}

1;
