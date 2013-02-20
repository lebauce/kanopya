# Local.pm - EContext::Local for local execution using system buitin function

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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=head1 NAME

EContext::Local  

=head1 SYNOPSIS



=head1 DESCRIPTION

EContext::Local offers execute method via system builtin function

=head1 METHODS

=cut
package EContext::Local;
use base "EContext";

use strict;
use warnings;
use Kanopya::Exceptions;
use General;

use Log::Log4perl "get_logger";
my $log = get_logger("command");
my $errmsg;

our $VERSION = "1.00";

=head2 $localcontext

$localcontext use to make this class a singleton

=cut

my $localcontext;

=head2 new


    
=cut

sub new {
    my ($class, %args) = @_;

    # do not reinstanciate local context, reuse 
    if(defined $localcontext) {
        return $localcontext;
    }

    my $self = $class->SUPER::new(%args);
    bless $self, $class;
    $localcontext = $self;

    return $self;
}

=head2 execute

execute ( command )
    desc: execute a command in shell
    args:
        command : string: command to execute
    return:
        result ref hash containing resulting stdout and stderr  
    
    WARNING: in your command, don't use stderr redirection ( 2> )
    
=cut

sub execute {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['command']);
    
    # command must no contain stderr redirection !
    if($args{command} =~ m/2>/) {
        $errmsg = "EContext::Local->execute : command must not contain stderr redirection (2>)!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
    }
        
    my $result = {};
    my $command = $args{command};
    $log->info("Running command: $command");
    $ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin'; 
    my $stdout = `$command 2> /tmp/EContext.stderr`;
    $result->{exitcode} = $?;
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

=head2 send

send(src => $srcfullpath, dest => $destfullpath)
    desc: send a file to a specific directory
    args:
        src : string: complete path to the file to send
        dest : string: complete path to the destination directory/file
    return:
        result ref hash containing resulting stdout and stderr  
    
=cut

sub send {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['src','dest']);
    
    if(not -e $args{src}) {
        $errmsg = "EContext::Local->execute src file $args{src} no found";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    # TODO faire plus de test sur la destination
    my $result = {};
    my $command = "cp -R $args{src} $args{dest}";
    $log->info("Running command: $command");
    $ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin'; 
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

=head2 DESTROY

    destructor : remove stored instance    
    
=cut

sub DESTROY {
    $localcontext = undef;
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
