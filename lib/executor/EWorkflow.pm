# Copyright © 2011 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EWorkflow;

use strict;
use warnings;

use Kanopya::Exceptions;
use Operation;
use EFactory;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

use vars qw ( $AUTOLOAD );

sub _getWorkflow{
    my $self = shift;
    return $self->{_workflow};
}

sub new {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'data', 'config' ]);

    my $self = {
        config    => $args{config},
        _workflow => $args{data},
        _executor => Entity->get(id => $args{config}->{cluster}->{executor})
    };

    bless $self, $class;

    return $self;
}

sub cancel {
    my $self = shift;
    my %args = @_;

    # TODO: filter on states to get operation to cancel only.
    my @operations = Operation->search(hash => {
                         workflow_id => $self->getAttr(name => 'workflow_id'),
                     });

    for my $operation (@operations) {
        if ($operation->getAttr(name => 'state') ne 'pending') {
            eval {
                $operation->unlockContext();
                EFactory::newEOperation(op => $operation, config => $self->{config})->cancel();
            };
            if ($@){
                $log->error("Error during operation cancel :\n$@");
            }
        }
        $operation->delete();
    }

    $self->setState(state => 'cancelled');
}

sub getEContext {
    my $self = shift;

    return EFactory::newEContext(ip_source      => $self->{_executor}->getMasterNodeIp(),
                                 ip_destination => $self->{_executor}->getMasterNodeIp());
}

sub AUTOLOAD {
    my $self = shift;
    my %args = @_;

    my @autoload = split(/::/, $AUTOLOAD);
    my $method = $autoload[-1];

    return $self->_getWorkflow->$method(%args);
}

sub DESTROY {
    my $self = shift;
    my %args = @_;
}

1;
