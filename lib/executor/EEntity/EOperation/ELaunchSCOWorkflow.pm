#    Copyright © 2011 Hedera Technology SAS
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

package EEntity::EOperation::ELaunchSCOWorkflow;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EEntity;
use Template;

my $log = get_logger("");
my $errmsg;


sub check {
    my $self = shift;
    my %args = @_;
    $self->SUPER::check();

    General::checkParams(args     => $self->{params},
                         required => [ 'output_directory', 'output_file', 'template_content' ],
                         optional => { 'period' => 600 });
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
    $tt->process(\$template_content, $wf_values, $output_path)
        or throw Kanopya::Exception::Internal(
                     error => "Error when processing template $template_content in $output_path : ". $tt->error()
                 );

    #append the return file to the generated file
    my $return_file = $output_path.'_return';
    open (my $FILE, ">>", $output_path)
        or die "an error occured while opening $output_path: $!";
    print $FILE "\n".$return_file;
    close($FILE);

    #put the return file into operation params
    $self->{params}->{return_file} = $return_file;
}

sub postrequisites {
    my $self = shift;

    #get absolute return file path (on local machine)
    if (-e $self->{params}->{return_file}) {
        return 0;
    }
    else {
        return $self->{params}->{period};
    }
}

1;
