# Administrator.pm - Object class of Administrator server

#    Copyright 2011 Hedera Technology SAS
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

Administrator - Administrator object

=head1 SYNOPSIS

    use Administrator;

    # Creates administrator
    my $adm = Administrator->new();

    # Get object
    $adm->getobject($type : String, %ObjectDefinition);


=head1 DESCRIPTION

Administrator is the main object use to create administrator objects

=head1 METHODS

=cut

package Administrator;

use strict;
use warnings;
use Digest::MD5 "md5_hex";
use Log::Log4perl "get_logger";
use Data::Dumper;
use NetAddr::IP;
use AdministratorDB::Schema;
use EntityRights;
use Kanopya::Exceptions;
use General;
use XML::Simple;
use DateTime;
use NetworkManager;
use RulesManager;
use MonitorManager;
use EntityRights::User;
use EntityRights::System;

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;

my ($schema, $config, $oneinstance);

=head2 Administrator::loadConfig
    Class : Private

    Desc : This method allow to load configuration from xml file
            /opt/kanopya/conf/administrator.conf
            File Administrator with config hash containing

    return: scalar string : a dbi data_source used for database connection

=cut

sub loadConfig {
    $config = XMLin("/opt/kanopya/conf/libkanopya.conf");
    if (! exists $config->{internalnetwork}->{ip} ||
        ! defined $config->{internalnetwork}->{ip} ||
        ! exists $config->{internalnetwork}->{mask} ||
        ! defined $config->{internalnetwork}->{mask})
        {
            $errmsg = "Administrator->new need internalnetwork definition in config file!";
            #$log->error($errmsg);
            throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
        }

    if (! exists $config->{dbconf}->{name} ||
        ! defined exists $config->{dbconf}->{name} ||
        ! exists $config->{dbconf}->{password} ||
        ! defined exists $config->{dbconf}->{password} ||
        ! exists $config->{dbconf}->{type} ||
        ! defined exists $config->{dbconf}->{type} ||
        ! exists $config->{dbconf}->{host} ||
        ! defined exists $config->{dbconf}->{host} ||
        ! exists $config->{dbconf}->{user} ||
        ! defined exists $config->{dbconf}->{user} ||
        ! exists $config->{dbconf}->{port} ||
        ! defined exists $config->{dbconf}->{port})
        {
            $errmsg = "Administrator::loadConfig need db definition in config file!";
            #$log->error($errmsg);
            throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
        }

    #$log->info("Administrator configuration loaded");
    return "dbi:" . $config->{dbconf}->{type} .
            ":" . $config->{dbconf}->{name} .
            ":" . $config->{dbconf}->{host} .
            ":" . $config->{dbconf}->{port};
}

=head2 Administrator::authenticate (%args)

    Class : Public

    Desc :     method used to authenticate user by login/password.
            ! THIS IS THE FIRST METHOD TO CALL BEFORE instanciating an Administrator;

    args :     login : string scalar : user login
            password : string scalar : user password

=cut

sub authenticate {
    my %args = @_;

    General::checkParams(args => \%args, required => ['login', 'password']);

    #$log->debug("login: ".$args{login}." password: ".$args{password});

    my $user_data = $schema->resultset('User')->search(
        {
            user_login => $args{login},
            user_password => md5_hex($args{password}),
        }
    )->single;

    if(not defined $user_data) {
        $errmsg = "Authentication failed for login ".$args{login};
        throw Kanopya::Exception::AuthenticationFailed(error => $errmsg);
    } else {
        $log->info("Authentication succeed for login ".$args{login});
        #$rchecker = EntityRights::build(dbixuser => $user_data, schema => $schema);
        $ENV{EID} = $user_data->id;
    }
}


# Configuration loading and database connection are automaticaly done during
# module loading.

{
    eval {
        my $dbi = loadConfig();
        $schema = AdministratorDB::Schema->connect($dbi, $config->{dbconf}->{user}, $config->{dbconf}->{password}, {});
    };

    if ($@) {
        my $error = $@;
        $log->error($error);
        throw Kanopya::Exception::Internal(error => $error);
    }
}

=head2 Administrator::buildEntityRights (%args)

    desc : instanciate an EntityRights::User/System depending on
            environment variable $ENV{EID}
    args : schema : AdministratorDB::Schema instance
    return : EntityRights::User or EntityRights::System

=cut

sub buildEntityRights {
    my %args =  @_;

    General::checkParams(args => \%args, required => ['schema']);

    my $user = $args{schema}->resultset('User')->find($ENV{EID});

    if($user->get_column('user_system')) {
        #$log->debug("EntityRights build a new EntityRights::System with EID ".$ENV{EID});
        return EntityRights::System->new(entity_id => $ENV{EID}, schema => $args{schema});
    } else {
        #$log->debug("EntityRights build a new EntityRights::User with EID ".$ENV{EID});
        return EntityRights::User->new(entity_id => $ENV{EID}, schema => $args{schema});
    }
}

=head2 Administrator::new (%args)

    Class : Public

    Desc : Instanciate Administrator object ; Administrator::authenticate must have been called

    return: Administrator instance

=cut

sub new {
    my $class = shift;
    my %args = @_;

    if(not exists $ENV{EID} or not defined $ENV{EID}) {
        $errmsg = "No valid session registered ;";
        $errmsg .= " Administrator::authenticate must be call with a valid login/password pair";
        throw Kanopya::Exception::AuthenticationRequired(error => $errmsg);
    }

    my $checker = buildEntityRights(schema => $schema);

    if(defined $oneinstance) {
        $oneinstance->{_rightchecker} = $checker;
        #$log->debug("Administrator instance retrieved with new rightchecker");
        return $oneinstance;
    }

    $log->debug("Administrator instance created");

    my $self = {
        _rightchecker => $checker,
        db => $schema,
        manager => {}
    };

    # Load Manager

    $self->{manager}->{network} = NetworkManager->new(
        schemas => $schema,
        internalnetwork => $config->{internalnetwork},
        dmznetwork => $config->{dmznetwork}
    );

    $self->{manager}->{rules} = RulesManager->new( schemas => $schema );
    $self->{manager}->{monitor} = MonitorManager->new( schemas=>$schema );

    bless $self, $class;
    $oneinstance = $self;
    return $self;
}


#TODO Comment getRow
# This is a very deep core method in Kanopya.
# It is used to get a row from an id in a specific table

sub getRow {
	my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['id', 'table']);

    if ((! exists $args{table} or ! defined $args{table}) ||
        (! exists $args{id} or ! defined $args{id})) {
            $errmsg = "Administrator->getRow need a table and id named argument!";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $dbix;
    eval {
        $dbix = $self->{db}->resultset( $args{table} )->find( $args{id} );
	};
    
    if ($@) {
        $errmsg = "Administrator->getRow error ".$@;
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg);
    }
    
    if(not $dbix) {
		$errmsg = "Administrator->getRow : no row found with id $args{id} in table $args{table}";
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg);
	}
    
    return $dbix;
}	


=head2 _getLastRank

    Class : Private

    Desc : This method return last operation number

=cut

sub _get_lastRank {
    my $self = shift;
    my $row = $self->{db}->resultset('Operation')->search(undef, {column => 'execution_rank', order_by=> ['execution_rank desc']})->first;
    if (! $row) {
        $log->debug("No previous operation in queue");
        return 0;
    }
    else {
        my $last_in_db = $row->get_column('execution_rank');
        $log->debug("Previous operation in queue is $last_in_db");
        return $last_in_db;
    }
}



=head2 Administrator::_getDbix(%args)

    Class : Private

    Desc : Instanciate dbix class mapped to corresponding raw in DB

    args:
        table : String : DB table name
        id: Int : id of required entity in table
    return: db schema (dbix)

=cut



=head2 Administrator::_getDbixFromHash(%args)

    Class : Private

    Desc : Instanciate dbix class mapped to corresponding raw in DB

    args:
        table : String : DB table name
        hash: Hash ref : hash of constraints to find entity
    return: db schema (dbix)

=cut

sub _getDbixFromHash {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['table', 'hash']);

    my $dbix;
    eval {
        my $hash = $args{hash};
        if (keys(%$hash)) {
            $dbix = $self->{db}->resultset( $args{table} )->search( $args{hash} );
        } else {
            $dbix = $self->{db}->resultset( $args{table} )->search( undef );
        }
        if (defined $args{page}) {
            $dbix = $dbix->page($args{page});
        }
    };
    if ($@) {
        $errmsg = "Administrator->_getDbixFromHash error ".$@;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error =>  $errmsg);
    }
    return $dbix;
}

=head2 _getAllDbix

    Class : Private

    Desc : Get all dbix class of table

    args:
        table : String : Table name
    return: resultset (dbix)

=cut

sub _getAllDbix {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['table']);

    my $entitylink = lc($args{table})."_entity";
    return $self->{db}->resultset( $args{table} )->search(undef);
}

=head2 _newDbix

    Class : Private

    Desc : Instanciate dbix class filled with <params>, doesn't add in DB

    args:
        table : String : DB table name
        row: hash ref : representing the new row (key mapped on <table> columns)
    return: db schema (dbix)

=cut

sub _newDbix {
    my $self = shift;
    my %args  = @_;
    #$args{params} = {} if !$args{params};

    General::checkParams(args => \%args, required => ['table', 'row']);

    my $new_obj = $self->{db}->resultset($args{table})->new($args{row});
    return $new_obj;
}

=head2 _getEntityClass

    Class : Private

    Desc : Make good require during an Entity Instanciation

    args:
        type : concrete entity type
    return: Entity class

=cut

sub _getEntityClass{
    my $self = shift;
    my %args = @_;
    my $entity_class;

    General::checkParams(args => \%args, required => ['type']);

    if (defined $args{class_path} && exists $args{class_path}){
        $entity_class = $args{class_path}}
    else {
        $entity_class = General::getClassEntityFromType(%args);}
    my $location = General::getLocFromClass(entityclass => $entity_class);
    eval { require $location; };
    if ($@){
        $errmsg = "Administrator->_getEntityClass type or class_path invalid! (location is $location)";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    return $entity_class;
}

sub registerComponent {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => ["component_name", "component_version", "component_category"]);
    return $self->{db}->resultset('Component')->create(\%args)->get_column("component_id");
}

sub registerTemplate {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => ["component_template_name", "component_template_directory", "component_id"]);
    return $self->{db}->resultset('ComponentTemplate')->create(\%args)->get_column("component_template_id");
}


########################################
## methodes for fast usage in web ui ##
########################################

# add a new message
sub addMessage {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['level', 'from', 'content']);

    $self->{db}->resultset('Message')->create({
        user_id => $self->{_rightschecker}->{_user},
        message_from => $args{from},
        message_creationdate => \"CURRENT_DATE()",
        message_creationtime => \"CURRENT_TIME()",
        message_level => $args{level},
        message_content => $args{content}
    });
    return;
}

sub getMessages {
    my $self  = shift;
    my %args  = @_;
    my $limit = $args{limit} || 10;

    my $r = $self->{db}->resultset('Message')->search(undef, {
        order_by => { -desc => [qw/message_id/], },
        rows => $limit
    });
    my @arr = ();
    while (my $row = $r->next) {
        push @arr, {
            'from' => $row->get_column('message_from'),
            'level' => $row->get_column('message_level'),
            'date' => $row->get_column('message_creationdate'),
            'time' => $row->get_column('message_creationtime'),
            'content' => $row->get_column('message_content'),

        };
    }
    return @arr;
}

sub getOperations {
    my $self = shift;
    my $Operations = $self->{db}->resultset('Operation')->search(undef, {
        order_by => { -asc => [qw/execution_rank/] },
        '+columns' => {'user_login' => 'user.user_login'},
#        '+columns' => [ 'user.user_login' ],
        join => [ 'user' ]
    });

    my $arr = [];
    while (my $op = $Operations->next) {

        my $opparams = [];
        my $execution_time;
        my $Parameters = $self->{db}->resultset('OperationParameter')->search({operation_id=>$op->get_column('operation_id')});

        while (my $param = $Parameters->next) {
            push @$opparams, {
                'PARAMNAME' => $param->get_column('name'),
                'VAL' => $param->get_column('value')
            };
        }
        if( defined $op->get_column('hoped_execution_time') ) {
            my $dt = DateTime->from_epoch(epoch => $op->get_column('hoped_execution_time'), time_zone => 'Europe/Paris');
            $execution_time = $dt->ymd()." ".$dt->hms();

        } else {
            $execution_time = 'no';
        }
        push @$arr, {
            'ID' => $op->get_column('operation_id'),
            'TYPE' => $op->get_column('type'),
            'FROM' => $op->get_column('user_login'),
            'CREATION' => $op->get_column('creation_date')." ".$op->get_column('creation_time'),
            #'PLANNED' => $execution_time,
            'RANK' => $op->get_column('execution_rank'),
            'PRIORITY' => $op->get_column('priority'),
            'PARAMETERS' => $opparams,
        };
    }
    return $arr;

}

sub getOperationSum {
# this method is used to calcul number of operations enqueued
    my $self = shift;
    # get number of roxs in operation table
    my $oposum = $self->{db}->resultset('Operation')->search(
	{},
	{
	   select => [ { count => { distinct => '*' } } ], as => [ 'count' ]
	}
    );
    # force oposum var to NULL if there's no operations enqueued (to avoid unnecesary display)
    if ($oposum eq 0) {
	$oposum = '';
    } 
    return $oposum;
}

sub getComponentsListByCategory {
    my $self = shift;
    my $components = $self->{db}->resultset('Component')->search({},
    { order_by => { -asc => [qw/component_category component_name component_version/]}}
    );
    my $list = [];
    my $currentindex = -1;
    my $currentcategory = '';
    while(my $c = $components->next) {
        my $category = $c->get_column('component_category');
        my $tmp = { name => $c->get_column('component_name'), version => $c->get_column('component_version')};
        if($currentcategory ne $category) {
            $currentcategory = $category;
            $currentindex++;
            $list->[$currentindex] = {category => "$category", components => []};
        }
        push @{$list->[$currentindex]->{components}}, $tmp;
    }
    return $list;
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
