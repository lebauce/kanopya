#    Copyright © 2011-2013 Hedera Technology SAS
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

package Message;
use base 'BaseDB';

use strict;
use warnings;

use Kanopya::Exceptions;
use General;
use DateTime;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    user_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
    message_from => {
        pattern      => '^.{0,32}$',
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
        pattern      => '^.{0,32}$',
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

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};

    General::checkParams(args => \%args, required => [ 'level', 'from', 'content' ]);

    return $class->SUPER::new(
               message_from         => $args{from},
               message_level        => $args{level},
               message_content      => $args{content},
               message_creationdate => \"CURRENT_DATE()",
               message_creationtime => \"CURRENT_TIME()",
               # The user id will be automatically set by the ORM
               user_id              => undef,
           );
}

sub send {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'level', 'from', 'content' ]);

    my $msg = Message->new(%args);
}

1;
