# EDeployDistribution.pm - Operation class implementing distribution deployment 

#    Copyright 2011 Hedera Technology SAS
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

EOperation::EDeployDistribution - Operation class implementing distribution deployment

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EDeployDistribution;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use XML::Simple;
use Kanopya::Exceptions;
use Entity::Cluster;
use Entity::Systemimage;
use Entity::Distribution;
use Entity::Gp;
use EFactory;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';


=head2 new

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
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
    

}

=head2 prepare

    $op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {
    
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    # Check if internal_cluster exists
    if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
        $errmsg = "EDeployComponent->prepare need an internal_cluster named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    
    # Get Operation parameters
    my $params = $self->_getOperation()->getParams();
    
    $self->{_file_path} = $params->{file_path};
    
    $self->{_file_path} =~ /.*\/(.*)$/;
    my $file_name = $1;
    $self->{_file_name} = $file_name; 

    # Check tarball name and retrieve component info from tarball name (temporary. TODO: component def xml file) 
    if ((not defined $file_name) || $file_name !~ /distribution_([a-zA-Z]+)_([0-9\.]+)\.tar\.bz2/) {
        $errmsg = "Incorrect component tarball name";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my ($dist_name, $dist_version) = ($1, $2);
    $self->{distribution_name} = $dist_name;
    $self->{distribution_version} = $dist_version;
    
    $log->debug("instanciate new distribution <$self->{distribution_name}> version <$self->{distribution_version}>");
    eval {
       $self->{_objs}->{distribution} = Entity::Distribution->new(distribution_name     => $self->{distribution_name},
                                                                  distribution_version  => $self->{distribution_version},
                                                                  distribution_desc     => "Upload by Admin on Kanopya");
    };
    if($@) {
        my $err = $@;
        $errmsg = "Distribution upload, maybe already exists \n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }


    ### Check Parameters and context
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "Operation DeployComponent failed an error occured :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }


    # Get contexts
    $self->{executor}->{econtext} = EFactory::newEContext(ip_source => "127.0.0.1", ip_destination => "127.0.0.1");
    $self->loadContext( internal_cluster => $args{internal_cluster}, service => 'nas' );
    $self->{nas}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{nas});
    my $tmp = $self->{nas}->{obj}->getComponent(name       => "Lvm",
                                                version    => "2");
    $log->debug("Value return by getcomponent ". ref($tmp));
    $self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
    
}

sub execute{
    my $self = shift;
    my ($cmd, $cmd_res);
    
    # untar component archive on local /tmp/<tar_root>
    $log->debug("Deploy files from archive '$self->{_file_path}'");
    $cmd = "tar -jxf $self->{_file_path} -C /tmp"; 
    $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);
    
    my $vg = $self->{_objs}->{component_storage}->_getEntity()->getMainVg();
    
    # Find size of root and etc
    for my $disk_type ("etc","root") {
        # get the file size
        my $file = "/tmp/$disk_type"."_$self->{distribution_name}_$self->{distribution_version}.img";
        $cmd = "du -s --bytes $file | awk '{print \$1}'";
        $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);
        if($cmd_res->{'stderr'}){
            $errmsg = "Error with $disk_type disk acces of <$self->{distribution_name}>";
            $log->error($errmsg);
             Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
        chomp($cmd_res->{'stdout'});
        # create a new lv with the same size
        $self->{$disk_type} = $self->{_objs}->{component_storage}->createDisk(name => "$disk_type"."_$self->{distribution_name}_$self->{distribution_version}",
                                                                 size        => $cmd_res->{'stdout'}."B",
                                                                 filesystem  => "ext3",
                                                                 econtext    => $self->{nas}->{econtext},
                                                                 erollback   => $self->{erollback},
                                                                 noformat    => 1);
        
        # duplicate file content into the new lv
        $cmd = "dd if=$file of=/dev/$vg->{vgname}/$disk_type".
               "_$self->{distribution_name}_$self->{distribution_version} bs=1M";
         $log->debug($cmd);
        $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);
        $self->{_objs}->{distribution}->setAttr(name => "$disk_type"."_device_id", value => $self->{$disk_type});
    
        # delete the file
        $cmd = "rm $file";
        $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);
    
    }
    $self->{_objs}->{distribution}->save();
        my @group = Entity::Gp->getGroups(hash => {gp_name=>'Distribution'});
        $group[0]->appendEntity(entity => $self->{_objs}->{distribution});
    # update distribution provided components list
	$self->{_objs}->{distribution}->updateProvidedComponents();
	
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
