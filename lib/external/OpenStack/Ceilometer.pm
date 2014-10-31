#    Copyright © 2014 Hedera Technology SAS
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

Implement Openstack API Compute operations related to Ceilometer

=end classdoc
=cut

package OpenStack::Ceilometer;

use strict;
use warnings;

use General;
use JSON;
=pod
=begin classdoc

Lists all available resources

=end classdoc
=cut

sub list {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ]);
    my $output = $args{api}->metering->meters->get;
    return OpenStack::API->handleOutput(output => $output);
}

=pod
=begin classdoc

Lists all available resources

=end classdoc
=cut

sub detail {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api', 'id' ]);
    my $output = $args{api}->metering->resources(id => $args{id})->get;
    return OpenStack::API->handleOutput(output => $output);
}

sub retrieve {
    my ($self, %args) = @_;
    General::checkParams(
        args => \%args,
        required => [ 'api', 'meters', 'hostnames' ],
        optional => { limit => scalar @{$args{hostnames}} * scalar @{$args{meters}}},
    );

    my $limit = $args{limit};

    if ((scalar @{$args{hostnames}} eq 0) or (scalar @{$args{meters}} eq 0)) {
        return {};
    }

    my $filter = {and => []};

    if (scalar @{$args{meters}} eq 1) {
        $filter->{and}->[0] = {'=' => {counter_name => $args{meters}->[0]}};
    }
    else {
         $filter->{and}->[0] = {or => []};
        for my $name (@{$args{meters}}) {
            push @{$filter->{and}->[0]->{or}}, {'=' => {counter_name => $name}};
        }
    }

    if (scalar @{$args{hostnames}} eq 1) {
        $filter->{and}->[1] = {'=' => {'metadata.display_name' => $args{hostnames}->[0]}};
    }
    else {
        $filter->{and}->[1] = {or => []};
        for my $name (@{$args{hostnames}}) {
            push @{$filter->{and}->[1]->{or}}, {'=' => {'metadata.display_name' => $name}};
        }
    }

    my $content = {};
    $content->{filter} = JSON->new->utf8->encode($filter);
    $content->{limit} = $args{limit};


    my $output = $args{api}->metering->query->samples->post(content => $content);
    $output = OpenStack::API->handleOutput(output => $output);

    my $meters = {};
    for my $data (@$output) {
        $meters->{$data->{metadata}->{display_name}}->{$data->{meter}} = $data;
    }
    return $meters;
}

1;
