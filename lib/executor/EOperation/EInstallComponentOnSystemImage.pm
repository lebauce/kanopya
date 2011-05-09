# EInstallComponentOnSystemImage.pm - Operation class implementing component installation on systemimage

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
# Created 14 july 2010

=head1 NAME

EOperation::EInstallComponentOnSystemImage - Operation class implementing component installation on systemimage

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EInstallComponentOnSystemImage;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::Cluster;
use Entity::Systemimage;
use EFactory;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';


=head2 new

    my $op = EOperation::EInstallComponentOnSystemImage->new();

    # Operation::EInstallComponentInSystemImage->new installs component on systemimage.
    # RETURN : EOperation::EInstallComponentInSystemImage : Operation activate cluster on execution side

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    $log->debug("Class is : $class");
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

    $op->_init();
    # This private method is used to define some hash in Operation

=cut

sub _init {
    my $self = shift;
    $self->{_objs} = {};
    return;
}

sub checkOp{
    my $self = shift;
    my %args = @_;
    
    $log->debug("checking systemimage active value <$args{params}->{systemimage_id}>");
       if($self->{_objs}->{systemimage}->getAttr(name => 'active')) {
            $errmsg = "EOperation::EActivateSystemiamge->new : cluster $args{params}->{systemimage_id} is active";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

}

=head2 prepare

    $op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {
    
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    $log->info("Operation preparation");

    General::checkParams(args => \%args, required => ["internal_cluster"]);
    
    # Get Operation parameters
    my $params = $self->_getOperation()->getParams();
    $self->{_objs} = {};

    #### Get instance of Systemimage Entity
    $log->debug("Load systemimage instance");
    eval {
       $self->{_objs}->{systemimage} = Entity::Systemimage->get(id => $params->{systemimage_id});
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EDeactivateSystemimage->prepare : systemimage_id $params->{systemimage_id} does not find\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    $log->debug("get systemimage self->{_objs}->{systemimage} of type : " . ref($self->{_objs}->{systemimage}));

    $self->{_objs}->{component_id} = $params->{component_id};

    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "Operation InstallComponent on systemimage failed an error occured :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    #### Instanciate Clusters
    # Instanciate nas Cluster 
    $self->{nas}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{nas});
    $log->debug("Nas Cluster get with ref : " . ref($self->{nas}->{obj}));

    # Load NAS Econtext
    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "nas");
    
    ## Instanciate Component needed (here ISCSITARGET on nas )
    # Instanciate Export component.
    $self->{_objs}->{component_storage} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Lvm",
                                                                                      version=> "2"));
    $log->info("Load export component (iscsitarget version 1, it ref is " . ref($self->{_objs}->{component_storage}));

}

sub execute{
    my $self = shift;
    
    $self->{_objs}->{systemimage}->installedComponentLinkCreation(component_id => $self->{_objs}->{component_id});
    
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