# ELaunchSCOWorkflow.pm - Launch a SCP Workflow

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
# Created 30 may 2012

=head1 NAME

EOperation::ELaunchSCOWorkflow - Operation class implementing SCO workflow launching

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement SCO workflow launching

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::ELaunchSCOWorkflow;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EFactory;

use Template;
#use Entity::ServiceProvider::Inside::Cluster;
#use Entity::Host;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 prepare

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{params}, required => [
        'output_directory',
        'output_file',
        'workflow_values',
    ]);
    
}

sub execute{
    my $self = shift;
    $self->SUPER::execute();
   
    my $output_directory = $self->{params}->{output_directory};
    my $output_file      = $self->{params}->{output_file};
    my $template_content = $self->{params}->{template_content};
    my $wf_values        = $self->{params}->{workflow_values};

    
    
    my $template_conf = {
        INTERPOLATE  => 0,               # expand "$wf_values" in plain text
        POST_CHOMP   => 0,               # cleanup whitespace
        EVAL_PERL    => 1,               # evaluate Perl code blocks
        ABSOLUTE     => 1,
    };
    
    my $tt = Template->new($template_conf) || die $Template::ERROR,"\n";
    my $output_path = $output_directory.'/'.$output_file;
    $tt->process(\$template_content, $wf_values, $output_path) or throw Kanopya::Exception::Internal(
                     error => "Error when processing template $template_content in $output_path : ".$tt->error()
                 );
}



=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Executor package so refers to Executor configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item Kanopya::Exception module used to throw exceptions managed by handling programs

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut
1;
