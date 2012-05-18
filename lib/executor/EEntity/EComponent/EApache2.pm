package EEntity::EComponent::EApache2;

use strict;
use Template;
use String::Random;
use Data::Dumper;
use base "EEntity::EComponent";
use Log::Log4perl "get_logger";
use General;

my $log = get_logger("executor");
my $errmsg;

sub addNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => [ 'host', 'mount_point' ]);

    my $apache2_conf = $self->_getEntity()->getGeneralConf();    
    my $data = {};
    
    # generation of /etc/apache2/apache2.conf 
    $data->{serverroot} = $apache2_conf->{'apache2_serverroot'};
    $self->generateFile( 
         mount_point => $args{mount_point}.'/etc',
        template_dir => "/templates/components/apache2",
          input_file => "apache2.conf.tt",
              output => "/apache2/apache2.conf",
                data => $data
    );

    # generation of /etc/apache2/ports.conf
    $data = {};
    $data->{ports} = $apache2_conf->{apache2_ports};
    $data->{sslports} = $apache2_conf->{apache2_sslports};

    $self->generateFile(
         mount_point => $args{mount_point}.'/etc',
        template_dir => "/templates/components/apache2",
          input_file => "ports.conf.tt",
              output => '/apache2/ports.conf',
                data => $data
    );

    # generation of /etc/apache2/sites-available/default
    $data = {};
    $data->{virtualhosts} = $self->_getEntity()->getVirtualhostConf();
    $data->{ports} =  $apache2_conf->{apache2_ports};
    $data->{sslports} = $apache2_conf->{apache2_sslports};
    
    $self->generateFile(
         mount_point => $args{mount_point}.'/etc',
        template_dir => "/templates/components/apache2",
          input_file => "virtualhost.tt", 
              output => '/apache2/sites-available/default', 
                data => $data
    );

    # generation of /etc/apache2/mods-available/status.conf
    $data = {};
    $data->{monitor_server_ip} = 'all';
    
    $self->generateFile(
         mount_point => $args{mount_point}.'/etc',
        template_dir => "/templates/components/apache2",
          input_file => "status.conf.tt", 
              output => '/apache2/mods-enabled/status.conf', 
                data => $data
    );

    $self->addInitScripts(
        scriptname => 'apache2', 
    );

}

sub removeNode {}

sub reload {
    my $self = shift;
    my %args = @_;

    my $command = "invoke-rc.d apache2 restart";
    my $result = $self->getEContext->execute(command => $command);
    return undef;
}

1;


__END__

=pod

=head1 NAME

EEntity::EComponent::EApache2 - This is the execution class of apache 2 component

=head1 SYNOPSIS

use EEntity::EComponent::EApache2;
use Entity::Component::Apache2;

my $apache2_component_instance_id; # get from somewhere

my $apache2_comp = Entity::Component::Apache2->get(id => $apache2_component_instance_id);

my #apache2_ecomp = EFactory::newEEntity(data => $apache2_comp);

=head1 DESCRIPTION

This Object is used to manipulate component Apache 2. 
It allows to  start/stop the component, generate config files, deploy it, reload the configuration.
This is this class which is used to add a Apache2 conf on a node joining a webserver cluster

=head1 METHODS

=head2 finish

    Class : Public

    Desc : This method is the last execution operation method called.
    It is used to clean and finalize operation execution

    Args :
        None

    Return : Nothing

    Throw

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

Copyright 2011 Hedera Technology SAS
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


