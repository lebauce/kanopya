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
use Sys::Hostname::FQDN qw(fqdn);
use base 'BaseDB';
use Data::Dumper;
# logger
#use Log::Log4perl "get_logger";
#my $log = get_logger("monitor");

use constant ATTR_DEF => {
    action_triggered_hostname      =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
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
    
#    $self -> trigger();
    return $self;
};

sub trigger{
    my ($self,%args) = @_;
    
    # Get db params (path and ou_dest)
    my $params = $self->getParams();    # Get current ou
    my $body;
    my $cluster_id = $self->{_dbix}
                          ->action_triggered_action
                          ->get_column('action_service_provider_id');
                          
    if($params->{trigger_rule_type} eq 'noderule'){
        my $outside    = Entity::ServiceProvider::Outside
                              ->get('id' => $cluster_id);
        my $directoryServiceConnector = $outside->getConnector(
                                                      'category' => 'DirectoryService'
                                                  );
        my $ou_from    = $directoryServiceConnector->getAttr(
                                                         'name' => 'ad_nodes_base_dn'
                                                 );
                                                 
        #remove the domain name from the hostname
        my $complete_host_name = $self->getAttr(name => 'action_triggered_hostname');
        my @hostname = split '\.', $complete_host_name;
        
        my $action_id =  $self->getAttr(name => 'action_triggered_id');
        my $kanopya_fqdn = fqdn(); 
        my $route_callback = 'http://'.$kanopya_fqdn.':5000/architectures/extclusters/'.$cluster_id.'/actions/'.$action_id.'/close';
        
        
        $body = {
            ou_from        => $ou_from,
            ou_to          => $params->{ou_to},
            user_message   => $params->{user_message},
            logout_time    => $params->{logout_time},
            hostname       => $hostname[0],
            route_callback => $route_callback,
        }
    }elsif($params->{trigger_rule_type} eq 'clusterrule'){
        my $cluster = Entity::ServiceProvider::Outside::Externalcluster->get('id' => $cluster_id);
         
        $body = { 
            id          => $self->getAttr(name => 'action_triggered_id'),
            clustername => $cluster->getAttr('name' =>'externalcluster_name'),
            user_message => $params->{user_message},
        }
    }
    
    $self->createXMLFile(
            file_path => $params->{file_path},
            body      => $body,

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
    
    General::checkParams(args => \%args, required => ['file_path','body']);
    
    my @params_order = ('route_callback','hostname','clustername','ou_from','ou_to', 'id', 'user_message','logout_time');
    
    my $fileDirPath = $args{file_path};

    #print Dumper $params;
    my $fileCompletePath = $fileDirPath.time().'file.xml';
    #print $fileCompletePath;
    open FILE, ">", $fileCompletePath or die $!;
    foreach my $param (@params_order){
       if(defined $args{body}->{$param}){print FILE $args{body}->{$param}."\n"};
    }

    close FILE;
    return $fileCompletePath;
};
1;