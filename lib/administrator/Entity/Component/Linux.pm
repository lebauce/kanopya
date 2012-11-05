# linux.pm - linux component
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 4 sept 2010

=head1 NAME

<Entity::Component::linux> <linux component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::linux> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::linux>;

my $component_instance_id = 2; # component instance id

Entity::Component::linux->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::linux->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::linux is class allowing to instantiate a linux component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Linux;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use LinuxMount;
use Log::Log4perl 'get_logger';

my $log = get_logger("");
my $errmsg;

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
             if($mountdef_conf->{linux_mount_id} == $id) {
                 $found = 1;
                 $mountdef_data = $mountdef_conf;
                 last;
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

# Insert default configuration in db for this component 
sub insertDefaultConfiguration {
    my $self = shift;
    
    my @default_conf = (
        { linux_mount_device => 'proc',
          linux_mount_point => '/proc',
          linux_mount_filesystem => 'proc',
          linux_mount_options => 'nodev,noexec,nosuid',
          linux_mount_dumpfreq => '0',
          linux_mount_passnum => '0'
        },
        { linux_mount_device => 'sysfs',
          linux_mount_point => '/sys',
          linux_mount_filesystem => 'sysfs',
          linux_mount_options => 'defaults',
          linux_mount_dumpfreq => '0',
          linux_mount_passnum => '0'
        },
        { linux_mount_device => 'tmpfs',
          linux_mount_point => '/tmp',
          linux_mount_filesystem => 'tmpfs',
          linux_mount_options => 'defaults',
          linux_mount_dumpfreq => '0',
          linux_mount_passnum => '0'
        },
        { linux_mount_device => 'tmpfs',
          linux_mount_point => '/var/tmp',
          linux_mount_filesystem => 'tmpfs',
          linux_mount_options => 'defaults',
          linux_mount_dumpfreq => '0',
          linux_mount_passnum => '0'
        },
        { linux_mount_device => 'tmpfs',
          linux_mount_point => '/var/run',
          linux_mount_filesystem => 'tmpfs',
          linux_mount_options => 'defaults',
          linux_mount_dumpfreq => '0',
          linux_mount_passnum => '0'
        },
        { linux_mount_device => 'tmpfs',
          linux_mount_point => '/var/lock',
          linux_mount_filesystem => 'tmpfs',
          linux_mount_options => 'defaults',
          linux_mount_dumpfreq => '0',
          linux_mount_passnum => '0'
        },
    );

    foreach my $row (@default_conf) {
        LinuxMount->new(linux_id => $self->id,
                        %$row);
    }
}

sub getPuppetDefinition {
    my ($self, %args) = @_;
    my $conf = $self->getConf();
    
    # /etc/hosts
    my $path = $args{cluster}->getAttr(name => 'cluster_name');
    $path .= '/'.$args{host}->getAttr(name => 'host_hostname');
    my $str = "class {'linux': sourcepath => \"$path\",}\n";  
    
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
    }
    
    return $str;
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;
