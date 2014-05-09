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

=pod
=begin classdoc

Add a host to the system.

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EAddHost;
use base EEntity::EOperation;

use strict;
use warnings;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;


=pod
=begin classdoc

Check if the host manager is defined in the context.

=end classdoc
=cut

sub check {
    my ($self, %args) = @_;

    General::checkParams(args => $self->{context}, required => [ "host_manager" ]);
}


=pod
=begin classdoc

Call the host manager to create the new host.

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;

    my $host = $self->{context}->{host_manager}->createHost(%{ $self->{params} }, erollback => $self->{erollback});

    $log->info("Host <" . $host->id . "> is now created");
}


1;
