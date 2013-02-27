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

Base class to manage inheritance throw relational database.

@since    2010-Nov-23

=end classdoc

=cut

package General;

use strict;
use warnings;

use Kanopya::Exceptions;
use Kanopya::Config;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

=pod

=begin classdoc

General sub to validate required/optional arguments passed to methodes
 
@param args hash reference containing arguments to validate

@param required array reference of strings (for required arguments)

@optional optional hash reference of strings (param name) associated to default value (for optional arguments)

=end classdoc

=cut

sub checkParams {
    my %args = @_;
    
    my $caller_args = $args{args};
    my $required = $args{required};
    my $caller_sub_name = (caller(1))[3];
        
    for my $param (@$required) {
        if (! exists $caller_args->{$param} or ! defined $caller_args->{$param}) {
            $errmsg = "$caller_sub_name needs a '$param' named argument!";

            throw Kanopya::Exception::Internal::MissingParam(sub_name   => $caller_sub_name,
                                                             param_name => $param );
        }
    }

    if (defined $args{optional}) {
        while (my ($key, $value) = each %{$args{optional}}) {
            if (not exists $caller_args->{$key}) {
                $caller_args->{$key} = $value;
            }
        }
    }
}

=pod

=begin classdoc

generate SHA512-hashed password using salt value stored in 
libkanopya.conf file 
 
@param password clear password (string) 
 
@return SHA512-hashed password (string)

=end classdoc

=cut

sub cryptPassword {
    my %args = @_;
    checkParams(args => \%args, required => ['password']);
    my $salt = Kanopya::Config::get('libkanopya')->{crypt}->{salt};
    my $cryptpasswd = crypt($args{password}, '$6$'.$salt.'$');
    return $cryptpasswd;
}

=pod

=begin classdoc

retrieve full path to entity class package
 
@param entityclass entity class package name string  
 
@return full path to the package file string

=end classdoc

=cut

sub getLocFromClass {
    my %args = @_;

    checkParams(args => \%args, required => [ 'entityclass' ]);

    my $location = $args{entityclass};
    $location =~ s/\:\:/\//g;
    return $location . ".pm";
}

=pod 

=begin classdoc

@param 
    
Util for hash loaded from an xml file with xml::simple and list management.
<tag> could be mapped with a hash (if only one defined in xml) or an array of hash (if list of <tag>).
This sub returns a array ref of <tag> in all cases.
WARNING: don't use attribute ['name','id','key'] (see @DefKeyAttr in XML::Simple) in your xml tag when list context!
    
@param data hash ref where one key is <tag> (but value could be hash ref or array ref)

@param tag string :the name of the tag 
    
@return array ref with all hash ref corresponding to tag (in data).
    
=end classdoc

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

=pod

=begin classdoc

Util for hash loaded from an xml file with xml::simple and list management.
Map the value of an element of <tag> with the hash correponding to all elements of <tag> (without the key element)
for all <tag> in data.
WARNING: don't use attribute ['name','id','key'] (see @DefKeyAttr in XML::Simple) in your xml tag when list context!
    
@param data hash ref where one key is <tag> (but value could be hash ref or array ref)

@param tag : string : the name of the tag 
        
@param key : string : name of a element of <tag> we want as key in the resulting hash
        
@return : The resulting hash ref.
    
=end classdoc

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

=pod

=begin classdoc

split a size string into 2 elements, value and units
 
@param size : string : XY where X is a positive number and Y a character among B, K, M, G, T, P or E
 
@return array : first element is the value, second element is the unit

=end classdoc

=cut

sub convertSizeFormat {
    my %args = @_;
    checkParams(args => \%args, required => ['size']);
    
    if($args{size} !~ /^(\d+)([BKMGTPE])$/) {
        $errmsg = "convertSizeFormat bad size argument $args{size} ; must be XY where X is a positive number and Y a character among B, K, M, G, T, P or E";
        $log->warn($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
    }
    return ($1, $2);   
}

=pod

=begin classdoc

convert in bytes a value expressed in units  
 
@param value the size to convert in bytes

@param units the value size unit
 
@return the converted value in units

=end classdoc

=cut

sub convertToBytes {
    my %args = @_;
    checkParams(args => \%args, required => ['value','units']);

    if($args{units} !~ /^[BKMGTPE]$/) {
        $errmsg = "convertToBytes bad units argument : \'$args{units}\'; value must be B, K, M, G, T, P or E !";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
    } 
    my %convert = ('B' => 0, 'K' => 1, 'M' => 2, 'G' => 3, 'T' => 4, 'P' => 5, 'E' => 6);  
    
    return $args{value} * (1024**$convert{$args{units}});
}

=pod

=begin classdoc

convert a value expressed in bytes to the desired unit
 
@param value the bytes size to convert

@param units the size unit to convert to
 
@return the converted value in units

=end classdoc

=cut

sub convertFromBytes {
    my %args = @_;
    checkParams(args => \%args, required => ['value','units']);
    
    if($args{units} !~ /^[BKMGTPE]$/) {
        $errmsg = "convertFromBytes bad units argument : \'$args{units}\'; value must be B, K, M, G, T, P or E !";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
    } 
    my %convert = ('B' => 0, 'K' => 1, 'M' => 2, 'G' => 3, 'T' => 4, 'P' => 5, 'E' => 6);  
    
    if(! $args{value}) { 
        return 0; 
    }
    
    return $args{value} / (1024**$convert{$args{units}}); 
}

=pod

=begin classdoc

bytesToHuman is a method for converting bytes values to human readable
value, rounded and with the right unit.
Example of return : 13.95 M (for value = 14630307)
 
@param value : value of size in bytes

@param precision : precision of rounding (the number of bit displayed included 
                   the separator character '.'. For example, a precision of 5 chars will
                   display 13.95 M, a precision of 7 chars will display 13.9502 M, etc)
 
@return scalar containing rounded value with correct unit (Example of return : '13.95 M')

=end classdoc

=cut

sub bytesToHuman {
    my %args = @_;
    checkParams(args => \%args, required => ['value','precision']);

    if(! $args{value}) { 
        return 0; 
    }
    
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

=pod

=begin classdoc

return hash reference to pass to Template instanciation
 
@return hash reference to pass to Template->new 

=end classdoc

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


=pod

=begin classdoc

Compare two scalar values in function of a SQL operator.

@return the comparison boolean result

=end classdoc

=cut

sub compareScalars {
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'left_op', 'right_op', 'op' ]);

    if ($args{op} =~ m/.*LIKE$/) {
        if (not $args{right_op} =~ m/^%.*%$/) {
            if ($args{right_op} =~ m/.*%$/) {
                $args{right_op} = '^' . $args{right_op};
            }
            if ($args{right_op} =~ m/^%.*/) {
                $args{right_op} = $args{right_op} . '$';
            }
        }
        (my $pattern = $args{right_op}) =~ s/%/.*/g;

        my $comp = ($args{left_op} =~ m/$pattern/);
        return ($args{op} =~ m/^NOT.*/) ? not $comp : $comp;
    }
    # Check if one of the operands is a string
    elsif (($args{left_op} ^ $args{left_op}) or (($args{right_op} ^ $args{right_op}))) {
        if ($args{op} eq "=") {
            return "$args{left_op}" eq "$args{right_op}";
        }
        elsif ($args{op} eq "<>") {
            return "$args{left_op}" ne "$args{right_op}";
        }
        elsif ($args{op} eq "<") {
            return "$args{left_op}" lt "$args{right_op}";
        }
        elsif ($args{op} eq ">") {
            return "$args{left_op}" gt "$args{right_op}";
        }
        elsif ($args{op} eq "<=") {
            return "$args{left_op}" le "$args{right_op}";
        }
        elsif ($args{op} eq ">=") {
            return "$args{left_op}" ge "$args{right_op}";
        }
    }
    else {
        if ($args{op} eq "=") {
            return $args{left_op} == $args{right_op};
        }
        elsif ($args{op} eq "<>") {
            return $args{left_op} != $args{right_op};
        }
        elsif ($args{op} eq "<") {
            return $args{left_op} < $args{right_op};
        }
        elsif ($args{op} eq ">") {
            return $args{left_op} > $args{right_op};
        }
        elsif ($args{op} eq "<=") {
            return $args{left_op} <= $args{right_op};
        }
        elsif ($args{op} eq ">=") {
            return $args{left_op} >= $args{right_op};
        }
    }

    throw Kanopya::Exception::Internal::UnknownOperator(
              error => "Unsupported operator $args{op}."
          );
}

1;
