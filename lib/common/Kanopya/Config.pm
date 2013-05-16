#    Copyright © 2012 Hedera Technology SAS
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

Subroutines to read/write kanopya configuration files.

@since    2012-May-21

=end classdoc

=cut

package Kanopya::Config;

use strict;
use warnings;

use XML::Simple;
use Storable 'dclone';
use Path::Class;

my $config;
my $kanopya_dir;

=pod

=begin classdoc

Initialize array reference $config from kanopya xml configuration files

=end classdoc

=cut

sub _loadconfig {
    my $base_dir = __FILE__;
    my @kanopya  = split 'kanopya', $base_dir;
    $kanopya_dir = $kanopya[0] . '/kanopya';

    $config = {
        executor          => XMLin($kanopya_dir . '/conf/executor.conf', ForceArray => [ "callbacks" ]),
        executor_path     => $kanopya_dir . '/conf/executor.conf',
        monitor           => XMLin($kanopya_dir . '/conf/monitor.conf'),
        monitor_path      => $kanopya_dir . '/conf/monitor.conf',
        libkanopya        => XMLin($kanopya_dir . '/conf/libkanopya.conf'),
        libkanopya_path   => $kanopya_dir . '/conf/libkanopya.conf',
        aggregator        => XMLin($kanopya_dir . '/conf/aggregator.conf'),
        aggregator_path   => $kanopya_dir . '/conf/aggregator.conf',
        rulesengine       => XMLin($kanopya_dir . '/conf/rulesengine.conf'),
        rulesengine_path  => $kanopya_dir . '/conf/rulesengine.conf',
    }
}

=pod

=begin classdoc

retrieve kanopya directory 

@return kanopya directory 

=end classdoc

=cut

sub getKanopyaDir {
    if (not defined $kanopya_dir) {
        _loadconfig();
    }
    return $kanopya_dir;
}

=pod

=begin classdoc

get the whole configuration or a specific subsystem configuration 

@optional $subsystem : a string among 'executor','monitor','libkanopya','orchestrator','aggregator'

@return hash reference containing the configuration

=end classdoc

=cut

sub get {
    my ($subsystem) = @_;

    if(not defined $config) {
        _loadconfig();
    }

    # use a copy of the structure to avoid accidental global modifications 
    my $copy = dclone($config);
    if(defined $subsystem && exists $copy->{$subsystem}) {
        # Reload config from file (allow several processes/workers to have the same data)
        $copy->{$subsystem} = XMLin($config->{$subsystem . '_path'});

        return $copy->{$subsystem};
    } else {
        return $copy;
    }
}

=pod

=begin classdoc

TODO

=end classdoc

=cut

sub set {
    my (%args) = @_;
    
    if(defined $args{config} && exists $config->{$args{subsystem}}) {
        $config->{$args{subsystem}} = $args{config};
        open (my $FILE, ">", $config->{"$args{subsystem}_path"}) 
            or die 'error while loading '.qq[$config->{"$args{subsystem}_path"}: $!]; 
        print $FILE XMLout($config->{$args{subsystem}});
        close ($FILE);
    }
}

1;
