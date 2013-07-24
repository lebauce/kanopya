#    Copyright © 2010-2013 Hedera Technology SAS
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

package EEntity::EOperation::ECloneSystemimage;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl 'get_logger';
use Data::Dumper;
use String::Random;
use Date::Simple (':all');

use Kanopya::Exceptions;
use Entity;
use EEntity;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Cluster;
use Entity::Host;
use Template;

my $log = get_logger("");
my $errmsg;


sub check {
    my ($self, %args) = @_;
    $self->SUPER::check();

    General::checkParams(args => $self->{context}, required => [ "systemimage_src", "disk_manager" ]);
    
    General::checkParams(args => $self->{params}, required => [ "systemimage_name", "systemimage_desc", "disk_manager_params" ]);
}


sub execute {
    my $self = shift;
    $self->SUPER::execute();

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

    my $sysimg_exists = Entity::Systemimage->find(
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
        my $entity = Entity::Systemimage->new(systemimage_name    => $self->{params}->{systemimage_name},
                                              systemimage_desc    => $self->{params}->{systemimage_desc}
                                              service_provider_id => $self->{params}->{service_provider_id});
        $self->{context}->{systemimage} = EEntity->new(data => $entity);
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
