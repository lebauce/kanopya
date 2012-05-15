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
=head1 NAME

EEntity::EComponent::EIscsitarget1 - EIscsitarget1 executor class.

=head1 SYNOPSIS

None for moment

=head1 DESCRIPTION

None for the moment

=head1 METHODS

=cut

package EEntity::EComponent::EIscsitarget1;
use base "EExportManager";
use base "EEntity::EComponent";

use warnings;
use strict;

use General;
use EFactory;
use Entity::ContainerAccess::IscsiContainerAccess;

use Kanopya::Exceptions;

use Template;
use String::Random;

use Date::Simple (':all');
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

=head2 createExport

    Desc : This method allow to create a new export in 1 call

=cut

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'container', 'export_name' ]);

    # TODO: Check if the given container is provided by the same
    #       storage provider than the iscsi storage provider.

    my $typeio = General::checkParam(args => \%args, name => 'typeio', default => 'fileio');
    my $iomode = General::checkParam(args => \%args, name => 'iomode', default => 'wb');

    my $disk_targetname = $self->generateTargetname(name => $args{export_name});
    my $device          = $args{container}->getAttr(name => 'container_device');

    $self->addTarget(target_name => $disk_targetname);

    my $lun_id = $self->addLun(
                     number      => 0,
                     device      => $device,
                     typeio      => $typeio,
                     iomode      => $iomode,
                     target_name => $disk_targetname,
                 );

    my $entity = Entity::ContainerAccess::IscsiContainerAccess->new(
                     container_id            => $args{container}->getAttr(name => 'container_id'),
                     export_manager_id       => $self->_getEntity->getAttr(name => 'entity_id'),
                     container_access_export => $disk_targetname,
                     container_access_ip     => $self->_getEntity->getServiceProvider->getMasterNodeIp,
                     container_access_port   => 3260,
                     typeio                  => $typeio,
                     iomode                  => $iomode,
                     lun_name                => "lun-0"
                 );
    my $container_access = EFactory::newEEntity(data => $entity);

    $self->generate();

    $log->info("Added iSCSI Export of device <$device> with target <$disk_targetname>");

    if (exists $args{erollback}) {
        $args{erollback}->add(
            function   => $self->can('removeExport'),
            parameters => [ $self, "container_access", $container_access ]
        );
    }

    return $container_access;
}

=head2 removeExport

    Desc : This method allow to remove an export in 1 call

=cut

sub removeExport {
    my $self = shift;
    my %args = @_;
    my ($lun, $container);

    General::checkParams(args => \%args, required => [ 'container_access' ]);

    if (! $args{container_access}->isa("EEntity::EContainerAccess::EIscsiContainerAccess")) {
        throw Kanopya::Exception::Internal::WrongType(
                  error => "ContainerAccess must be a EEntity::EContainerAccess::EIscsiContainerAccess, not " . 
                           ref($args{container_access})
              );
    }

    my $target_name = $args{container_access}->getAttr(name => 'container_access_export');
    my $lun_typeio;
    my $lun_iomode;

    $self->removeTarget(target_name => $target_name);

    if (exists $args{host_initiatorname} and defined $args{host_initiatorname}) {
        $self->cleanInitiatorSession(initiator => $args{host_initiatorname});
    }

    $args{container_access}->delete();

    # Regenerate configuration
    $self->generate();
}

sub generateInitiatorname {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'hostname' ]);

    my $today = today();
    my $res = "iqn." . $today->year . "-" . $today->format("%m") .
              ".com.hedera-technology." . $args{hostname};

    $log->info("InitiatorName generated is $res");
    return $res;
}

sub generateTargetname {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'name' ]);

    my $today = today();
    my $res = "iqn." . $today->year . "-" . $today->format("%m") .
              ".com.hedera-technology.nas:$args{name}";

    $log->info("TargetName generated is $res");
    return $res;
}

sub generateNameFromTarget {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'target_name' ]);

    return $args{'target_name'} =~ s/.*\://g;
}

sub addTarget {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'target_name' ]);

    my $cmd = "grep tid: /proc/net/iet/volume | sed 's/tid:\\(\[0-9\]\*\\) .*/\\1/'";
    my $result = $self->getEContext->execute(command => $cmd);

    my $tid;
    if ($result->{stdout} eq "") {
        $tid = 0;
    }
    else {
        my @tab = split(/\s/, $result->{stdout});
        $tid = $tab[0];
        $tid += 1;
    }

    # Create the new target
    $cmd = "ietadm --op new --tid=$tid --params Name=$args{target_name}";
    $result = $self->getEContext->execute(command => $cmd);
}

sub gettid {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'target_name' ]);

    my $result = $self->getEContext->execute(
                     command => "grep \"$args{target_name}\" /proc/net/iet/volume"
                 );

    if ($result->{stdout} eq "") {
        $errmsg = "EComponent::EIscsitarget1->gettid : no target name found for $args{target_name}!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my @t1 = split(/\s/, $result->{stdout});
    my @t2 = split(/:/, $t1[0]);
    my $tid = $t2[1];

    $log->debug("Tid found <$tid> for target <$args{target_name}>");
    return $tid;
}

sub reload {
    my $self = shift;
    $self->generateConf();
}

sub addLun {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "device", "number", "typeio",
                                       "iomode", "target_name" ]);

    my $tid = $self->gettid(target_name => $args{target_name});

    my $command = "ietadm --op new --tid=$tid " .
                  "--lun=$args{number} --params " .
                  "Path=$args{device}," .
                  "Type=$args{typeio}," .
                  "IOMode=$args{iomode}";

    my $result = $self->getEContext->execute(command => $command);
}

sub removeTarget {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'target_name' ]);

    # First we clean sessions for this target
    my $tid = $self->cleanTargetSession(targetname => $args{target_name});

    if (defined $tid) {
        my $result = $self->getEContext->execute(command => "ietadm --op delete --tid=$tid");
    }
}

=head2 _getIetdSessions

    return an arrayref contening /proc/net/iet/session content

=cut

sub _getIetdSessions {
    my $self = shift;
    my %args = @_;

    my $target_regexp = qr/^tid:([0-9]+)\sname:(.+)/;
    my $session_regexp = qr/^\tsid:([0-9]+)\sinitiator:(.*)/;
    my $connection_regexp = qr/^\t\tcid:([0-9]+)\sip:(.+)state:(.+)\shd:(.+)\sdd:(.+)/;

    my $result = $self->getEContext->execute(command => 'cat /proc/net/iet/session');
    my @output = split(/\n/, $result->{stdout});

    my ($target, $session, $connection);
    my $ietdsessions = [];

    foreach my $line (@output) {
        if ($line =~ $target_regexp) {
            push @$ietdsessions, {
                tid        => $1,
                targetname => $2,
                sessions   => []
            };
        } elsif ($line =~ $session_regexp) {
            push @{$ietdsessions->[-1]->{sessions}}, {
                sid         => $1,
                initiator   => $2,
                connections => []
            };
        } elsif ($line =~ $connection_regexp) {
            push @{$ietdsessions->[-1]->{sessions}->[-1]->{connections}}, {
                cid   => $1,
                ip    => $2,
                state => $3,
                hd    => $4,
                dd    => $5
            };
        }
    }

    return $ietdsessions;
}

=head2 cleanTargetSession

    try to remove any sessions on a target

=cut

sub cleanTargetSession {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'targetname' ]);

    # first, we get actual sessions
    my $ietdsessions = $self->_getIetdSessions();

    # next we clean existing sessions on this target
    foreach my $target (@$ietdsessions) {
        if ($target->{targetname} eq $args{targetname}) {
            foreach my $session (@{$target->{sessions}}) {
                for my $connection (@{$session->{connections}}) {
                    my $command = "ietadm --op delete --tid=$target->{tid} " .
                                  "--sid=$session->{sid} --cid=$connection->{cid}";
                    my $result = $self->getEContext->execute(command => $command);
                    # TODO: Check return code
                }
            }
            return $target->{tid};
        }
        else { next; }
    }
}

=head2 cleanInitiatorSession

    try to remove all sessions for an initiator

=cut

sub cleanInitiatorSession {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'initiator' ]);

    # first, we get actual sessions
    my $ietdsessions = $self->_getIetdSessions();

    # next we clean existing sessions for the given initiatorname
    foreach my $target (@$ietdsessions) {
        foreach my $session (@{$target->{sessions}}) {
            if(($session->{initiator} eq $args{initiator}) || !$session->{initiator}) {
                for my $connection (@{$session->{connections}}) {
                    my $command = "ietadm --op delete --tid=$target->{tid} " .
                                  "--sid=$session->{sid} --cid=$connection->{cid}";
                    my $result = $self->getEContext->execute(command => $command);
                    # TODO: check return code
                }
            } else { next; }
        }
    }
}

# generate /etc/ietd.conf configuration file
sub generate {
    my $self = shift;
    my %args = @_;

    my $data = $self->getTemplateData();

    $self->generateFile(mount_point  => "/etc",
                        template_dir => "/templates/components/ietd",
                        input_file   => "ietd.conf.tt",
                        output       => "/iet/ietd.conf",
                        data         => $data);

    if (exists $args{erollback}) {
        $args{erollback}->add(
            function   => $self->can('generate'),
            parameters => [ $self ]
        );
    }
}

1;
