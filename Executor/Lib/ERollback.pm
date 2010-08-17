# ERollback.pm -  

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

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
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);

my $log = get_logger("executor");

use lib "../../Common/Lib";
use McsExceptions;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

 Instanciate a rollback object with a first function/arguments

=cut

sub new {
	my $class = shift;
	my %args = @_;
		
	my $self = {
		function => undef,
        parameters => undef,
        next_item => undef,
        prev_item => undef,
    };
    bless $self, $class;
    return $self;
}

=head2 add

 Add a function/arguments to the rollback

=cut

sub add {
	my $self = shift;
    my %args = @_;
    if((! exists $args{function} or ! defined $args{function}) or
	   (! exists $args{parameters} or ! defined $args{parameters})) {
		throw Mcs::Exception::Internal(error => "ERollback->add need function and parameters named arguments");   	
	}
    
    if(not defined $self->{function}) {
    	$self->{function} = $args{function};
    	$self->{parameters} = $args{parameters};
    } else {
    	my $last = $self->_last;
        $last->{next_item} = ERollback->new();
        $last->{next_item}->{function} = $args{function};
        $last->{next_item}->{parameters} = $args{parameters};
    	$last->{next_item}->{prev_item} = $last;
    }
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
    if ($self->{'next_item'}) {
        $self->{'next_item'}->recursive_del();
    }
    $self->DESTROY();
}

=head2 undo

=cut

sub undo {
	my $self = shift;
    my $tmp = $self->_last;

    while ($tmp) {
        my $fn = $tmp->{function};
        my $args = $tmp->{parameters};
        $log->debug("undo with parameters: ", Dumper  $args);
	$fn->(@$args);
        $tmp = $tmp->{prev_item};
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