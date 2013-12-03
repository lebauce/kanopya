#    Copyright © 2011-2012 Hedera Technology SAS
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

The local econtext offers execute method via system builtin function.

@since    2010-Nov-23
@instance hash
@self     $self

=end classdoc

=cut

package EContext::Local;
use base "EContext";

use strict;
use warnings;

use File::Basename "dirname";
use Kanopya::Exceptions;
use General;

use Log::Log4perl "get_logger";
my $log = get_logger("command");
my $errmsg;


my $localcontext;


=pod

=begin classdoc

@constructor

Return the local econtext singleton if defined, instanciate it instead.

@return a class instance

=end classdoc

=cut

sub new {
    my ($class, %args) = @_;

    # do not reinstanciate local context, reuse 
    if(defined $localcontext) {
        return $localcontext;
    }
    my $self = {};

    bless $self, $class;
    $localcontext = $self;

    return $self;
}


=cut

=pod

=begin classdoc

Use the builtin function to execute local commands.
NOTE: don't use stderr redirection ( 2> ) in your command.

@param command the command to execute

@return the command result

=end classdoc

=cut

sub execute {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'command' ]);
    
    # command must no contain stderr redirection !
    if($args{command} =~ m/2>/) {
        $errmsg = "EContext::Local->execute : command must not contain stderr redirection (2>)!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
    }
        
    my $result = {};
    my $command = $args{command};
    $log->debug("Running command: $command");

    my $stdout = `$command 2> /tmp/EContext.stderr`;
    $result->{exitcode} = ($? >> 8);
    $result->{stdout} = $stdout;
    chop($stdout);
    $result->{stderr} = `cat /tmp/EContext.stderr`;
    my $stderr = $result->{stderr};
    chop($stderr);
    $log->debug("Command stdout is : '$stdout'");
    $log->debug("Command stderr: $stderr");
    $log->debug("Command exitcode: $result->{exitcode}");

    return $result;    
}


=cut

=pod

=begin classdoc

Use the cp command to copy the file.

@param src the source file to copy
@param dest the destionation to copy file

@return the command result

=end classdoc

=cut

sub send {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'src', 'dest' ],
                         optional => { mode => undef, user => undef,
                                       group => undef });
    
    if (not -e $args{src}) {
        $errmsg = "EContext::Local->execute src file $args{src} no found";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    my $result = {};
    my $command = "";

    $command = "mkdir -p " . dirname($args{dest});
    $command .= "; cp --preserve=mode -R $args{src} $args{dest}";
    $command .= "; chmod -R $args{mode} $args{dest}; " if $args{mode};
    $command .= "; chown -R $args{user}:$args{group} $args{dest}" if ($args{user} || $args{group});

    $log->debug("Running command: $command");
    my $stdout = `$command 2> /tmp/EContext.stderr`;
    $result->{exitcode} = $?;
    $result->{stdout} = $stdout;
    $result->{stderr} = `cat /tmp/EContext.stderr`;
    my $stderr = $result->{stderr};
    chop($stderr);
    $log->debug("Command stderr: $stderr");
    $log->debug("Command exitcode: $result->{exitcode}");
    
    return $result;
}

=cut

=pod

=begin classdoc

Use the cp command to copy the file.

@param src the source file to copy
@param dest the destionation to copy file

@return the command result

=end classdoc

=cut

sub retrieve {
    my ($self, %args) = @_;

    return $self->send(%args);
}


=cut

=pod

=begin classdoc

Unvalidate the local econtext singleton.

=end classdoc

=cut

sub DESTROY {
    $localcontext = undef;
}

1;
