# EKanopyaMaintenance.pm - Operation class node removing from cluster operation

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

EOperation::EKanopyaMaintenance - Operation class implementing node removing operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement node removing operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EKanopyaMaintenance;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use String::Random;
use Message;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 new

EOperation::EKanopyaMaintenance->new creates a new EKanopyaMaintenance operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

    $op->_init() is a private method used to define internal parameters.

=cut

sub _init {
    my $self = shift;
    $self->{executor} = {};
    return;
}

sub checkOp{
    my $self = shift;
    my %args = @_;
    
 
}

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    $log->info("Operation preparation");

    my $messages = Message->getMessages(hash=>{});
    if (scalar @$messages < 1000) {
        $log->info("Not enough message in database to backup it");
        throw Kanopya::Exception::Internal(error => "Not enough message in database to backup it", hidden => 1);
    }
    else {
        $self->{messages} = $messages;
    }
    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "executor");
}

sub execute {
    my $self = shift;
    $log->debug("Before EOperation exec");
    $self->SUPER::execute();


########## Backup message
    my $msg_log = "";
    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");
    my $messages = $self->{messages};
    open (my $MSGTXT, ">","/tmp/$tmpfile") or throw Kanopya::Exception::Internal(error => "Kanopya could not open tmp file");
   $msg_log = "msg id\tmsg from\tdate\ttime\tlevel\tmessage content\n";
    foreach my $msg (@$messages) {
        $msg_log .= $msg->getAttr(attr_name => "message_id") . "\t";
        $msg_log .= $msg->getAttr(attr_name => "message_from") . "\t";
        $msg_log .= $msg->getAttr(attr_name => "message_creationdate") . "\t";
        $msg_log .= $msg->getAttr(attr_name => "message_creationtime") . "\t";
        $msg_log .= $msg->getAttr(attr_name => "message_level") . "\t";
        $msg_log .= $msg->getAttr(attr_name => "message_content") . "\n";
        $msg->delete();
    }
    print( $MSGTXT "$msg_log");
    close $MSGTXT;
    $self->{executor}->{econtext}->send(src => "/tmp/$tmpfile", dest => "/var/log/kanopya/msg_backup_".time());
    unlink "/tmp/$tmpfile";
    
    
}

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
