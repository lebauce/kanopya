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

package EEntity::EComponent::EDhcpd3;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent";
use Log::Log4perl "get_logger";
use General;

my $log = get_logger("executor");
my $errmsg;

sub addHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args,
                         required => ['dhcpd3_subnet_id','dhcpd3_hosts_ipaddr',
                                      'dhcpd3_hosts_mac_address', 'dhcpd3_hosts_hostname',
                                      'kernel_id', "dhcpd3_hosts_ntp_server",
                                      'dhcpd3_hosts_domain_name', 'dhcpd3_hosts_domain_name_server']);
    my $erollback = $args{erollback};
    delete $args{erollback};

    my $host_id = $self->_getEntity()->addHost(%args);
    $args{erollback} = $erollback;

    if(exists $args{erollback}) {
        $args{erollback}->add(function   =>$self->can('removeHost'),
                              parameters => [$self,
                                            "dhcpd3_subnet_id", $args{dhcpd3_subnet_id},
                                            "dhcpd3_hosts_id", $host_id]);
    }
    return $host_id;
}

sub removeHost {
    my $self = shift;
    my %args = @_;
    my $host;

    General::checkParams(args => \%args, required => ['dhcpd3_subnet_id','dhcpd3_hosts_id']);

    if (exists $args{erollback}){
        $host = $self->_getEntity()->getHost(dhcpd3_subnet_id    => $args{dhcpd3_subnet_id},
                                                dhcpd3_hosts_id     =>$args{dhcpd3_hosts_id});
    }
    
    my $ret = $self->_getEntity()->removeHost(%args);
    
    if(exists $args{erollback}) {
        $args{erollback}->add(function   =>$self->can('addHost'),
                              parameters => [$self,
                                            'dhcpd3_subnet_id', $host->{dhcpd3_subnet_id},
                                            'dhcpd3_hosts_ipaddr', $host->{dhcpd3_hosts_ipaddr},
                                            'dhcpd3_hosts_mac_address', $host->{dhcpd3_hosts_mac_address}, 
                                            'dhcpd3_hosts_hostname', $host->{dhcpd3_hosts_hostname},
                                            'kernel_id', $host->{kernel_id},
                                            "dhcpd3_hosts_ntp_server", $host->{dhcpd3_hosts_ntp_server},
                                            'dhcpd3_hosts_domain_name', $host->{dhcpd3_hosts_domain_name},
                                            'dhcpd3_hosts_domain_name_server', $host->{dhcpd3_hosts_domain_name_server}]);
    }

    return $ret;
}

# generate edhcpd configuration files
sub generate {
    my $self = shift;
    my %args = @_;

    my $config = {
        INCLUDE_PATH => $self->_getEntity()->getTemplateDirectory(),
        INTERPOLATE  => 1,               # expand "$var" in plain text
        POST_CHOMP   => 0,               # cleanup whitespace 
        EVAL_PERL    => 1,               # evaluate Perl code blocks
        RELATIVE     => 1,               # desactive par defaut
    };
    
    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");
    # create Template object
    my $template = Template->new($config);
    my $input = "dhcpd.conf.tt";
    my $data = $self->_getEntity()->getConf();
    
    $template->process($input, $data, "/tmp/".$tmpfile) || do {
        $errmsg = "EComponent::EDhcpd3->generate : error during template generation : $template->error;";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);    
    };
    $self->getEContext->send(src => "/tmp/$tmpfile", dest => "/etc/dhcp/dhcpd.conf");
    unlink "/tmp/$tmpfile";
    $log->debug("Dhcp server conf generate and sent");
    if(exists $args{erollback}){
        $args{erollback}->add(function => $self->can('generate'), parameters => [ $self ]);
    }

}

# Reload conf on edhcp
sub reload {
    my $self = shift;
    my %args = @_;
    
    my $command = "invoke-rc.d isc-dhcp-server restart";
    my $result = $self->getEContext->execute(command => $command);
    
    if(exists $args{erollback}){
        $args{erollback}->add(function => $self->can('reload'), parameters => [ $self ]);
    }
    return;
}

1;
