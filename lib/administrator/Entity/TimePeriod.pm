#    Copyright © 2013 Hedera Technology SAS
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

package Entity::TimePeriod;
use base "Entity";

use strict;
use warnings;

use Data::Dumper;
use DateTime;
use DateTime::Duration;
use DateTime::Set;
use DateTime::Format::HTTP;
use Set::IntervalTree;
use DateTime::Infinite;

use constant ATTR_DEF => {
    time_period_name => {
        label        => 'Name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    param_preset_id => {
        label        => 'Param preset',
        type         => 'relation',
        relation     => 'single',
        is_mandatory => 0,
        is_editable  => 1,
    },
    limits => {
        is_virtual   => 1,
    }
};

use constant {
    HOURLY   => "Hourly",
    DAILY    => "Daily",
    WEEKLY   => "Weekly",
    MONTHLY  => "Monthly",
    WEEKDAYS => "Every weekday",
};

sub getAttrDef { return ATTR_DEF };

sub methods {
    return {
        normalizeEvents => {
            description => 'given an array of events return an array of time intervals'
        },
    };
}

sub limits {
    return shift->param_preset->load()->{limits};
}

sub normalizeEvents {
    my ($self, %args) = @_;

    my $dt;
    my $iter = $self->toSpanSet(except => 0, %args)->iterator;
    my $spans = [];
    while ($dt = $iter->next) {
        push @{$spans}, { start => "" . $dt->start,
                          end   => "" . $dt->end };
    };

    return $spans;
}

sub toSpanSet {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { except => 1 });

    my $spansets = DateTime::SpanSet->from_spans(spans => []);
    my $limits = $args{limits} || $self->param_preset->load()->{limits};
    my $tree = Set::IntervalTree->new;
    my $from = $args{from};
    my $to = $args{to};

    for my $limit (@{$limits}) {
        my $start = DateTime::Format::HTTP->parse_datetime($limit->{start});
        my $end = DateTime::Format::HTTP->parse_datetime($limit->{end});
        my $ends_on = $limit->{ends_on}
                      ? DateTime::Format::HTTP->parse_datetime($limit->{ends_on})
                      : undef;
        my $type = $limit->{type};
        my $frequency = $limit->{repeat};
        my $every = $limit->{every} || 1;
        my $count = $limit->{count};
        my $time = $start;
        my $except = $limit->{except} || [];
        my $duration = $end - $start;
        my $delay;
        my %args;
        my $dates;
        my $span;

        $start->set_time_zone('local');
        $end->set_time_zone('local');

        if ($frequency) {
            if ($frequency eq DAILY) {
                $args{days} = 1 * $every;
            }
            elsif ($frequency eq WEEKLY) {
                $args{weeks} = 1 * $every;
            }
            elsif ($frequency eq MONTHLY) {
                $args{months} = 1 * $every;
            }
            elsif ($frequency eq WEEKDAYS) {
                $args{days} = 1;
            }

            if ($limit->{ends_on}) {
                $span = DateTime::Span->from_datetimes(start => $start, end => $ends_on);
            }
            else {
                # For some reason, we can't exceed 30 weeks for the end date
                $span = DateTime::Span->from_datetimes(start => $start,
                                                       end   => $start + DateTime::Duration->new(months => 6));
            }
        }

        if ($frequency) {
            $dates = DateTime::Set->from_recurrence( 
                         recurrence => sub {
                             return $_[0]->add(%args)
                         },
                         span => $span
                     );

            if ($count) {
                $dates = $dates->grep(sub { return ($count-- > 0); });
            }

            my $index = 0;
            if ($args{except} && $except) {
                $dates = $dates->grep(sub {
                    my @skip = grep { $_ == $index } @{$except};
                    $index++;
                    return (scalar @skip) == 0;
                } );
            }

            if ($frequency eq WEEKDAYS) {
                $dates = $dates->grep(sub { return ( $_->day_of_week <= 5 ); });
            }

            my $spanset = DateTime::SpanSet->from_set_and_duration(set      => $dates,
                                                                   duration => $duration);

            my $total_span = DateTime::SpanSet->from_spans(spans => [ $span ]);
            $spanset = $spanset->intersection($total_span);

            $spansets = $spansets->union($spanset);
        }
        else {
            # Sporadic event
            $tree->insert($limit->{id},
                          $start, $end);
        }
    }

    return $spansets;
}

sub isActive {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'timestamp' => "" . DateTime->now });

    my $timestamp = DateTime::Format::HTTP->parse_datetime($args{timestamp});
    $timestamp->set_time_zone('local');

    return $self->toSpanSet->contains($timestamp);
}

sub displaySpanSet {
    my $self = shift;

    my $dt;
    my $iter = $self->toSpanSet->iterator;
    while ($dt = $iter->next) {
        print $dt->start . " " . $dt->end . "\n";
    };
}

1;

