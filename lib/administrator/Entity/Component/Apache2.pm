# Apache2.pm Apache 2 web server component (Adminstrator side)
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
# Created 24 july 2010
=head1 NAME

<Entity::Component::Apache2> <Apache 2 component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Apache2> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Apache2>;

my $component_instance_id = 2; # component instance id

Entity::Component::Apache2->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Apache2->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Apache2 is class allowing to instantiate an apache2 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Apache2;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

=head2 addVirtualhost
B<Class>   : Public
B<Desc>    : This method allows to add a new virtualhost to component instance configuration.
B<args>    : 
    B<apache2_virtualhost_servername> : I<String> : Virtualhost server name
    B<apache2_virtualhost_sslenable> : I<int> : 1 activat SSL, 0 disable it.
    B<apache2_virtualhost_serveradmin> : I<String> : Virtualhost admin email.
    B<apache2_virtualhost_documentroot> : I<String> : directory hosting virtualhost root document.
    B<apache2_virtualhost_log> : I<String> : file path for access log.
    B<apache2_virtualhost_errorlog> : I<String> : file path for error log.
    
B<Return>  : None
B<Comment>  : None
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
    
=cut

sub addVirtualhost {
    #TODO AddVirtualhost
}

=head2 getVirtualhost
B<Class>   : Public
B<Desc>    : This method allows to get a existing virtualhosts.
B<args>    : None
B<Return>  : hash ref table containing all virtualhost, hash ref are composed by :
    B<apache2_virtualhost_servername> : I<String> : Virtualhost server name
    B<apache2_virtualhost_sslenable> : I<int> : 1 activat SSL, 0 disable it.
    B<apache2_virtualhost_serveradmin> : I<String> : Virtualhost admin email.
    B<apache2_virtualhost_documentroot> : I<String> : directory hosting virtualhost root document.
    B<apache2_virtualhost_log> : I<String> : file path for access log.
    B<apache2_virtualhost_errorlog> : I<String> : file path for error log.
B<Comment>  : None
B<throws>  : 
    B<Kanopya::Exception> When apache2 component instance is not already saved in db
    
=cut

sub getVirtualhostConf{
    my $self = shift;

    if(! $self->{_dbix}->in_storage) {
        $errmsg = "Entity::Component::Apache2->getVirtualhostConf must be called on an already save instance";
        $log->error($errmsg);
        throw Kanopya::Exception(error => $errmsg);
    }
    my $virtualhost_rs = $self->{_dbix}->apache2_virtualhosts;
    my @tab_virtualhosts = ();
    while (my $virtualhost_row = $virtualhost_rs->next){
        my %virtualhost = $virtualhost_row->get_columns();
        push @tab_virtualhosts, \%virtualhost;
    }
    return \@tab_virtualhosts;
}

=head2 getGeneralConf
B<Class>   : Public
B<Desc>    : This method allows to get a apache2 general conf.
B<args>    : None
B<Return>  : hash ref containing apache 2 general conf, hash is composed by :
    B<apache2_loglevel> : I<String> : Apache 2 general log level 
        (debug, info, notice, warn, error, crit,  alert, emerg)
    B<apache2_serverroot> : I<String> : directory hosting apache2 root document.
    B<apache2_ports> : I<int> : Apache 2 port HTTP number
    B<apache2_sslports> : I<Int> : fApache 2 port SSL number.
B<Comment>  : None
B<throws>  : 
    B<Kanopya::Exception> When apache2 component instance is not already saved in db
    
=cut

sub getGeneralConf{
    my $self = shift;

    if(! $self->{_dbix}->in_storage) {
        $errmsg = "Entity::Component::Apache2->getGeneralConf must be called on an already save instance";
        $log->error($errmsg);
        throw Kanopya::Exception(error => $errmsg);
    }
    my %apache2_conf = $self->{_dbix}->get_columns();
    $log->debug("Apache2 conf return is : " . Dumper(%apache2_conf));
    return \%apache2_conf;
}

=head2 getConf
B<Class>   : Public
B<Desc>    : This method allows to get a structured image of apache2 configuration.
B<args>    : None
B<Return>  : hash ref containing apache 2 global conf, hash is composed by :
    B<apache2_loglevel> : I<String> : Apache 2 general log level 
        (debug, info, notice, warn, error, crit,  alert, emerg)
    B<apache2_serverroot> : I<String> : directory hosting apache2 root document.
    B<apache2_ports> : I<int> : Apache 2 port HTTP number
    B<apache2_sslports> : I<Int> : Apache 2 port SSL number.
    B<apache2_virtualhosts> : I<Table of hash ref> : Containing virtualhost, composed by :
        B<apache2_virtualhost_servername> : I<String> : Virtualhost server name
        B<apache2_virtualhost_sslenable> : I<int> : 1 activat SSL, 0 disable it.
        B<apache2_virtualhost_serveradmin> : I<String> : Virtualhost admin email.
        B<apache2_virtualhost_documentroot> : I<String> : directory hosting virtualhost root document.
        B<apache2_virtualhost_log> : I<String> : file path for access log.
        B<apache2_virtualhost_errorlog> : I<String> : file path for error log.
B<Comment>  : None
B<throws>  : None
    
=cut
sub getConf {
    my $self = shift;
    my $apache2_conf = {
        apache2_id => undef,
        apache2_loglevel => undef,
        apache2_serverroot => undef,
        apache2_ports => undef,
        apache2_sslports => undef,
        apache2_virtualhosts => [
            { apache2_virtualhost_id => undef,
              apache2_virtualhost_servername => undef,
              apache2_virtualhost_sslenable => undef,
              apache2_virtualhost_serveradmin => undef,
              apache2_virtualhost_documentroot => undef,
              apache2_virtualhost_log => undef,
              apache2_virtualhost_errorlog => undef,
            },
        ]
    };
    
    my $lineindb = $self->{_dbix};
    if(defined $lineindb) {
        my %dbconf = $lineindb->get_columns();
        $apache2_conf = \%dbconf;

        my $virtualhost_rs = $lineindb->apache2_virtualhosts;
        my @tab_virtualhosts = ();
        while (my $virtualhost_row = $virtualhost_rs->next){
            my %virtualhost = $virtualhost_row->get_columns();
            delete $virtualhost{'apache2_id'};
            push @tab_virtualhosts, \%virtualhost;
        }
        $apache2_conf->{apache2_virtualhosts} = \@tab_virtualhosts;
        $log->debug("APACHE2 configuration exists in db: ".Dumper $apache2_conf);
        
    }

    return $apache2_conf;
}

=head2 setConf
B<Class>   : Public
B<Desc>    : This method allows to set a complete apache2 configuration from structured image.
B<args>    : hash ref containing apache 2 global conf, hash is composed by :
    B<apache2_loglevel> : I<String> : Apache 2 general log level 
        (debug, info, notice, warn, error, crit,  alert, emerg)
    B<apache2_serverroot> : I<String> : directory hosting apache2 root document.
    B<apache2_ports> : I<int> : Apache 2 port HTTP number
    B<apache2_sslports> : I<Int> : Apache 2 port SSL number.
    B<apache2_virtualhosts> : I<Table of hash ref> : Containing virtualhost, composed by :
        B<apache2_virtualhost_servername> : I<String> : Virtualhost server name
        B<apache2_virtualhost_sslenable> : I<int> : 1 activat SSL, 0 disable it.
        B<apache2_virtualhost_serveradmin> : I<String> : Virtualhost admin email.
        B<apache2_virtualhost_documentroot> : I<String> : directory hosting virtualhost root document.
        B<apache2_virtualhost_log> : I<String> : file path for access log.
        B<apache2_virtualhost_errorlog> : I<String> : file path for error log.
B<Return>  : None
B<Comment>  : None
B<throws>  : None

=cut

sub setConf {
    my $self = shift;
    my ($conf) = @_;
    
    $log->debug("APACHE2 configuration to save in db: ".Dumper $conf);
    my $virtualhosts = $conf->{apache2_virtualhosts};
    delete $conf->{apache2_virtualhosts};
    
    if(not $conf->{apache2_id}) {
        # new configuration -> create    
        my $row = $self->{_dbix}->create($conf);
        $self->{_dbix}->clear_cache();
        foreach my $vh (@$virtualhosts) {
            $vh->{apache2_virtualhost_id} = undef;
            $self->{_dbix}->apache2_virtualhosts->create($vh);
        }
        
    } else {
        # old configuration -> update
         $self->{_dbix}->update($conf);
         my $virtualhosts_indb = $self->{_dbix}->apache2_virtualhosts;
         
         # update existing virtual hosts
         while(my $vhost_indb = $virtualhosts_indb->next) {
             my $found = 0;
             my $vhost_data;
             foreach    my $vhost_to_update (@$virtualhosts) {
                 if($vhost_to_update->{apache2_virtualhost_id} == $vhost_indb->get_column('apache2_virtualhost_id')) {
                     $found = 1;
                     $vhost_data = $vhost_to_update;
                     last;
                 }
             }
             if($found) {
                 $vhost_indb->update($vhost_data);
             } else {
                 $vhost_indb->delete();
             }
         }
         
         # create new virtual hosts
        foreach    my $vh (@$virtualhosts) {
            if ($vh->{apache2_virtualhost_id} == 0) {
                    $vh->{apache2_virtualhost_id} = undef;
                    $virtualhosts_indb->create($vh);
            }
        }
    }    
}

sub insertDefaultConfiguration {
    my $self = shift;
    my %args = @_;
    my $apache2_conf = {
        apache2_loglevel => 'debug',
        apache2_serverroot => '/srv',
        apache2_ports => 80,
        apache2_sslports => 443,
        apache2_virtualhosts => [
            {
              apache2_virtualhost_servername => 'www.yourservername.com',
              apache2_virtualhost_sslenable => 'no',
              apache2_virtualhost_serveradmin => 'admin@mycluster.com',
              apache2_virtualhost_documentroot => '/srv',
              apache2_virtualhost_log => '/tmp/apache_access.log',
              apache2_virtualhost_errorlog => '/tmp/apache_error.log',
            },
        ]
    };
    $self->{_dbix}->create($apache2_conf);
}

sub getNetConf{
    my $self = shift;
    my $http_port = $self->{_dbix}->get_column("apache2_ports");
    my $https_port = $self->{_dbix}->get_column("apache2_sslports");

    my %net_conf = ($http_port  => ['tcp']);

    # manage ssl
    my $virtualhosts = $self->getVirtualhostConf();
    my $ssl_enable = grep { $_->{apache2_virtualhost_sslenable} == 1 } @$virtualhosts;
    $net_conf{$https_port} = ['tcp', 'ssl'] if ($ssl_enable);

    return \%net_conf;
}

sub getClusterizationType { return 'loadbalanced'; }

# SYP: this sub is commented because when workload is high on a node, ssh sometimes fail
#      and so the node is considered broken even if it's no really broken.
#sub getExecToTest {
#    return {apache =>   {cmd => 'invoke-rc.d apache2 status',
#                         answer => 'Apache2? is running.*$',
#                         return_code => '0'}
#    };
#}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

Exceptions are thrown when apache2 component instance is not already saved in db
Exception : Kanopya::Exception 

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
