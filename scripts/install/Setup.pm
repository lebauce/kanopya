# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=pod

=begin classdoc

Base class implementing operating system independant actions

@since    2012-Jun-10
@instance hash
@self     $self

=end classdoc

=cut

package Setup;
use Cwd;
use Term::ReadKey;
use Data::Dumper;

=pod

=begin classdoc

@constructor

Base initialization of Setup instance.

@optional f yaml file containing predefined answers

@optional d 1 use default answer for each question

@return a Setup instance

=end classdoc

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;

    ($self->{installpath} = getcwd()) =~ s/kanopya.*/kanopya/;
    $self->{parameters_values} = {};

    if(defined $args{f}) {
        $self->{mode} = 'file';
        $self->{parameters_values} = $self->_load_file($args{f});
    } elsif(defined $args{d}) {
        $self->{mode} = 'default';
    } else {
        $self->{mode} = 'ask';
    }

    $self->_init();

    return $self;
}

=pod

=begin classdoc

Display kanopya licence and ask to accept by typing yes.
If mode is not 'ask', automatically answer y

=end classdoc

=cut

sub accept_licence {
    my ($self) = @_;
    open (my $LICENCE, "<", $self->{licence_path})
        or die "error while opening ".$self->{licence_path}." : $!";
    print join("", <$LICENCE>);
    close($LICENCE);
    print "Do you accept the licence ? (y/n)\n";
    if($self->{mode} ne 'ask') {
        print "y\n";
        return 1;
    } else {
        chomp($validate_licence= <STDIN>);
        if($validate_licence ne 'y') {
            return 0;
        }
        return 1;
    }
}

=pod

=begin classdoc

Retrieve/generate additionnal data parameters

=end classdoc

=cut

sub complete_parameters {

}

=pod

=begin classdoc

Depending of the process mode, ask the user for parameters.
If mode is default (-d command line parameter), do not ask user but 
  automatically use default answers
If mode is file (-f command line parameter), do not ask user but 
  automatically use the provided file to take answers

=end classdoc

=cut

sub ask_parameters {
    my ($self) = @_;

    PARAMS:
    for my $param (@{$self->{parameters}}) {
        my $value;

        # display title step
        if (exists $param->{title}) {
            print "\n = $param->{title} = \n\n";
            next PARAMS;
        }

        # display caption
        print "- $param->{caption} ";

        # display default value if exists
        if (exists $param->{default}) {
            my $default = $param->{default};
            if (ref($default) eq 'CODE') {
                $param->{default} = $param->{default}();
            }

            print "($param->{default})";
        }
        print " :\n";

        # display choices answer if exists
        if (exists $param->{choices}) {
            print " [" . join('|', $param->{choices}()) . "]\n";
        }

        # ask mode
        if ($self->{mode} eq 'ask') {
            $value = $self->_ask($param);
            if(not defined $value) {
                redo PARAMS;
            }
        }
        # default mode
        elsif ($self->{mode} eq 'default') {
            if (not exists $param->{default}) {
                $value = $self->_ask($param);
                if (not defined $value) {
                    redo PARAMS;
                }
            } else {
                 $value = $param->{default};
                 print "> $value\n";
            }
        }

        # file mode
        elsif ($self->{mode} eq 'file') {
            if (exists $self->{parameters_values}->{$param->{keyname}}) {
                $value = $self->{parameters_values}->{$param->{keyname}};
                print "> $value\n";
            } else {
                $value = $self->_ask($param);
                if(not defined $value) {
                    redo PARAMS;
                }
            }
        }

        $self->{parameters_values}->{$param->{keyname}} = $value;

        #confirm parameter (equality test, most often for password checks)
        if (exists $param->{confirm}) {
            my $method = $param->{confirm};
            my $v = $self->$method($param);
            if (exists $v->{error}) {
                print "ERROR: $v->{msg}\n";
                if (exists $self->{parameters_values}->{$param->{keyname}}) {
                    delete $self->{parameters_values}->{$param->{keyname}};
                }
                redo PARAMS;
            }
        }

        # validate parameter
        if(exists $param->{validate}) {
            my $method = $param->{validate};
            my $v = $self->$method($value);
            if(exists $v->{error}) {
                print "ERROR: $v->{msg}\n";
                if(exists $self->{parameters_values}->{$param->{keyname}}) {
                    delete $self->{parameters_values}->{$param->{keyname}};
                }
                redo PARAMS;
            }
        }
        print "\n";
    }
}

sub _ask {
    my ($self, $param) = @_;
    my $value;
    print "> ";
    if(exists $param->{hideinput}) {
        ReadMode('noecho');
        chomp($value = <STDIN>);
        ReadMode('original');
        print "\n";
    }
    else {
        chomp($value = <STDIN>);
    }


    # use default value if empty string
    if(length($value) == 0) {
        if(exists $param->{default}) {
            $value = $param->{default};
            print "> $value\n";
        } else {
            print "ERROR: answer required (not default value)\n";
            return;
        }
    }
    return $value;
}

sub _validate_domainname {
    my ($self, $value) = @_;
    if($value !~ /^[a-z0-9-]+(\.[a-z0-9-]+)+$/) {
        return { error => 1, msg => "Invalid domain name $value" };
    }
    return { value => $value };
}

sub _validate_ip {
    my ($self, $value) = @_;
    if($value !~ /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/) {
        return { error => 1, msg => "Invalid ip address $value" };
    }
    return { value => $value };
}

sub _validate_port {
    my ($self, $value) = @_;
    if($value < 1 || $value > 65535) {
        return { error => 1, msg => "Invalid port number $value" };
    }
    return { value => $value };
}

sub _validate_mysql_connection {
    my ($self, $value) = @_;
    my $host = $self->{parameters_values}->{mysql_host};
    my $port = $self->{parameters_values}->{mysql_port};
    my $passwd = $value;
    my $output = `mysql -h $host -P $port -u root -p$passwd -e 'quit'`;
    if($? != 0) {
        return { error => 1, msg => "$output" };
    }
    return { value => $value };
}

sub _confirm_password {
    my ($self, $param) = @_;

    print 'Please confirm the parameter value:' . "\n";
    my $confirm = $self->_ask($param);

    if ($confirm eq $self->{parameters_values}->{$param->{keyname}}) {
        return $confirm;
    }
    else {
        return { error => 1, msg => 'Passwords does not match' };
    }
}

1;
