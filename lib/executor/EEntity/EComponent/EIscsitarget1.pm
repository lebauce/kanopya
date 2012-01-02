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

use strict;
use Date::Simple (':all');
use Log::Log4perl "get_logger";
use Template;
use String::Random;
use General;

use base "EEntity::EComponent";

my $log = get_logger("executor");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub generateInitiatorname{
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => ['hostname']);

    my $today = today();
    my $res = "iqn." . $today->year . "-" . $today->format("%m") . ".com.hedera-technology." . $args{hostname};
    $log->info("InitiatorName generated is $res");
    return $res;
}
sub generateTargetname {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => ['name']);

    my $today = today();
    my $res = "iqn." . $today->year . "-" . $today->format("%m") . ".com.hedera-technology.nas:$args{name}";
    $log->info("TargetName generated is $res");
    return $res;
}

# This method allow to create a new export in 1 call
sub createExport {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args,
                         required => ['export_name','econtext',
                                      'device_name', 'typeio',
                                      'iomode', 'erollback']);

    my $disk_targetname = $self->generateTargetname(name => $args{export_name});

    $self->addExport(iscsitarget1_lun_number    => 0,
                     iscsitarget1_lun_device    => $args{device_name},
                     iscsitarget1_lun_typeio    => $args{typeio},
                     iscsitarget1_lun_iomode    => $args{iomode},
                     iscsitarget1_target_name   => $disk_targetname,
                     econtext                   => $args{econtext},
                     erollback                  => $args{erollback});
    my $eroll_add_export = $args{erollback}->getLastInserted();

    $args{erollback}->insertNextErollBefore(erollback=>$eroll_add_export);
    $self->generate(econtext  => $args{econtext},
                    erollback => $args{erollback});
    $log->info("Add IScsi Export of device <$self->{params}->{device}>");
}

sub addExport {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args,
                         required => ['iscsitarget1_lun_number','econtext',
                                      'iscsitarget1_lun_device', 'iscsitarget1_lun_typeio',
                                      'iscsitarget1_target_name', 'iscsitarget1_lun_iomode']);


    my $target_id = $self->addTarget(iscsitarget1_target_name   =>$args{iscsitarget1_target_name},
                                     econtext                   =>$args{econtext});

    my $lun_id = $self->addLun(iscsitarget1_target_id    => $target_id,
                                                iscsitarget1_lun_number    => $args{iscsitarget1_lun_number},
                                                iscsitarget1_lun_device    => $args{iscsitarget1_lun_device},
                                                iscsitarget1_lun_typeio    => $args{iscsitarget1_lun_typeio},
                                                iscsitarget1_lun_iomode    => $args{iscsitarget1_lun_iomode},
                                                iscsitarget1_target_name=> $args{iscsitarget1_target_name},
                                                econtext                 => $args{econtext});
    if(exists $args{erollback}) {
        $args{erollback}->add(function   =>$self->can('removeExport'),
                              parameters => [$self,
                                               "iscsitarget1_lun_id", $lun_id,
                                               "iscsitarget1_target_name", $args{iscsitarget1_target_name},
                                               "iscsitarget1_target_id", $target_id,
                                               "econtext", $args{econtext}]);
    }
}

sub removeExport {
    my $self = shift;
    my %args  = @_;
    my $lun;
    my $log_content;

    General::checkParams(args => \%args,
                         required => ['iscsitarget1_lun_id','econtext',
                                      'iscsitarget1_target_name', 'iscsitarget1_target_id']);

    if(exists $args{erollback}) {
        $lun = $self->_getEntity()->getLun(  iscsitarget1_lun_id     => $args{iscsitarget1_lun_id},
                                                iscsitarget1_target_id  => $args{iscsitarget1_target_id});
    }
    $self->removeLun(iscsitarget1_lun_id    => $args{iscsitarget1_lun_id},
                    iscsitarget1_target_id  => $args{iscsitarget1_target_id});
    $self->removeTarget(iscsitarget1_target_id      => $args{iscsitarget1_target_id},
                        iscsitarget1_target_name    => $args{iscsitarget1_target_name},
                        econtext                    => $args{econtext});
    $log_content = "Remove Export with targetname <". $args{iscsitarget1_target_name}.">";
    if(exists $args{erollback}) {
        $args{erollback}->add(function   =>$self->can('addExport'),
                              parameters => [$self,
                                               "iscsitarget1_lun_number", $lun->{iscsitarget1_lun_number},
                                               "iscsitarget1_lun_device", $lun->{iscsitarget1_lun_device},
                                               "iscsitarget1_lun_typeio", $lun->{iscsitarget1_lun_typeio},
                                               "iscsitarget1_lun_iomode", $lun->{iscsitarget1_lun_iomode},
                                               "iscsitarget1_target_name", $args{iscsitarget1_target_name},
                                               "econtext", $args{econtext}]);
       $log_content .= " and will be rollbacked with add export of disk <" .$lun->{iscsitarget1_lun_device}.">";
    }
    $log->debug($log_content);
}

sub addTarget {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => ['iscsitarget1_target_name']);

    my $result = $args{econtext}->execute(command => "grep tid: /proc/net/iet/volume | sed 's/tid:\\(\[0-9\]\*\\) .*/\\1/'");
     my $tid;
    if ($result->{stdout} eq "") {
        $tid = 0;
    }
    else {
        my @tab = split(/\s/, $result->{stdout});
        $tid = $tab[0];
        $tid += 1;
    }
        # on cree le nouveau target
    $result = $args{econtext}->execute(command => "ietadm --op new --tid=$tid --params Name=$args{iscsitarget1_target_name}");
    delete $args{econtext};
    return $self->_getEntity()->addTarget(%args);
}

sub gettid {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => ['target_name',"econtext"]);


    my $result = $args{econtext}->execute(command =>"grep \"$args{target_name}\" /proc/net/iet/volume");
    if ($result->{stdout} eq "") {
        $errmsg = "EComponent::EIscsitarget1->gettid : no target name found for $args{target_name}!";#
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

    General::checkParams(args => \%args, required => ['iscsitarget1_target_id',"iscsitarget1_lun_number",
                                                     "iscsitarget1_lun_device","iscsitarget1_lun_typeio",
                                                     "iscsitarget1_lun_iomode","iscsitarget1_target_name",
                                                     "econtext"]);

    my $tid = $self->gettid(target_name => $args{iscsitarget1_target_name}, econtext => $args{econtext});
    delete $args{iscsitarget1_target_name};
    my $result =  $args{econtext}->execute(command => "ietadm --op new --tid=$tid --lun=$args{iscsitarget1_lun_number} --params Path=$args{iscsitarget1_lun_device},Type=$args{iscsitarget1_lun_typeio},IOMode=$args{iscsitarget1_lun_iomode}");
    delete $args{econtext};
    return $self->_getEntity()->addLun(%args);
}

sub removeLun {
    my $self = shift;
    my %args  = @_;

    #TODO In future if need we can just remove a lun.
    return $self->_getEntity()->removeLun(%args);
}

sub removeTarget {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => ['iscsitarget1_target_id',"iscsitarget1_target_name",
                                                     "econtext"]);

    $log->debug('iscsitargetname : '.$args{iscsitarget1_target_name});

    # first we clean sessions for this target
    my $tid = $self->cleanTargetSession(targetname => $args{iscsitarget1_target_name}, econtext => $args{econtext});

    my $result = $args{econtext}->execute(command =>"ietadm --op delete --tid=$tid");
    delete $args{econtext};
    return $self->_getEntity()->removeTarget(%args);
}

=head2 _getIetdSessions
    argument : econtext
    return an arrayref contening /proc/net/iet/session content

=cut

sub _getIetdSessions {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ["econtext"]);

    my $target_regexp = qr/^tid:([0-9]+)\sname:(.+)/;
    my $session_regexp = qr/^\tsid:([0-9]+)\sinitiator:(.*)/;
    my $connection_regexp = qr/^\t\tcid:([0-9]+)\sip:(.+)state:(.+)\shd:(.+)\sdd:(.+)/;

    my $result = $args{econtext}->execute(command => 'cat /proc/net/iet/session');
    my @output = split(/\n/, $result->{stdout});

    my ($target, $session, $connection);
    my $ietdsessions = [];

    foreach my $line (@output) {
        if($line =~ $target_regexp) {
            $target = { tid => $1, targetname => $2, sessions => [] };
            push(@$ietdsessions, $target);
        } elsif($line =~ $session_regexp) {
            $session = { sid => $1, initiator => $2, connections => [] };
            push(@{$ietdsessions->[-1]->{sessions}}, $session);
        } elsif($line =~ $connection_regexp) {
            $connection = { cid => $1, ip => $2, state => $3, hd => $4, dd => $5};
            push(@{$ietdsessions->[-1]->{sessions}->[-1]->{connections}}, $connection);
        }
    }
    return $ietdsessions;
}

=head2 cleanTargetSession

    argument : targetname, econtext
    try to remove any sessions on a target

=cut

sub cleanTargetSession {
    my $self = shift;
    my %args  = @_;
    General::checkParams(args => \%args, required => ['targetname',"econtext"]);

    # first, we get actual sessions
    my $ietdsessions = $self->_getIetdSessions(econtext => $args{econtext});

    # next we clean existing sessions on this target
    foreach my $target (@$ietdsessions) {
        if($target->{targetname} eq $args{targetname}) {
            foreach my $session(@{$target->{sessions}}) {
                for my $connection (@{$session->{connections}}) {
                    my $command = "ietadm --op delete --tid=$target->{tid} --sid=$session->{sid} --cid=$connection->{cid}";
                    my $result = $args{econtext}->execute(command => $command);
                    #TODO tester le retour de la commande
                }
            }
            return $target->{tid};
        }
        else { next; }
    }
    return;
}

=head2 cleanInitiatorSession

    argument : initiator, econtext
    try to remove all sessions for an initiator

=cut

sub cleanInitiatorSession {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => ['initiator',"econtext"]);

    # first, we get actual sessions
    my $ietdsessions = $self->_getIetdSessions(econtext => $args{econtext});

    # next we clean existing sessions for the given initiatorname
    foreach my $target (@$ietdsessions) {
        foreach my $session(@{$target->{sessions}}) {
			$log->info(">>>>> session initiator: $session->{initiator}");
            if(($session->{initiator} eq $args{initiator})|| !$session->{initiator}){
                for my $connection (@{$session->{connections}}) {
                    my $command = "ietadm --op delete --tid=$target->{tid} --sid=$session->{sid} --cid=$connection->{cid}";
                    my $result = $args{econtext}->execute(command => $command);
                    #TODO tester le retour de la commande
                }
            } else { next; }
        }
    }
}


# generate /etc/ietd.conf configuration file
sub generate {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ["econtext"]);

    my $data = $self->_getEntity()->getTemplateData();

    $self->generateFile( econtext => $args{econtext},
                         mount_point => "/etc",
                         template_dir => "/templates/components/ietd",
                         input_file => "ietd.conf.tt",
                         output => "/iet/ietd.conf",
                         data => $data);
    if(exists $args{erollback}){
        $args{erollback}->add(function   =>$self->can('generate'),
                              parameters => [$self,
                                             "econtext", $args{econtext}]);
    }
}

1;
