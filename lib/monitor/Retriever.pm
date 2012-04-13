# Retriever.pm - Object class of retriever

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
# Created 20 august 2010

=head1 NAME

Retriever - Retriever object

=head1 SYNOPSIS

    use Retriever;
    
    # Creates monitor
    my $retriever = Retriever->new();

=head1 DESCRIPTION

Abstract class defining an object retrieving informations from a data collector (kanopya collector or external monitoring tool).
Provide collected counter values of monitored objects.

=head1 METHODS

=cut

package Retriever;

use strict;
use warnings;

1;
