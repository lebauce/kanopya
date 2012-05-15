# EDeployComponent.pm - Operation class implementing component deployment 

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
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Systemimage;
use EFactory;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 prepare

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{params}, required => [ "file_path" ]);
    
    $self->{params}->{file_path} =~ /.*\/(.*)$/;
    my $file_name = $1;
    $self->{params}->{file_path} = $file_name; 

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

    my $nas = Entity->get(id => $self->{config}->{cluster}->{nas});
    $self->{context}->{nas} = EFactory::newEEntity(data => $nas);

    my $executor = Entity->get(id => $self->{config}->{cluster}->{executor});
    $self->{context}->{executor} = EFactory::newEEntity(data => $executor);
}

sub execute{
    my $self = shift;

    $log->debug("Deploy component '$self->{comp_name}' version $self->{comp_version} category '$self->{comp_category}'");
    
    my $comp_fullname_lc = lc $self->{comp_name} . $self->{comp_version};
    my ($cmd, $cmd_res);
    
    # untar component archive on local /tmp/<tar_root>
    $log->debug("Deploy files from archive '$self->{params}->{file_path}'");
    $cmd = "tar -jxf $self->{params}->{file_path} -C /tmp"; 
    $cmd_res = $self->getEContext->execute(command => $cmd);
    
    $self->{_file_name} =~ /(.*)\.tar\.bz2/; 
    my $root_dir_name = $1;
    
    # retrieve package info
    my $desc_filename = $root_dir_name;
    $cmd = "cat /tmp/$root_dir_name/$desc_filename.xml";
    $cmd_res = $self->getEContext->execute(command => $cmd);
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
            $self->{context}->{$srv}->getEContext->send(src  => "/tmp/$root_dir_name/" . $file->{src},
                                                        dest => "/opt/kanopya/" . $file->{dest});    
        }
    }

    # Send templates files (actually cp in local)
    if (defined $package_info->{templates_dir}) {
        $package_info->{templates_dir} =~ /(.*)\/([^\/]*)$/;
        my $path = $1; 
        $cmd = "cp -r /tmp/$root_dir_name/$package_info->{templates_dir} /opt/kanopya/$path";
        $cmd_res = $self->getEContext->execute(command => $cmd);
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
        $cmd_res = $self->getEContext->execute(command => $cmd);
        if ( $cmd_res->{stderr} =~ "ERROR" ) {
            $errmsg = "While creating component tables : $cmd_res->{stderr}";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);        
        }
        $log->debug("DB tables created");
    }    
    
    # Register
    $self->_registerComponentInDB(templates_directory=>$package_info->{templates_dir});

#   TODO call component data sql (for specific data insertion)
#   create new component and call init method on it

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
    
    
    my $adm = Administrator->new();

    my $component_id = $adm->registerComponent(component_name=>$comp_name, component_version => $comp_version, component_category=>$comp_cat);

    $adm->registerTemplate(component_template_directory => $args{templates_directory},
                           component_template_name      => "default_$comp_fullname_lc",
                           component_id                 => $component_id);
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
