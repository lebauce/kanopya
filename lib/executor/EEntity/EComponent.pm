#    Copyright 2011 Hedera Technology SAS
#
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

=pod
=begin classdoc

Execution lib for Component class inherited by components.

@since    2010-Nov-23
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EComponent;
use base "EEntity";

use strict;
use warnings;

use Data::Dumper;
use String::Random;
use Template;
use File::Basename qw(fileparse);
use File::Spec qw(rel2abs);
use File::Temp qw/ tmpnam /;
use Log::Log4perl "get_logger";

use General;
use EEntity;

my $log = get_logger("");
my $errmsg;


=pod
=begin classdoc

Install the system service corresponding to the component on the mounted system image.

@param mountpoint the directory where is mounted the system image
@param scriptname the name of the service script to install

=end classdoc
=cut

sub addInitScripts {
    my ($self, %args) = @_;
    
    General::checkParams(args => \%args, required => [ 'mountpoint', 'scriptname' ]);

    my $cmd = "chroot $args{mountpoint} /sbin/insserv -d $args{scriptname}";
    $self->_host->getEContext->execute(command => $cmd);
}


=pod
=begin classdoc

Generate a file using a template file and data, and send it to the desired location using econtext

=end classdoc
=cut

sub generateFile {
    my $self = shift;
    my %args = @_;

    General::checkParams(
        args => \%args,
        required => [ 'file', 'template_dir', 'template_file', 'data' ],
        optional => { host => undef, keep_file => 0,
                      mode => undef, user => undef, group => undef }
    );

    $args{host} = $args{host} || $self->_host;
    $args{template_dir} = File::Spec->rel2abs($args{template_dir},
                                              Kanopya::Config::getKanopyaDir() . '/templates');

    my $config = General::getTemplateConfiguration();
    $config->{INCLUDE_PATH} = $args{template_dir};

    my $template = Template->new($config);
    my ($fh, $path) = tmpnam();

    eval {
        $template->process($args{template_file}, $args{data}, $fh) || die $template->error(), "\n";
    };
    if ($@) {
        $errmsg = "error during generation from '$args{file}':" .  $template->error;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    };

    $args{host}->getEContext->send(src   => $path,
                                   dest  => $args{file},
                                   mode  => $args{mode},
                                   user  => $args{user},
                                   group => $args{group});

    close($fh);
    unlink $path;

    return $args{file};
}


=pod
=begin classdoc

Generate a file on a remote host.

@return the econtext instance

=end classdoc
=cut

sub generateNodeFile {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'file', 'template_dir', 'template_file', 'data' ],
        optional => { host => undef, send => 0, mount_point => '',
                      mode => undef, user => undef, group => undef }
    );

    $args{host} = $args{host} || EEntity->new(entity => $self->getMasterNode->host);

    my $path = $self->_executor->getConf->{clusters_directory} . '/' .
               $args{host}->node->node_hostname . '/' . $args{file};

    my ($filename, $directories, $prefix) = fileparse($path);
    $self->_host->getEContext->execute(command => "mkdir -p $directories");

    $self->generateFile(
        template_dir  => $args{template_dir},
        template_file => $args{template_file},
        content       => $args{content},
        file          => $path,
        mode          => $args{mode},
        user          => "puppet",
        group         => "puppet",
        data          => $args{data},
    );

    if ($args{mount_point}) {
        $self->_host->getEContext->send(
            src   => $path,
            dest  => $args{mount_point} . $args{file},
            mode  => $args{mode},
            user  => $args{user},
            group => $args{group}
        );
    }

    if ($args{send}) {
        $args{host}->getEContext->send(src   => $path,
                                       dest  => $args{file},
                                       mode  => $args{mode},
                                       user  => $args{user},
                                       group => $args{group});
    }

    return $path;
}

sub generateConfiguration {}

sub configureNode {}

sub preStartNode {}
sub readyNodeAddition { return 1; }
sub postStartNode {}

sub preStopNode {}
sub readyNodeRemoving { return 1; }
sub postStopNode {}

sub cleanNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    eval { $self->preStopNode(%args); };
    eval { $self->stopNode(%args); };
    eval { $self->postStopNode(%args); };
}

=pod
=begin classdoc

Base method to test if component is available. Basically check if the component
is up on its master node.

Should be overriden in conrete component to replace or improve
the check the availability of the component.

=end classdoc
=cut

sub isAvailable {
    my ($self, %args) = @_;

    return $self->isUp(node => $self->getMasterNode());
}


=pod
=begin classdoc

Check the network availability of the component on a node, could
execute commands defined in the concrete components to ensure the system
availability on the specified node.

@param node the node where to test the component availability

=end classdoc
=cut

sub isUp {
    my ($self, %args) = @_;

    General::checkParams( args => \%args, required => [ 'node' ] );

    my $availability = 1;
    my $execution_list = $self->getExecToTest(node => $args{node});
    my $net_conf = $self->getNetConf();

    # Test executable
    foreach my $i (keys %$execution_list) {
        my $ret;
        eval {
            $ret = $args{node}->getEContext->execute(command => $execution_list->{$i}->{cmd});
        };
        if ($@ || (not defined $ret->{stdout}) || $ret->{stdout}  !~ m/($execution_list->{$i}->{answer})/) {
            return 0;
        }
    }

    # Test Services
    my $ip = $args{node}->adminIp;
    while (my ($daemon, $conf) = each %$net_conf) {
        my $cmd = "nmap -n ";
        PROTO:
        foreach my $proto (@{$conf->{protocols}}) {
            next PROTO if ($proto eq "ssl");
            if ($proto eq "udp") {
                $cmd .= "-sU ";
            }
            else {
                $cmd .= "-sT ";
            }
            $cmd .= "-p " . $conf->{port} . " $ip | grep " . $conf->{port} . " | cut -d\" \" -f2";
            my $result = $self->_host->getEContext->execute(command => $cmd);
            my $port_state = $result->{stdout};
            chomp($port_state);
            if ($port_state eq "closed") {
                return 0;
            }
        }
    }
    return 1;
}


=pod
=begin classdoc

Return the econtext instance to connect on the master node.

=end classdoc
=cut

sub getEContext { 
    my ($self) = @_;

    return $self->SUPER::getEContext(dst_ip => $self->getMasterNode->adminIp);
}


=pod
=begin classdoc

Apply the component configuration on all nodes where it is running.

=end classdoc
=cut

sub applyConfiguration {
    my ($self, %args) = @_;

    my $tags = $args{tags} || [ 'kanopya::' . lc($self->component_type->component_name) ];

    my $puppet = $self->getMasterNode->getComponent(category => "Configurationagent");
    return EEntity->new(entity => $puppet)->applyConfiguration(nodes => $self->getActiveNodes(),
                                                               tags  => $tags);
}

1;
