# ECloneSystemimage.pm - Operation class implementing System image cloning operation

#    Copyright © 2010-2012 Hedera Technology SAS
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

=head1 NAME

EEntity::EOperation::ECloneSystemimage - Operation class implementing System image cloning operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement System image cloning operation

=head1 DESCRIPTION



=head1 METHODS

=cut
package EOperation::ECloneSystemimage;
use parent 'EOperation';

use strict;
use warnings;

use Log::Log4perl 'get_logger';
use Data::Dumper;
use String::Random;
use Date::Simple (':all');

use Kanopya::Exceptions;
use Entity;
use EFactory;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;
use Template;

my $log = get_logger('executor');
my $errmsg;
our $VERSION = '1.00';

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my ($self, %args) = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "systemimage_src", "disk_manager" ]);
    
    General::checkParams(args => $self->{params}, required => [ "systemimage_name", "systemimage_desc", "disk_manager_params" ]);

    # Check if systemimage is not active
    $log->debug('Checking source systemimage active value <' .
                $self->{context}->{systemimage_src}->getAttr(name => 'systemimage_id') . '>');

    if ($self->{context}->{systemimage_src}->getAttr(name => 'active')) {
        $errmsg = 'Systemimage <' . $self->{context}->{systemimage_src}->getAttr(name => 'systemimage_id') .
                  '> is active.';
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    # Check if systemimage name does not already exist
    $log->debug('Checking unicity of systemimage_name <' . $self->{params}->{systemimage_name} . '>');

    my $sysimg_exists = Entity::Systemimage->getSystemimage(
                            hash => { systemimage_name => $self->{params}->{systemimage_name} }
                        );

    if (defined $sysimg_exists){
        $errmsg = 'EOperation::ECloneSystemimage->prepare : systemimage_name ' .
                  $self->{params}->{systemimage_name} . ' already exist';
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Create new systemimage instance
    eval {
        my $entity = Entity::Systemimage->new(systemimage_name => $self->{params}->{systemimage_name},
                                              systemimage_desc => $self->{params}->{systemimage_desc});
        $self->{context}->{systemimage} = EFactory::newEEntity(data => $entity);
    };
    if($@) {
        throw Kanopya::Exception::Internal::WrongValue(error => $@);
    }

    # Check if disk manager has enough free space
    my $neededsize = $self->{context}->{systemimage_src}->getDevice->getAttr(name => 'container_size');
    my $freespace  = $self->{context}->{disk_manager}->getFreeSpace(%{$self->{params}->{disk_manager_params}});

    $log->debug("Size needed for systemimage device : $neededsize, freespace left : $freespace");

    # TODO: temporary disable freespace checking, cause some disk managers do not implement it.
    if(0 and $neededsize > $freespace) {
        $errmsg = "EOperation::ECloneSystemimage->prepare : not enough freespace on " .
                  "the disk manager ($freespace left, $neededsize required)";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub execute {
    my $self = shift;

    $self->{context}->{systemimage}->create(src_container => $self->{context}->{systemimage_src},
                                            disk_manager  => $self->{context}->{disk_manager},
                                            erollback     => $self->{erollback},
                                            %{$self->{params}->{disk_manager_params}});

    $self->{context}->{systemimage}->cloneComponentsInstalledFrom(
        systemimage_source_id => $self->{context}->{systemimage_src}->getAttr(name => 'entity_id')
    );

    $log->info('System image <' . $self->{context}->{systemimage}->getAttr(name => 'systemimage_name') . '> is cloned');
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010-2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
