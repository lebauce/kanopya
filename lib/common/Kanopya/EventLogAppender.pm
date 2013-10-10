#    Copyright © 2012 Hedera Technology SAS
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

package Kanopya::EventLogAppender;

use strict;
use warnings;

use Win32::EventLog;

sub new {
    my ($class, %params) = @_;

    if (not defined($params{source})) {
        $params{source} = 'Kanopya';
    }
    my $self = {
        'handle' => Win32::EventLog->new($params{source})
    };

    bless $self, $class;
}

sub name {
    return 'Win32EventLog';
}

sub log {
    my ($self, %params) = @_;

    if (defined($self->{handle})) {
        my $eventtype  = EVENTLOG_INFORMATION_TYPE;
        if ($params{level} == 3) {
            $eventtype = EVENTLOG_WARNING_TYPE;
        }
        elsif ($params{level} == 4) {
            $eventtype = EVENTLOG_ERROR_TYPE;
        }

        $self->{handle}->Report({
                EventType => $eventtype,
                EventID   => $params{level},
                Strings   => $params{message}
            });
    }
}

1;
