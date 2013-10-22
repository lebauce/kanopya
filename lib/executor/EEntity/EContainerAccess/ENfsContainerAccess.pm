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


=pod
=begin classdoc

Execution class for iscsi container access entities.

=end classdoc
=cut

package EEntity::EContainerAccess::ENfsContainerAccess;
use base "EEntity::EContainerAccess";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");


=pod
=begin classdoc

Mount the remote container acces with mount.nfs.

=end classdoc
=cut

sub mount {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'econtext' ],
                         optional => { 'mountpoint' => $self->getMountPoint } );

    my $target = $self->_entity->getAttr(name => 'container_access_export');
    #my $ip     = $self->_entity->getAttr(name => 'container_access_ip');
    #my $port   = $self->_entity->getAttr(name => 'container_access_port');

    my $mkdir_cmd = "mkdir -p $args{mountpoint}; chmod 777 $args{mountpoint}";
    $args{econtext}->execute(command => $mkdir_cmd);

    my $mount_cmd = "mount.nfs $target $args{mountpoint} -o vers=3";
    my $cmd_res   = $args{econtext}->execute(command => $mount_cmd);

    # Must check return code 32 ("mount failed") as ->{'exitcode'} value changer in Local EContext
    if ($cmd_res->{'stderr'}) { #and ($cmd_res->{'exitcode'} != 32)){
        throw Kanopya::Exception::Execution(
                  error => "Unable to mount $target on $args{mountpoint}: " .
                           $cmd_res->{'stderr'}
              );
    }
    $log->debug("NFS export $target mounted on <$args{mountpoint}>.");

    if (exists $args{erollback} and defined $args{erollback}){
        $args{erollback}->add(
            function   => $self->can('umount'),
            parameters => [ $self, "mountpoint", $args{mountpoint}, "econtext", $args{econtext} ]
        );
    }

    return $args{mountpoint};
}


=pod
=begin classdoc

Not supported, returning undef.

=end classdoc
=cut

sub connect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    #$self->_entity->setAttr(name  => 'device_connected',
    #                           value => '');
    return undef;
}


=pod
=begin classdoc

Not supported, doing nothing.

=end classdoc
=cut

sub disconnect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    #$self->_entity->setAttr(name  => 'device_connected',
    #                           value => '');
    return undef;
}

1;
