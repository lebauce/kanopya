# ERollback.pm -  

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
# Created 14 july 2010

=head1 NAME

ERollback

ERollback is the object used to manage execution rollback list.
During operation execution, rollback action will be enque. If an error coming, rollback is call

=cut

package ERollback;

use strict;
use warnings;
use Data::Dumper;
use General;
use Log::Log4perl "get_logger";


my $log = get_logger("executor");
my $errmsg;

use Kanopya::Exceptions;

my $VERSION = "1.00";

=head2 new

 Instanciate a rollback object with a first function/arguments

=cut

sub new {
    my $class = shift;
    my %args = @_;
        
    my $self = {
        function    => undef,
        parameters  => undef,
        next_item   => undef,
        prev_item   => undef,
        last_inserted => undef,
    };
    bless $self, $class;
    return $self;
}

sub print {
    
}

=head2 add

 Add a function/arguments to the rollback

=cut

sub add {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args,
                         required => ['function', 'parameters']);

#    $self->{last_inserted} = undef;
    $log->debug("add rollback func $args{function}");

    if (not defined $self->{function}) {
        $self->{function} = $args{function};
        $self->{parameters} = $args{parameters};
        $self->{last_inserted} = $self;

        $log->debug("First rollback <" . $self->{function} . "> inserted.");
    }
    else {
        if ($self->{before}){
            $log->debug("Before defined <" . $self->{before}->{function}. ">, try to insert <" .
                        $args{function} . "> before it.");

            my $eroll = $self->find(erollback => $self->{before});
            my $previous = $eroll->{prev_item};

            $eroll->{prev_item} = ERollback->new();
            $eroll->{prev_item}->{function}   = $args{function};
            $eroll->{prev_item}->{parameters} = $args{parameters};
            $eroll->{prev_item}->{prev_item}  = $previous;
            $eroll->{prev_item}->{next_item}  = $eroll;

            if ($previous) {
                $previous->{next_item} = $eroll->{prev_item};
            }
#            else {
#                $self->{function}   = $eroll->{prev_item}->{function};
#                $self->{parameters} = $eroll->{prev_item}->{parameters};
#                $self->{prev_item}  = $eroll->{prev_item}->{prev_item};
#                $self->{next_item}  = $eroll->{prev_item}->{next_item};
#            }

            $log->debug("Rollback <" . $eroll->{prev_item}->{function} . "> inserted before <" .
                        $eroll->{function} . ">.");

            $self->{last_inserted} = $eroll->{prev_item};
            $self->{before} = undef;
        }
        elsif ($self->{after}){
            my $eroll = $self->find(erollback => $self->{after});
            my $next  = $eroll->{next_item};

            $eroll->{next_item} = ERollback->new();
            $eroll->{next_item}->{function}   = $args{function};
            $eroll->{next_item}->{parameters} = $args{parameters};
            $eroll->{next_item}->{prev_item}  = $eroll;
            $eroll->{next_item}->{next_item}  = $next;
            if($next) {
                $next->{prev_item} = $eroll->{next_item};
            }
            $self->{last_inserted} = $eroll->{next_item};

            $log->debug("Rollback <".$eroll->{next_item}->{function}. "> inserted after <" .
                        $self->{after}->{function} . ">");

            $self->{after} = undef;
        }
        else {
            my $last = $self->_last();
            $last->{next_item} = ERollback->new();
            $last->{next_item}->{function}   = $args{function};
            $last->{next_item}->{parameters} = $args{parameters};
            $last->{next_item}->{prev_item}  = $last;

            $self->{last_inserted} = $last->{next_item};
        }
    }
}

sub find {
    my $self = shift;
    my %args = @_;
    General::checkParams(args => \%args,
                         required => ['erollback']);
    my $tmp = $self;

    while ($tmp->{'next_item'}) {
        if ($tmp == $args{erollback}){
            return $tmp;
        }
        $tmp = $tmp->{'next_item'};
    }
    return $tmp;
}

sub insertNextErollBefore{
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['erollback']);

    $self->{before} = $args{erollback};

    $log->debug("Insert next rollback before <" . $self->{before}->{function} . ">");
}

sub insertNextErollAfter{
    my $self = shift;
    my %args = @_;
    General::checkParams(args => \%args,
                         required => ['erollback']);
    $self->{after} = $args{erollback};
}

sub getLastInserted{
    my $self = shift;
    $log->debug("Get last inserted in rollback <" . $self->{last_inserted}->{function} . ">");
    return $self->{last_inserted};
}

=head2 _last

=cut

sub _last {
    my $self = shift;
    my $tmp = $self;

    while ($tmp->{'next_item'}) {
        $tmp = $tmp->{'next_item'};
    }
    return $tmp;
}

=head2 recursive_del

=cut

sub recursive_del {
    my $self = shift;
    if ($self->{next_item}) {
        $self->{next_item}->recursive_del();
    }
    $self->DESTROY();
}

=head2 undo

=cut

sub undo {
    my $self = shift;
    my $current = $self->_last;

    while ($current && $current->{function}) {
        my $func = $current->{function};
        my $args = $current->{parameters};

        $log->info("Undo <$func>.");

        eval {
            $func->(@$args);
        };
        if ($@) {
            $log->error("Rollback <$func> failed:\n$@");
        }

        $current = $current->{prev_item};
    }
    $self->recursive_del;
}

=head2 DESTROY

=cut

sub DESTROY {}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
