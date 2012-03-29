#    Copyright © 2012 Hedera Technology SAS
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
package ActionTriggered;
use strict;
use warnings;
use General;
use Entity::Connector::ActiveDirectory;
use Entity::Connector;
use base 'BaseDB';
use Data::Dumper;
# logger
#use Log::Log4perl "get_logger";
#my $log = get_logger("monitor");

use constant ATTR_DEF => {
    action_triggered_hostname      =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    action_triggered_action_id     =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    action_triggered_timestamp     =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
};

sub getAttrDef { return ATTR_DEF; }

sub new {
    my ($class, %args) = @_;
    $args{action_triggered_timestamp} = time();
    my $self = $class->SUPER::new(%args);
    
    $self -> trigger();
    return $self;
};

sub trigger{
    my ($self,%args) = @_;
    my $params = $self->getParams();
    my $cluster_id = $self->{_dbix}->action_triggered_action->get_column('action_service_provider_id');
    #print '**'.$cluster_id."\n";
    my $connector =  Entity::Connector->find(hash => { #TODO : multiple
        service_provider_id => $cluster_id,
        connector_type_id   => '1', #TODO : UN HARDCODE
    });
    
    #print '++'.$connector->getAttr(name => 'connector_id')."\n";
    
    my $active_directory =  Entity::Connector::ActiveDirectory->get(
        id => $connector->getAttr(name => 'connector_id'),
    );
    my $ou_from = $active_directory->getAttr('name' => 'ad_nodes_base_dn');
    #sprint $ou_from;
    $self->createXMLFile(
            hostname => $self->getAttr(name => 'action_triggered_hostname'),
            ou_from  => $ou_from,
            ou_to    => $params->{ou_to},
            filePath => $params->{filePath},
            id       => $self->getAttr(name => 'action_triggered_id'),
    );
}
sub getParams {
    my ($self, %args) = @_;
    my $params_rs = $self->{_dbix}
    ->action_triggered_action
    ->action_parameters
    ->search({});
    
    my %params;
    while ( my $param = $params_rs->next ) {
        $params{ $param->action_parameter_name } = $param->action_parameter_value;
    }
    
    return \%params;
    #print Dumper \%params;
};

sub createXMLFile {
    my ($self, %args) = @_;
    
    General::checkParams(args => \%args, required => ['hostname','ou_from','ou_to','filePath']);

    my $fileDirPath = $args{filePath};
    #print Dumper $params;
    my $fileCompletePath = $fileDirPath.'/file.xml';
    #print $fileCompletePath;
    open FILE, ">", $fileCompletePath or die $!;
    print FILE $args{hostname}."\n";
    print FILE $args{ou_from}."\n";
    print FILE $args{ou_to}."\n";
    print FILE $args{id}."\n";
    close FILE;
   
};
1;