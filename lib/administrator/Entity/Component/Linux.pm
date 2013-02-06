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
use Entity::Component::Linux::LinuxMount;
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
    return 10;
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
            Entity::Component::Linux::LinuxMount->new(linux_id => $self->id, %$mtdef);
        }
    }
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    my $conf = $self->getConf();
    my $nfs;
    my $str = "";
    my $definition = "class {'linux': sourcepath => \"" .
                     $args{cluster}->cluster_name . '/' . $args{host}->host_hostname .
                     "\",}\n";

    # /etc/fstab et mounts
    foreach my $mount (@{$conf->{linuxes_mount}}) {
        $str .= "file {'$mount->{linux_mount_point}': ensure => directory }\n";
        $str .= "mount {'$mount->{linux_mount_point}':\n";
        $str .= "\tdevice => '$mount->{linux_mount_device}',\n";
        $str .= "\tensure => mounted,\n";
        $str .= "\tfstype => '$mount->{linux_mount_filesystem}',\n";
        $str .= "\tname   => '$mount->{linux_mount_point}',\n";
        $str .= "\toptions => '$mount->{linux_mount_options}',\n";
        $str .= "\tdump   => '$mount->{linux_mount_dumpfreq}',\n";
        $str .= "\tpass   => '$mount->{linux_mount_passnum}',\n";
        $str .= "\trequire => File['$mount->{linux_mount_point}']\n";
        $str .= "}\n";

        $nfs = $nfs || ($mount->{linux_mount_filesystem} eq "nfs");
    }

    if ($nfs) {
        $definition .= "class { 'nfs': }\n";
    }

    return $definition . $str;
}

1;
