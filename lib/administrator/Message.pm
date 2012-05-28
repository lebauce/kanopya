# Message.pm - This object allows to manipulate Message with user interface
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
# Created 3 sept 2010
package Message;
use base 'BaseDB';

use strict;
use warnings;
use DateTime;

use Administrator;
use Kanopya::Exceptions;
use General;
use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    user_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
    message_from => {
        pattern      => '^.{32}$',
        is_mandatory => 1,
        is_extended  => 0
    },
    message_creationdate => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    message_creationtime => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    message_level => {
        pattern      => '^.{32}$',
        is_mandatory => 1,
        is_extended  => 0
    },
    message_content => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getMessages {
    my $class = shift;
    my %args = @_;
    my @objs = ();
    my ($rs);

    General::checkParams(args => \%args, required => ['hash']);

    my $adm = Administrator->new();
    
    $rs = $adm->_getDbixFromHash( table => "Message", hash => $args{hash} );


    while ( my $row = $rs->next ) {
        my $id = $row->get_column("message_id");
        my $obj = eval { Message->get(id => $id); }; 
        if($@) {
            my $exception = $@; 
            if(Kanopya::Exception::Permission::Denied->caught()) {
                next;
            } 
            else { $exception->rethrow(); } 
        }
        else {push @objs, $obj; }
    }
    return  \@objs;
}


sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};
    
    General::checkParams(args => \%args, required => ['level', 'from', 'content']);
    
    my $adm = Administrator->new();
    $self->{_dbix} = $adm->_newDbix( table => 'Message', row => {
                                                                user_id => $adm->{_rightschecker}->{_user},
                                                                message_from => $args{from},
                                                                message_creationdate => \"CURRENT_DATE()",
                                                                message_creationtime => \"CURRENT_TIME()",
                                                                message_level => $args{level},
                                                                message_content => $args{content}});
    bless $self, $class;
    return $self;
}

sub send {
    my $class = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['level', 'from', 'content']);

    my $msg = Message->new(%args);
    $msg->save();
}

sub save {
    my $self = shift;

    my $newmessage = $self->{_dbix}->insert;
}

1;
