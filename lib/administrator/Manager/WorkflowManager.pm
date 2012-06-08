# CollectorManager.pm - Object class of Collector Manager included in Administrator

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
# Created 7 June 2012

package Manager::WorkflowManager;
use base "Manager";

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use General;

my $log = get_logger("administrator");

=head2 checkManagerParams

=cut

sub checkWorkflowManagerParams { };

sub createWorkflow { };
sub instanciateWorkflow { };
sub getSpecificWorkflowParameters { };
sub runWorkflow { };

1;