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
package EEntity::EComponent::EWebserver::EApache2;

use strict;
use Template;
use String::Random;
use Data::Dumper;
use base "EEntity::EComponent::EWebserver";
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


sub addNode {
	my $self = shift;
	my %args = @_;
	
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{motherboard} or ! defined $args{motherboard}) ||
		(! exists $args{mount_point} or ! defined $args{mount_point})) {
		$errmsg = "EComponent::EWebserver::EApacge2->configureNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $config = {
	    INCLUDE_PATH => "/templates/components/apache2", #$self->_getEntity()->getTemplateDirectory(),
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 0,               # cleanup whitespace 
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	    RELATIVE => 1,                   # desactive par defaut
	};
	
	my $apache2_conf = $self->_getEntity()->getGeneralConf();	
	$log->debug("Apache2 conf return is : " . Dumper($apache2_conf));
	my $rand = new String::Random;
	my $template = Template->new($config);
	
	# generation of /etc/apache2/apache2.conf 
	my $tmpfile = $rand->randpattern("cccccccc");
	my $input = "apache2.conf.tt";
	my $data = {};
	$data->{serverroot} = $apache2_conf->{'apache2_serverroot'};
   	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::EWebserver::EApache2->addNode : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}.'/apache2/apache2.conf');	
	unlink "/tmp/$tmpfile";
	
	# generation of /etc/apache2/ports.conf 
	$tmpfile = $rand->randpattern("cccccccc");
	$input = "ports.conf.tt";
    $data = {};
    $data->{ports} = $apache2_conf->{apache2_ports};
    $data->{sslports} = $apache2_conf->{apache2_sslports};
       	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::EWebserver::EApache2->addNode : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}.'/apache2/ports.conf');	
	unlink "/tmp/$tmpfile";
	
	# generation of /etc/apache2/sites-available/default
	$tmpfile = $rand->randpattern("cccccccc");
	$input = "virtualhost.tt";
    
    $data = {};
    $data->{virtualhosts} = $self->_getEntity()->getVirtualhostConf();
    $data->{ports} =  $apache2_conf->{apache2_ports};
    $data->{sslports} = $apache2_conf->{apache2_sslports};
    
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::EWebserver::EApache2->addNode : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}.'/apache2/sites-available/default');	
	unlink "/tmp/$tmpfile";
	
	$self->addInitScripts(	etc_mountpoint => $args{mount_point}, 
								econtext => $args{econtext}, 
								scriptname => 'apache2', 
								startvalue => '91', 
								stopvalue => '09');
	
}

sub removeNode{
	
}

# Reload snmp process
sub reload {
	my $self = shift;
	my %args = @_;
	
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::EMonitoragent::ESnmpd5->reload needs an econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $command = "invoke-rc.d apache2 restart";
	my $result = $args{econtext}->execute(command => $command);
	return undef;
}

1;
