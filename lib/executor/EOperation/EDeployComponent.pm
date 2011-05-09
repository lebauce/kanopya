# EDeployComponent.pm - Operation class implementing component deployment 

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

EOperation::EDeployComponent - Operation class implementing component deployment

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EDeployComponent;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use XML::Simple;
use Kanopya::Exceptions;
use Entity::Cluster;
use Entity::Systemimage;
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
    if ((not defined $file_name) || $file_name !~ /component_(.*)_([a-zA-Z]+)([0-9]+)\.tar\.bz2/) {
        $errmsg = "Incorrect component tarball name";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my ($comp_cat, $comp_name, $comp_version) = ($1, $2, $3);
    $self->{comp_category} = $comp_cat; 
    $self->{comp_name} = $comp_name;
    $self->{comp_version} = $comp_version;
    
    #TODO test if tarball is good and contains good element


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
    
    
}

sub execute{
    my $self = shift;
    $log->debug("Before EOperation exec");
    
    $log->debug("Deploy component '$self->{comp_name}' version $self->{comp_version} category '$self->{comp_category}'");
    
    my $comp_fullname_lc = lc $self->{comp_name} . $self->{comp_version};
    my ($cmd, $cmd_res);
    
    # untar component archive on local /tmp/<tar_root>
    $log->debug("Deploy files from archive '$self->{_file_path}'");
    $cmd = "tar -jxf $self->{_file_path} -C /tmp"; 
    $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);
    
    $self->{_file_name} =~ /(.*)\.tar\.bz2/; 
    my $root_dir_name = $1;
    
    # retrieve package info
    my $desc_filename = $root_dir_name;
    $cmd = "cat /tmp/$root_dir_name/$desc_filename.xml";
    $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);
    if ( $cmd_res->{stderr} ne '') {
        $errmsg = "While reading component archive info : $cmd_res->{stderr}";
        throw Kanopya::Exception::Internal(error => $errmsg);        
    }
    
    # Build info struct
    my $package_info = XMLin( "$cmd_res->{stdout}", ForceArray => ['nas', 'executor'] );
    
    # TODO check validity of package info (needed keys, compatibility of packager version and this operation,... )
    #$log->debug(Dumper $package_info);
    
    # Send files from local tmp to dest path on specified internal cluster
    for my $srv ('nas', 'executor') {
        my $files = $package_info->{$srv};
        next if (not defined $files);
        for my $file (@$files) {
            $self->{$srv}->{econtext}->send(     src  => "/tmp/$root_dir_name/" . $file->{src},
                                                dest => "/opt/kanopya/" . $file->{dest} );    
        }
    }
    
    # Send templates files (actually cp in local)
    if (defined $package_info->{templates_dir}) {
        $package_info->{templates_dir} =~ /(.*)\/([^\/]*)$/;
        my $path = $1; 
        $cmd = "cp -r /tmp/$root_dir_name/$package_info->{templates_dir} /opt/kanopya/$path";
        $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);
    }
    
    # Retriev admin db conf
    # TODO Better way to acces db info
    my $config = XMLin("/opt/kanopya/conf/libkanopya.conf");
    my ($dbname, $dbuser, $dbpwd, $dbhost, $dbport) = ( $config->{dbconf}->{name},
                                                          $config->{dbconf}->{user},
                                                          $config->{dbconf}->{password},
                                                          $config->{dbconf}->{host},
                                                          $config->{dbconf}->{port});
    
    # create tables 
    # Use local context (executor) to create tables in (potentially) remote db
    if (defined $package_info->{tables_file}) {
        my $tables_file = "/tmp/$root_dir_name/" . $package_info->{tables_file};
        #TODO check if tables_file is in archive (or in local /tmp) because mysql don't do error if file doesn't exist
        $cmd = "mysql -u $dbuser -p$dbpwd -h $dbhost -P $dbport < '$tables_file'";
        $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);
        if ( $cmd_res->{stderr} =~ "ERROR" ) {
            $errmsg = "While creating component tables : $cmd_res->{stderr}";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);        
        }
        $log->debug("DB tables created");
    }    
    
    # Register
    $self->_registerComponentInDB( dbname => $dbname, dbuser => $dbuser, dbpwd => $dbpwd, dbhost => $dbhost, dbport => $dbport );

    
    
}        

=head2 _registerComponentInDB
    
    Class : Private
    
    Desc : Insert component in component table, insert default template and provide component on default distribution
    
    Args : db connection infos
    
    Throw Exception if execution fail or cmd return error
    
=cut

sub _registerComponentInDB {
    my $self = shift;
    my %args = @_;
    
    my ($comp_name, $comp_version, $comp_cat) = ($self->{comp_name}, $self->{comp_version}, $self->{comp_category});
    my $comp_fullname_lc = lc $comp_name . $comp_version;
    
    my $sql_cmd = "SET foreign_key_checks=0;";
    
    # Register Component
    $sql_cmd .= "SET \@eid_new_component = (SELECT MAX(component_id) FROM component) + 1;";
    $sql_cmd .= "INSERT INTO component VALUES (\@eid_new_component,'$comp_name','$comp_version','$comp_cat');";
    
    # Insert template
    $sql_cmd .= "SET \@eid_new_component_template = (SELECT MAX(component_template_id) FROM component_template) + 1;";
    $sql_cmd .= "INSERT INTO component_template VALUES (\@eid_new_component_template,'default_$comp_fullname_lc','/templates/components/$comp_fullname_lc', \@eid_new_component);";
    
    # provide component on default distribution (1)
    $sql_cmd .= "INSERT INTO component_provided VALUES (\@eid_new_component,1);";
    $sql_cmd .=  "SET foreign_key_checks=1;";
    
    # Execute sql cmd
    my $cmd = "mysql -u $args{dbuser} -p$args{dbpwd} -h $args{dbhost} -P $args{dbport} $args{dbname} -e \"$sql_cmd\"";
    my $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);    
    
    # Throw execption if cmd failed
    if ( $cmd_res->{stderr} =~ "ERROR" ) {
        $errmsg = "While creating component tables : $cmd_res->{stderr}";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
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