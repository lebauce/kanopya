# General.pm - This lib contain general function used in microCluster system

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

General - Common Lib

=head1 SYNOPSIS

    use General;
    
    # Get EEntity Location from Entity
    my $execloc = General::getLocEEntityFromEntity($entity : Entity);
    
    # Get EEntity Class name from Entity
    my $execclass = General::getClassEEntityFromEntity($entity : Entity);


=head1 DESCRIPTION

Executor is the main object use to create execution objects

=head1 METHODS

=cut
package General;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use strict;
use warnings;
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

=head2 getTemplateConfiguration

    Desc: return hashref used to configure Template instance

=cut

sub getTemplateConfiguration {
    return {
        INCLUDE_PATH => '/templates/internal/',
        INTERPOLATE  => 1,     # expand "$var" in plain text
        POST_CHOMP   => 0,     # cleanup whitespace
        EVAL_PERL    => 1,     # evaluate Perl code blocks
        RELATIVE     => 1,     # desactive par defaut
    };
}

=head2---------+--------------+
1 row in set (0.00 sec)

    
    Class : Public
    
    Desc : General sub for check existence of required parameters
    
    Args : 
        0: hash ref to check (caller args)
        1: array ref of required params name 
    
    Throw bad param exception if one param is missing
    
=cut

# TODO log on corresponding caller logger
# Usage: General::checkParams( args => \%args, required => ['param1', 'param2'] );
sub checkParams {
    my %args = @_;
    
    my $caller_args = $args{args};
    my $required = $args{required};
    my $caller_sub_name = (caller(1))[3];
        
    for my $param (@$required) {
        if (! exists $caller_args->{$param} or ! defined $caller_args->{$param}) {
            $errmsg = "$caller_sub_name needs a '$param' named argument!";
            
            # Log in general logger
            # TODO log in the logger corresponding to caller package;
            $log->error($errmsg);
            
            throw Kanopya::Exception::Internal::MissingParam(sub_name   => $caller_sub_name,
                                                             param_name => $param );
        }
    }
}

sub checkParam {
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'args', 'name' ]);

    my $caller_args = $args{args};
    my $arg_name = $args{name};
    my $caller_sub_name = (caller(1))[3];

    my $value;
    eval {
        General::checkParams(args => $caller_args, required => [ $arg_name ]);
        $value = $caller_args->{$arg_name};
        delete $caller_args->{$arg_name};
    };
    if ($@) {
        if (exists $args{default} and defined $args{default}) {
            $value = $args{default};
        }
        else {
            throw Kanopya::Exception::Internal::MissingParam(
                      sub_name   => $caller_sub_name,
                      param_name => $args{name}
                  );
        }
    }
    return $value;
}

sub getClassEEntityFromEntity{
    my %args = @_;
    my $data = $args{entity};
#    $log->debug("Try to get Eentity class from object". ref($data));
    
    if(! exists($args{entity})) {
        $errmsg = "Try to get Eentity class from object not entity : ". ref($args{entity});
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);    
    }
         
    my $entityclass = ref($args{entity});
    my $class = $entityclass;
    $class =~s/\:\:/\:\:E/g;
    $class = "E".$class;
#    $log->debug("$class retrieved from ".ref($args{entity}));
    return $class;
}

#TODO Tester si les regexp fonctionne en simulant le use.
sub getLocFromClass{
    my %args = @_;
    
       if (! exists $args{entityclass} or ! defined $args{entityclass}) { 
        $errmsg = "getLocFromClass need a  entityclass named argument!";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $data = $args{entityclass};
    my $location = $args{entityclass};
    $location =~ s/\:\:/\//g;
    return $location . ".pm";
}

sub getClassEntityFromType{
    my %args = @_;
    
    if (! exists $args{type} or ! defined $args{type}) { 
        $errmsg = "getClassEntityFromType need a  type named argument!";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
        
    
    my $requested_type = $args{type};
    my $obj_class = "Entity::$requested_type";
    return $obj_class;
}

=head2 getAsArrayRef
    
    Class : Public
    
    Desc :     Util for hash loaded from an xml file with xml::simple and list management.
            <tag> could be mapped with a hash (if only one defined in xml) or an array of hash (if list of <tag>).
            This sub returns a array ref of <tag> in all cases.
            
            WARNING: don't use attribute ['name','id','key'] (see @DefKeyAttr in XML::Simple) in your xml tag when list context!
    
    Args :
        data : hash ref where one key is <tag> (but value could be hash ref or array ref)
        tag : string :the name of the tag 
    
    Return : Array ref with all hash ref corresponding to tag (in data).
    
=cut

sub getAsArrayRef {
    my %args = @_;
    
    my $data = $args{data};
    my $elems = $data->{ $args{tag} };
    if ( ref $elems eq 'ARRAY' ) {
        return $elems;
    }
    return $elems ? [$elems] : [];
}

=head2 getAsHashRef
    
    Class : Public
    
    Desc :     Util for hash loaded from an xml file with xml::simple and list management.
            Map the value of an element of <tag> with the hash correponding to all elements of <tag> (without the key element)
            for all <tag> in data.
            
            WARNING: don't use attribute ['name','id','key'] (see @DefKeyAttr in XML::Simple) in your xml tag when list context!
    
    Args :
        data : hash ref where one key is <tag> (but value could be hash ref or array ref)
        tag : string : the name of the tag 
        key : string : name of a element of <tag> we want as key in the resulting hash
        
    Return : The resulting hash ref.
    
=cut

sub getAsHashRef {
    my %args = @_;
    
    my $key = $args{key};
    my $array = getAsArrayRef( data => $args{data}, tag => $args{tag} );
    my %res = ();
    for my $elem (@$array) {
        my %e = %$elem;
        my $val = delete $e{$key}; 
        $res{ $val } = \%e; 
    }
    return \%res;
}

sub convertSizeFormat {
    my %args = @_;
    if(! exists $args{size} or ! defined $args{size}) {
        $errmsg = "convertSizeFormat needs size named argument";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
    }
    if($args{size} !~ /^(\d+)([BKMGTPE])$/) {
        $errmsg = "convertSizeFormat bad size argument $args{size} ; must be XY where X is a positive number and Y a character among B, K, M, G, T, P or E";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
     
    }
    return ($1, $2);   
}

sub convertToBytes {
    my %args = @_;
    if((! exists $args{value} or ! defined $args{value}) ||
       (! exists $args{units} or ! defined $args{units})) {
        $errmsg = "convertToBytes needs value and units named arguments!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    if($args{units} !~ /^[BKMGTPE]$/) {
        $errmsg = "convertToBytes bad units argument : \'$args{units}\'; value must be B, K, M, G, T, P or E !";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
    } 
    my %convert = ('B' => 0, 'K' => 1, 'M' => 2, 'G' => 3, 'T' => 4, 'P' => 5, 'E' => 6);  
    
    return $args{value} * (1024**$convert{$args{units}});
}

sub convertFromBytes {
    my %args = @_;
    if((! exists $args{value} or ! defined $args{value}) ||
       (! exists $args{units} or ! defined $args{units})) {
        $errmsg = "convertFromBytes needs value and units named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    if($args{units} !~ /^[BKMGTPE]$/) {
        $errmsg = "convertFromBytes bad units argument : \'$args{units}\'; value must be B, K, M, G, T, P or E !";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
    } 
    my %convert = ('B' => 0, 'K' => 1, 'M' => 2, 'G' => 3, 'T' => 4, 'P' => 5, 'E' => 6);  
    
    if(! $args{value}) { return 0; }
    
    return $args{value} / (1024**$convert{$args{units}}); 
}

=head2

    Desc : bytesToHuman is a method for converting bytes values to human readable
           value, rounded and with the right unit.
           Example of return : 13.95 M (for value = 14630307)
    
    Args : bytesToHuman expect two argumens 'value' and 'precision'
            value :     value of size in bytes
            precision : precision of rounding (the number of bit displayed included 
                        the separator character '.'. For example, a precision of 5 chars will
                        display 13.95 M, a precision of 7 chars will display 13.9502 M, etc)
    
    Return : scalar containing rounded value with correct unit (Example of return : '13.95 M')
    
=cut

sub bytesToHuman {
    my %args = @_;
    # Check if argument is provided ;
    if((! exists $args{value} or ! defined $args{value}) ||
       (! exists $args{precision} or ! defined $args{precision})) {
        $errmsg = "bytesToHuman needs value named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    if(! $args{value}) { return 0; }
    
    my $value = $args{value};
    my $precision = $args{precision}; # This include the separator '.' char
    my $return_value; 
    # Get the length of value (number of characters in integer) :
    my $value_length = length($value);

    # If value is minor than 3 length, the value is in Bytes :
    if ( $value_length <= 3) {
        $return_value = $value . " B";
    }
    # If the value length is include between 3 and 6 characters, the value is in KiloBytes :
    elsif ( $value_length > 3 and $value_length < 6 ) {
        # Divide by 1024 to get the new value in KB :
        my $a = $value/1024;
        # Round the new value with a precisoin parameter :
        my $b = substr($a, 0, $precision);
        # Return scalar :
        $return_value = $b . " K";
    }
    # Etc ...
    elsif ($value_length > 6 and $value_length <= 9 ) {
        my $a = $value/1024/1024;
        my $b = substr($a, 0, $precision);
        $return_value = $b . " M";
    }   
    elsif ($value_length > 9 and $value_length <= 12 ) {
        my $a = $value/1024/1024/1024;
        my $b = substr($a, 0, $precision);
        $return_value = $b . " G";
    }
    elsif ($value_length > 12 and $value_length <= 15 ) {
        my $a = $value/1024/1024/1024/1024;
        my $b = substr($a, 0, $precision);
        $return_value = $b . " T";
    }
    elsif ($value_length > 15 and $value_length <= 18 ) {
        my $a = $value/1024/1024/1024/1024/1024;
        my $b = substr($a, 0, $precision);
        $return_value = $b . " P";
    }
    elsif ($value_length > 18 and $value_length <= 21 ) {
        my $a = $value/1024/1024/1024/1024/1024/1024;
        my $b = substr($a, 0, $precision);
        $return_value = $b . " E";
    }
    elsif ($value_length > 21 and $value_length <= 24 ) {
        my $a = $value/1024/1024/1024/1024/1024/1024/1024;
        my $b = substr($a, 0, $precision);
        $return_value = $b . " Z";
    }

    return $return_value;

}

=head2
    TODO : humanToBytes (Convert from K,M,G,T ... to bytes size)
=cut

1;
