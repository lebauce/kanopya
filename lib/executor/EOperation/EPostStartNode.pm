# EPostStartNode.pm - Operation class implementing Cluster creation operation

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

EEntity::Operation::EAddHost - Operation class implementing Host creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Host creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EPostStartNode;
use base "EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EFactory;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');
use Template;

my $log = get_logger("executor");
my $errmsg;

my $config = {
    INCLUDE_PATH => '/templates/internal/',
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 0,               # cleanup whitespace 
    EVAL_PERL    => 1,               # evaluate Perl code blocks
    RELATIVE => 1,                   # desactive par defaut
};

=head2 prepare

    $op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    $log->info("Operation preparation");

    General::checkParams(args => \%args, required => ["internal_cluster"]);
    
    my $params = $self->_getOperation()->getParams();

    General::checkParams(args => $params, required => [ "cluster_id", "host_id" ]);

    #$self->{nas}   = {};
    $self->{_objs} = {};
    
    # Get instance of Cluster Entity
    $log->info("Load cluster instance");
    $self->{_objs}->{cluster} = Entity::ServiceProvider::Inside::Cluster->get(id => $params->{cluster_id});
    $log->debug("get cluster self->{_objs}->{cluster} of type : " . ref($self->{_objs}->{cluster}));

    # Get cluster components Entities
    $log->info("Load cluster component instances");
    $self->{_objs}->{components}= $self->{_objs}->{cluster}->getComponents(category => "all");
    $log->debug("Load all component from cluster");

    # Get instance of Host Entity
    $log->info("Load Host instance");
    $self->{_objs}->{host} = Entity::Host->get(id => $params->{host_id});
    $log->debug("get Host self->{_objs}->{host} of type : " . ref($self->{_objs}->{host}));

    # Get contexts
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{executor});
    $self->{executor}->{econtext} = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                                          ip_destination => $exec_cluster->getMasterNodeIp());
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();
    
    if (not $self->{_objs}->{cluster}->getMasterNodeId()) {
        $self->{_objs}->{host}->becomeMasterNode();
    }

    my $components = $self->{_objs}->{components};
    $log->info('Processing cluster components configuration for this node');
    foreach my $i (keys %$components) {
        my $tmp = EFactory::newEEntity(data => $components->{$i});
        $log->debug("component is ".ref($tmp));
        $tmp->postStartNode(host     => $self->{_objs}->{host},
                            cluster  => $self->{_objs}->{cluster},
                            econtext => $self->{executor}->{econtext});
    }

    my $nodes = $self->{_objs}->{cluster}->getHosts();
    $log->info("Generate Hosts Conf");

    my $etc_hosts_file = $self->generateHosts(nodes => $nodes);
    foreach my $i (keys %$nodes) {
	    my $node = $nodes->{$i};
        my $node_ip = $nodes->{$i}->getInternalIP()->{ipv4_internal_address};
        my $node_econtext = EFactory::newEContext(ip_source      => $self->{executor}->{econtext}->getLocalIp,
                                                  ip_destination => $node_ip);
        $node_econtext->send(src => $etc_hosts_file, dest => "/etc/hosts");
    }    
	my $ehost = EFactory::newEEntity(data => $self->{_objs}->{host});
    $ehost->postStart(econtext => $self->{executor}->{econtext});
}
 
sub generateHosts {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "nodes" ]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # create Template object
    my $template = Template->new($config);
    my $input = "hosts.tt";
    my $nodes = $args{nodes};
    my @nodes_list = ();
    
    foreach my $i (keys %$nodes) {
        my $tmp = {hostname     => $nodes->{$i}->getAttr(name => 'host_hostname'),
                   domainname    => "hedera-technology.com",
                   ip            => $nodes->{$i}->getInternalIP()->{ipv4_internal_address}};
        push @nodes_list, $tmp;
    }
    my $vars = { hosts       => \@nodes_list };
    $log->debug(Dumper($vars));
    $template->process($input, $vars, "/tmp/$tmpfile") || die $template->error(), "\n";

    return("/tmp/".$tmpfile);
   # $self->{nas}->{econtext}->send(src => "/tmp/".$tmpfile, dest => "/etc/hosts");
   # unlink     "/tmp/$tmpfile";
}

#sub finish {
#    my $self = shift;
#    my $masternode;
#
#    if ($self->{_objs}->{cluster}->getMasterNodeId()) {
#        $masternode = 0;
#    } else {
#        $masternode =1;
#    }
#    
#    $self->{_objs}->{host}->becomeMasterNode(master_node => $masternode);
#}
1;
__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
