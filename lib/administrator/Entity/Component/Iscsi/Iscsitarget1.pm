#    Copyright 2011 Hedera Technology SAS
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

=pod

=begin classdoc

TODO

=end classdoc

=cut

package Entity::Component::Iscsi::Iscsitarget1;
use base "Entity::Component::Iscsi";
use base "Manager::ExportManager";

use strict;
use warnings;

use General;
use Kanopya::Exceptions;

use Entity::Container;
use Entity::ContainerAccess::IscsiContainerAccess;

use Log::Log4perl "get_logger";
use Data::Dumper;


my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    export_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

sub exportType {
    return "ISCSI target";
}

use constant ACCESS_MODE => {
    READ_WRITE => 'wb',
    READ_ONLY  => 'ro',
};

sub checkExportManagerParams {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => [ "iscsi_portals" ]);
}

=pod

=begin classdoc

@return the managers parameters as an attribute definition. 

=end classdoc

=cut

sub getExportManagerParams {
    my $self = shift;
    my %args  = @_;

    my $portals = {};
    for my $portal (@{ $self->getConf->{iscsi_portals} }) {
        $portals->{$portal->{iscsi_portal_id}} = $portal->{iscsi_portal_ip} . ':' . $portal->{iscsi_portal_port}
    }

    return {
        iscsi_portals => {
            label        => 'ISCSI portals to use',
            type         => 'enum',
            relation     => 'multi',
            is_mandatory => 1,
            options      => $portals
        },
    };
}

sub getConf {
    my $self = shift;
    my @targets = ();

    my $conf = $self->SUPER::getConf();

    my @accesses = Entity::ContainerAccess->search(
                       hash => { export_manager_id => $self->getAttr(name => 'entity_id') }
                   );

    for my $access (@accesses) {
        my @luns = ();
        push @luns, {
            iscsitarget1_lun_id     => $access->getContainer->id,
            iscsitarget1_lun_number => $access->getAttr(name => 'lun_name'),
            iscsitarget1_lun_device => $access->getContainer->getAttr(name => 'container_device'),
            iscsitarget1_lun_typeio => $access->getAttr(name => 'typeio'),
            iscsitarget1_lun_iomode => $access->getAttr(name => 'iomode'),
        };
        push @targets, {
            iscsitarget1_target_name => $access->getAttr(name => 'container_access_export'),
            iscsitarget1_target_id   => $access->getAttr(name => 'entity_id'),
            luns => \@luns
        };
    }

    $conf->{targets} = \@targets;
    return $conf;
}

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['conf']);

    $self->SUPER::setConf(%args);

    my $conf = $args{conf};
    for my $target ( @{ $conf->{targets} } ) {
        LUN:
        for my $lun ( @{ $target->{luns} } ) {
            # Create the export if not already exists
            if (not $lun->{iscsitarget1_lun_id}) {
                my @containers = Entity::Container->search(hash => {});

                # Check if specified device match to a registred container.
                my $container;
                foreach my $cont (@containers) {
                    my $device = $cont->getAttr(name => 'container_device');
                    if ("$device" eq "$lun->{iscsitarget1_lun_device}") {
                        $container = $cont;
                        last;
                    }
                }
                if (! defined $container) {
                    $errmsg = "Specified device <$lun->{iscsitarget1_lun_device}> " .
                              "does not match to an existing container.";
                    $log->error($errmsg);
                    throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
                }

                $self->createExport(container   => $container,
                                    export_name => $container->container_name,
                                    typeio      => $lun->{iscsitarget1_lun_typeio},
                                    iomode      => $lun->{iscsitarget1_lun_iomode});
            }

            # Temporary: we can create only one lun with one target
            last LUN;
        }        
    }
}

# return a data structure to pass to the template processor 
sub getTemplateData {
    my $self = shift;
    my $targets = { };
    my @results = ();

    my @exports = Entity::ContainerAccess->search(
                      hash => { export_manager_id => $self->getAttr(name => "component_id") }
                  );

    for my $export (@exports) {
        my $target;
        my $target_name = $export->getAttr(name => "container_access_export");
        my $luns;

        if (defined $targets->{$target_name}) {
            $target = $targets->{$target_name};
        }
        else {
            $target = { luns        => [],
                        target_name => $target_name };
        }

        my $container = Entity::Container->get(
                            id => $export->getAttr(name => 'container_id')
                        );

        push @{$target->{luns}}, {
            number => 0, # $export->getAttr(name => 'number'),
            device => $container->getAttr(name => 'container_device'),
            typeio => $export->getAttr(name => 'typeio'),
            iomode => $export->getAttr(name => 'iomode'),
        };

        $targets->{$target_name} = $target;
    }

    my @values = values %{$targets};
    return { targets => \@values };
}

=head2 createExport

    Desc : Implement createExport from ExportManager interface.
           This function enqueue a ECreateExport operation.
    args : export_name, device, typeio, iomode

=cut

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container", "export_name", "typeio", "iomode" ]);

    $log->debug("New Operation CreateExport with attrs : " . %args);
    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'CreateExport',
        params   => {
            context => {
                export_manager => $self,
                container      => $args{container},
            },
            manager_params => {
                export_name => $args{export_name},
                typeio      => $args{typeio},
                iomode      => $args{iomode},
            },
        },
    );
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return "class { 'kanopya::iscsitarget': }\n";
}

1;
