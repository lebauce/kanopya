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
package EEntity::EComponent::EHAProxy1;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent";
use Log::Log4perl "get_logger";
use General;

my $log = get_logger("executor");
my $errmsg;

# generate configuration files on node
sub configureNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'host', 'mount_point', 'cluster']);

    my $template_path = $args{template_path} || "/templates/components/haproxy";
    
    my $conf = $self->_getEntity()->getConf();
    my %data;
    # remove prefix of var name
    for (keys %$conf) {
        $_ =~ /haproxy1_(.*)/;
        $data{$1} = $conf->{"haproxy1_$1"};
    }
    
    my $publicips =  $args{cluster}->getPublicIps();
    my $vip = shift @$publicips;
    $data{public_ip} = defined $vip ? $vip->{address} : "127.0.0.1";
    
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => $template_path,
                         input_file => "haproxy.cfg.tt", output => "/haproxy/haproxy.cfg",
                         data => \%data);
    
    # send default haproxy conf (allowing haproxy to be started with init script)
    $args{econtext}->send(src => $template_path . "/haproxy_default", dest => $args{mount_point} . "/default/haproxy");
    
}

sub addNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'host', 'mount_point', 'cluster']);

    $args{mount_point} .= '/etc';

    my $masternodeip = $args{cluster}->getMasterNodeIp();
    
    # Run only on master node
    if(not defined $masternodeip) {
	    $self->configureNode(%args);
	    
	    $self->addInitScripts(  etc_mountpoint => $args{mount_point}, 
	                            econtext => $args{econtext}, 
	                            scriptname => 'haproxy', 
	                            startvalue => '20', 
	                            stopvalue => '20');
    }
}

# Reload process
sub reload {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext']);

}

1;
