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

package Quota;
use base 'BaseDB';

use strict;
use warnings;

use Log::Log4perl 'get_logger';

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    user_id => {
        type         => 'relation',
        type         => 'single',
        pattern      => '^\d+$',
        is_mandatory => 1,
    },
    resource => {
        label        => 'Ressource type',
        type         => 'enum',
        options      => [ 'ram', 'cpu' ],
        pattern      => '^(ram|cpu)$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    current => {
        label        => 'Consumed amount',
        type         => 'string',
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_editable  => 0,
    },
    quota => {
        label        => 'Limit value',
        type         => 'string',
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);

    # Compute the current consomation value for the resource
    my @services = Entity::ServiceProvider::Inside::Cluster->search(hash => {
                       user_id => $self->user->id
                   });

    my $hostattr;
    if ($self->resource eq 'ram') {
        $hostattr = 'host_ram';
    } elsif ($self->resource eq 'cpu') {
        $hostattr = 'host_core';
    }

    my $consumed = 0;
    for my $service (@services) {
        my @nodes = $service->nodes;
        for my $node (@nodes) {
            $consumed += $node->host->$hostattr;
        }
    }
    $self->setAttr(name => 'current', value => $consumed);
    $self->save();

    return $self;
}

=head2 consume

    Consume a given amount of the quota resource.

=cut

sub consume {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'amount' ], optional => { 'dryrun' => 0 });

    # Check if the quota exceed
    if (($self->current + $args{amount}) > $self->quota) {
        throw Kanopya::Exception::Quota(
            error => "<" . $self->current . " + $args{amount}> exceed the " . $self->resource . " quota <" . $self->quota . ">"
        );
    }

    if (not $args{dryrun}) {
        # Set the new current value
        $self->setAttr(name => 'current', value => $self->current + $args{amount});
        $self->save();
    }
}

=head2 release

    Release a given amount of the quota resource.

=cut

sub release {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'amount' ]);

    # Check if the quota exceed
    if (($self->current - $args{amount}) < 0) {
        throw Kanopya::Exception::Quota(
            error => "Can not release <$args{amount}> of " . $self->resource .
                     " on the current value <" . $self->current . ">"
        );
    }

    $self->setAttr(name => 'current', value => $self->current - $args{amount});
    $self->save();
}

1;
