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


=pod
=begin classdoc

ERollback is the object used to manage execution rollback list.
During operation execution, rollback action will be enque. If an error coming, rollback is call

=end classdoc
=cut


package ERollback;

use strict;
use warnings;
use Data::Dumper;
use General;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use Kanopya::Exceptions;


=pod
=begin classdoc

@constructor

Instanciate a rollback object with a first function/arguments

=end classdoc
=cut

sub new {
    my ($class) = @_;

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

sub print {}


=pod
=begin classdoc

Add a function/arguments to the rollback

=end classdoc
=cut

sub add {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         required => ['function', 'parameters']);

    if (not defined $self->{function}) {
        $self->{function} = $args{function};
        $self->{parameters} = $args{parameters};
        $self->{last_inserted} = $self;
    }
    else {
        if ($self->{before}){
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
    $log->debug('One function added to rollback');
}

sub find {
    my ($self, %args) = @_;

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
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['erollback']);

    $self->{before} = $args{erollback};

    $log->debug("Insert next rollback before <" . $self->{before}->{function} . ">");
}

sub insertNextErollAfter{
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         required => ['erollback']);
    $self->{after} = $args{erollback};
}

sub getLastInserted{
    my ($self) = @_;
    return $self->{last_inserted};
}


sub _last {
    my ($self) = @_;
    my $tmp = $self;

    while ($tmp->{'next_item'}) {
        $tmp = $tmp->{'next_item'};
    }
    return $tmp;
}


sub _recursive_del {
    my ($self) = @_;
    if ($self->{next_item}) {
        $self->{next_item}->_recursive_del();
    }
}


sub undo {
    my ($self) = @_;
    my $current = $self->_last;

    while ($current && $current->{function}) {
        my $func = $current->{function};
        my $args = $current->{parameters};

        $log->info("Undo <$func>.");

        eval {
            $func->(@$args);
        };
        if ($@) {
            # Here we do not display the rollback errors, 
            # as some rollbacks could be inserted many times, and do the same job.
            
            # TODO: We need to remove inserted callback when we detect that it is useless.
            #$log->error("Rollback <$func> falled:\n$@");
            $log->error("Rollback <$func> failed.");
        }

        $current = $current->{prev_item};
    }
    $self->_recursive_del;
}



1;
