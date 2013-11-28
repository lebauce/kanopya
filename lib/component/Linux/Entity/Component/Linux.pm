#    Copyright © 2011 Hedera Technology SAS
#
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package Entity::Component::Linux;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use LinuxMount;
use Entity::ServiceProvider::Cluster;

use Hash::Merge qw(merge);
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {
    linuxes_mount => {
        label => 'Filesystems mounts',
        type => 'relation',
        relation => 'single_multi',
        is_editable => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub priority {
    return 1;
}

sub getConf {
    my $self = shift;
    my $conf = {};

    my @mountdefs;
    for my $mount ($self->linuxes_mount) {
        push @mountdefs, $mount->toJSON(raw => 1);
    }

    $conf->{linuxes_mount} = \@mountdefs;
    return $conf;
}

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['conf']);

    my $conf = $args{conf};
    my $mountdefs_conf = $conf->{linuxes_mount};

    # for each mount definition , we search it in db for update or deletion
    for my $mount ($self->linuxes_mount) {
        my $found = 0;
        my $mountdef_data;
        my $id = $mount->id;
        foreach my $mountdef_conf (@$mountdefs_conf) {
             if ($mountdef_conf->{linux_mount_id} == $id or
                 $mountdef_conf->{linux_mount_point} eq $mount->linux_mount_point) {
                 $found = 1;
                 $mountdef_conf->{linux_mount_id} = $id;
                 $mountdef_data = $mountdef_conf;
             }
        }
        if ($found) {
            $mount->update(%$mountdef_data);
        } else {
            $mount->delete();
        }
    }
    
    foreach my $mtdef (@$mountdefs_conf) {
        if (not exists $mtdef->{linux_mount_id}) {
            LinuxMount->new(linux_id => $self->id, %$mtdef);
        }
    }
}

sub addMount {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'mountpoint', 'filesystem' ],
                         optional => {
                             dumpfreq => 0,
                             passnum  => 0,
                             device   => 'none',
                             options  => 'defaults'
                         } );

    my $oldconf = $self->getConf();
    my @mountentries = @{$oldconf->{linuxes_mount}};
    push @mountentries, {
        linux_mount_dumpfreq   => $args{dumpfreq},
        linux_mount_filesystem => $args{filesystem},
        linux_mount_point      => $args{mountpoint},
        linux_mount_device     => $args{device},
        linux_mount_options    => $args{options},
        linux_mount_passnum    => $args{passnum},
    };
    $self->setConf(conf => { linuxes_mount => \@mountentries });
}

sub removeMount {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'mountpoint' ]);

    my $oldconf = $self->getConf();
    my @mountentries = @{$oldconf->{linuxes_mount}};
    @mountentries = grep { $_->{linux_mount_point} ne $args{mountpoint} } @mountentries;
    $self->setConf(conf => { linuxes_mount => \@mountentries });
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    my $nfs;
    my $ntp = $self->service_provider->getKanopyaCluster->getComponent(category => 'System');
    my $conf = $self->getConf();
    my $tag = 'kanopya::' . lc($self->component_type->component_name);

    my $manifest = $self->instanciatePuppetResource(
        name => 'kanopya::linux',
        params => {
            sourcepath => $args{cluster}->cluster_name . '/' . $args{host}->node->node_hostname,
            stage => "system",
            tag => $tag
        }
    );

    if (Entity::ServiceProvider::Cluster->getKanopyaCluster->id == $args{cluster}->id) {
        $manifest .= $self->instanciatePuppetResource(
            name => "kanopya::ntp::server",
            params => {
                tag => $tag
            }
        );
    }
    else {
        $manifest .= $self->instanciatePuppetResource(
            name => "kanopya::ntp::client",
            params => {
                server => $ntp->getMasterNode->adminIp,
                tag => $tag
            }
        );
    }

    my @swap_entries = grep { $_->{linux_mount_filesystem} eq 'swap' } @{$conf->{linuxes_mount}};
    my @mount_entries = grep { $_->{linux_mount_filesystem} ne 'swap' } @{$conf->{linuxes_mount}};

    my @except;
    eval {
        my $nfsserver = $args{host}->node->getComponent(name => "Nfsd");
        @except = map {
            $_->container_access_export
        } $nfsserver->container_accesses;
    };

    # /etc/fstab et mounts
    foreach my $mount (@mount_entries) {
        # Avoid NFS'ception when the server tries to access a folder
        # that it is already exporting
        next if (grep { ($_ eq $mount->{linux_mount_device}) &&
                        ($mount->{linux_mount_filesystem} eq "nfs") } @except);

        $manifest .= $self->instanciatePuppetResource(
            resource => "file",
            name => $mount->{linux_mount_point},
            params => {
                ensure => 'directory',
                tag => 'mount'
            }
        );

        $manifest .= $self->instanciatePuppetResource(
            resource => "mount",
            name => $mount->{linux_mount_point},
            require => [ "File['" . $mount->{linux_mount_point} . "']" ],
            params => {
                device => $mount->{linux_mount_device},
                ensure => "mounted",
                fstype => $mount->{linux_mount_filesystem},
                name => $mount->{linux_mount_point},
                options => $mount->{linux_mount_options},
                dump => $mount->{linux_mount_dumpfreq},
                pass => $mount->{linux_mount_passnum},
                tag => $tag
            }
        );

        $nfs = $nfs || ($mount->{linux_mount_filesystem} eq "nfs");
    }

    # TODO find another method to manage swap devices
    # current implementation (with mount resource) accept only one swap entry
    # several entries invalidate the manifest due to name => 'none' repeats

    foreach my $swap (@swap_entries) {
        $manifest .= $self->instanciatePuppetResource(
            resource => 'mount',
            name => $swap->{linux_mount_device},
            params => {
                device => $swap->{linux_mount_device},
                ensure => 'present',
                fstype => 'swap',
                name => 'none',
                options => 'sw',
                dump => 0,
                pass => 0,
                tag => $tag
            }
        );
    }
    
    if (@swap_entries) {
        $manifest .= $self->instanciatePuppetResource(
            resource => 'swap',
            name => 'swap',
            require => [ "Mount['". $swap_entries[0]->{linux_mount_device} . "']" ],
            params => {
                ensure => 'present',
                tag => $tag
            }
        );
    }

    if ($nfs) {
        $manifest .= $self->instanciatePuppetResource(
            name => 'kanopya::nfs',
            params => {
                tag => $tag
            }
        );
    }

    return merge($self->SUPER::getPuppetDefinition(%args), {
        linux => {
            manifest => $manifest
        }
    } );
}

1;
