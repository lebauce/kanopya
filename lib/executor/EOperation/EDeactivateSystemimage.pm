# EDeactivateSystemimage.pm - Operation class implementing systemimage deactivation operation

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

EOperation::EDeactivateSystemimage - Operation class implementing systemimage deactivation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement systemimage deactivation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EDeactivateSystemimage;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use vars qw(@ISA $VERSION);
use Kanopya::Exceptions;
use EFactory;
use Template;
use Entity::Cluster;
use General;

my $log = get_logger("executor");
my $errmsg;
$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = EOperation::EDeactivateSystemimage->new();

    # Operation::EDeactivateSystemimage->new creates a new DeactivateSystemimage operation.
    # RETURN : EOperation::EDeactivateSystemimage : Operation deactive systemimage on execution side

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
    $self->{nas} = {};
    $self->{executor} = {};
    $self->{_objs} = {};
    return;
}

sub checkOp{
    my $self = shift;
    my %args = @_;
    
    
    # check if systemimage is not active
    $log->debug("checking systemimage active value <$args{params}->{systemimage_id}>");
       if(!$self->{_objs}->{systemimage}->getAttr(name => 'active')) {
            $errmsg = "EOperation::EActivateSystemiamge->new : cluster $args{params}->{systemimage_id} is already active";
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

    General::checkParams(args => \%args, required => ["internal_cluster"]);
    my $params = $self->_getOperation()->getParams();

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

    ### Check Parameters and context
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "Operation ActivateSystemimage failed an error occured :\n$error";
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
    $self->{_objs}->{component_export} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Iscsitarget",
                                                                                      version=> "1"));
    $log->debug("Load export component (iscsitarget version 1, it ref is " . ref($self->{_objs}->{component_export}));

}

sub execute{
    my $self = shift;
    my $adm = Administrator->new();
    
    my $sysimg_dev = $self->{_objs}->{systemimage}->getDevices();
    
    my $target_name = $self->{_objs}->{component_export}->_getEntity()->getFullTargetName(lv_name => $sysimg_dev->{root}->{lvname});
    my $target_id = $self->{_objs}->{component_export}->_getEntity()->getTargetIdLike(iscsitarget1_target_name => '%'. $sysimg_dev->{root}->{lvname});

    my $lun_id =  $self->{_objs}->{component_export}->_getEntity()->getLunId(iscsitarget1_target_id => $target_id,
                                                iscsitarget1_lun_device => "/dev/$sysimg_dev->{root}->{vgname}/$sysimg_dev->{root}->{lvname}");

    $self->{_objs}->{component_export}->removeExport(iscsitarget1_lun_id        => $lun_id,
                                                     econtext                   => $self->{nas}->{econtext},
                                                     iscsitarget1_target_name   => $target_name,
                                                     iscsitarget1_target_id     => $target_id,
                                                     erollback                  => $self->{erollback});
    my $eroll_del_export = $self->{erollback}->getLastInserted();
    # generate new configuration file
    $self->{erollback}->insertNextErollBefore(erollback=>$eroll_del_export);
    $self->{_objs}->{component_export}->generate(econtext => $self->{nas}->{econtext},
                                                 erollback  => $self->{erollback});
        
    # set system image active in db
    $self->{_objs}->{systemimage}->setAttr(name => 'active', value => 0);
    $self->{_objs}->{systemimage}->save();
    $log->info("System Image <". $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name') ."> deactivated");
}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
