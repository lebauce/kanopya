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

=pod

=begin classdoc

Factory to create local/remote econtext for command execution.

@since    2010-Nov-23
@instance hash
@self     $self

=end classdoc

=cut

package EContext;

use EContext::Local;
use EContext::SSH;
use EEntity;

use strict;
use warnings;


=pod

=begin classdoc

@constructor

Create an EContext object to execute local/remote commands on hosts.
The constructir a the base class is a factory that instanciate the
proper type in function of sourec host ans dest host paramaters.

@param src_host the source host that from which commands are executed
@param dst_host the destination host that on which commands are executed

@return a class instance

=end classdoc

=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'src_host', 'dst_host' ],
                                         optional => { key => undef, timeout => 30 });

    # If the destination host is different then the source one,
    # use a SSH econtext to excecute remote commands.
    if ($args{src_host}->id != $args{dst_host}->id) {
        return EContext::SSH->new(ip      => $args{dst_host}->adminIp,
                                  key     => $args{key},
                                  timeout => $args{timeout});
    }
    # Use a local econtext instead.
    else {
        return EContext::Local->new();
    }
}

=cut

=pod

=begin classdoc

Execute a command on a host.
This method must be implemented in child classes

=end classdoc

=cut

sub execute {}


=cut

=pod

=begin classdoc

Send (copy) a file on a host.
This method must be implemented in child classes

=end classdoc

=cut

sub send {}

=pod

=begin classdoc

Check if a command exists in the context

@param command the name of the command

@return the local path of the software using the which command or an emtpy string if the command doesn't exist

=end classdoc

=cut

sub which {

    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "command" ]);

    my $result = $self->execute(command => 'which ' . $args{command});

    chomp $result->{stdout};

    return $result->{stdout};
}

1;
