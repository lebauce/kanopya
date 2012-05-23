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
use base 'EEntity::EComponent';

use strict;
use warnings;
use Log::Log4perl "get_logger";
use General;

my $log = get_logger("executor");
my $errmsg;

# generate configuration files on node
sub configureNode {
    my ($self, %args) = @_;
    
    General::checkParams(args => \%args, required => ['host', 'mount_point']);
    
    my $cluster = $self->_getEntity->getServiceProvider;
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
    
     my $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $args{host},
        file          => '/etc/haproxy/haproxy.cfg',
        template_dir  => '/templates/components/haproxy',
        template_file => 'haproxy.cfg.tt',
        data          => \%data 
    );
    
     $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/haproxy'
    );
    
    # send default haproxy conf (allowing haproxy to be started with init script)
    $self->getExecutorEContext->send(
        src  => '/templates/components/haproxy/haproxy_default', 
        dest => $args{mount_point} . '/etc/default/haproxy'
    );
}

sub addNode {
    my ($self, %args) = @_;
    
    General::checkParams(args => \%args, required => ['host', 'mount_point', 'cluster']);
    
    my $masternodeip = $args{cluster}->getMasterNodeIp();
    
    # Run only on master node
    if(not defined $masternodeip) {
	    $self->configureNode(%args);
        	    
	    $self->addInitScripts(
            mountpoint => $args{mount_point}, 
	        scriptname => 'haproxy', 
        );
    }
}



1;
