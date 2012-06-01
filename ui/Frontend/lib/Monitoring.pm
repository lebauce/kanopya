package Monitoring;

use Dancer ':syntax'; 
use Dancer::Plugin::Ajax;
use Data::Dumper;

use Administrator;
use NodemetricCombination;
use Log::Log4perl "get_logger";

my $log = get_logger("webui");

prefix '/monitoring';


=head2 ajax '/serviceprovider/:spid/nodesview/bargraph'

    Desc: Get the values corresponding to the selected nodemetric combination for the currently monitored cluster, 
    return to the monitor.js an array containing the nodes names for the combination, and another one containing the values for the nodes, plus the label of the node combination unit

=cut  

get '/serviceprovider/:spid/nodesview/bargraph' => sub {
    my $cluster_id    = params->{spid} || 0;
    my $nodemetric_combination_id = params->{'id'};

    my $compute_result = _computeNodemetricCombination (cluster_id => $cluster_id, combination_id => $nodemetric_combination_id);

    if ($compute_result->{'error'}) {
        return to_json {error => $compute_result->{'error'}};
    }

    my $nodelist = [ @{$compute_result->{'nodes'}}, @{$compute_result->{'undef'}} ];
    
    content_type('application/json');
    return to_json {values => $compute_result->{'values'}, nodelist => $nodelist};
};


=head2 sub _computeNodemetricCombination

    Desc: Compute the nodemetric combination for each node of the cluster and return a reference to a hash containing references to 2 arrays, the first containing the node list, the second containing the corresponding values 
    return: \%rep;

=cut

sub _computeNodemetricCombination {
    my %args = @_;
    my $cluster_id = $args{cluster_id};
    my $nodemetric_combination_id = $args{combination_id};
    my $service_provider = Entity::ServiceProvider->get(id=>$cluster_id);
    my $nodemetric_combination = NodemetricCombination->get('id' => $nodemetric_combination_id);
    my @indicator_ids = $nodemetric_combination->getDependantIndicatorIds();
    my @indicator_oids;
    $log->debug('[Cluster id '.$cluster_id.']: The requested combination: '.$nodemetric_combination_id.' is built on the top of the following indicators: '."@indicator_ids");

    my $nodes_metrics; 
    my $error;
    my %nodeEvals;
    my %rep;
    
    # we retrieve the nodemetric values
    eval {
        foreach my $indicator_id (@indicator_ids) {
            #my $indicator_inst = Indicator->get('id' => $indicator_id);
            #my $indicator_oid = $indicator_inst->getAttr('name'=> 'indicator_oid');
            my $indicator_oid = $service_provider->getIndicatorOidFromId( indicator_id => $indicator_id );
            push @indicator_oids, $indicator_oid;
        }
        $nodes_metrics = $service_provider->getNodesMetrics(
            indicators => \@indicator_oids,
            time_span => 1200,
            shortname => 1
        );

        $log->debug('[Cluster id '.$cluster_id.']: The indicators have the following values :'.Dumper $nodes_metrics);

        while (my ($host_name,$monitored_values_for_one_node) = each %$nodes_metrics) {
            my $nodeEval;
            $nodeEval = $nodemetric_combination->computeValueFromMonitoredValues(
                monitored_values_for_one_node => $monitored_values_for_one_node
            );
            $nodeEvals{$host_name} = $nodeEval;
        }
        $log->debug('[Cluster id '.$cluster_id.']: Requested combination value for each node: '.Dumper \%nodeEvals);
    };
    # error catching
    if ($@) {
        $error="$@";
        $log->error($error);
        $rep{'error'} = $error;
        return \%rep;
    # we catch the fact that there is no value available for the selected nodemetric
    } elsif (scalar(keys %nodeEvals) == 0) {
        $error='Error : No indicator values returned by monitored nodes';
        $log->error($error);
        $rep{'error'} = $error;
        return \%rep;
    } else {
        #we create an array containing the values, to be sorted
        my @nodes_values_to_sort;
        my @nodes_undef;
        while (my ($node, $metric) = each %nodeEvals) {
            if (defined $metric) {
            push @nodes_values_to_sort, { node => $node, value => $metric };
            } else {
                push @nodes_undef, $node;
            }
        }
        if (scalar(@nodes_values_to_sort) == 0) {
            $error = "no value could be retrieved for this metric";
            $log->error($error);
            $rep{'error'} = $error;
            return \%rep;
        }
        #we now sort this array
        my @sorted_nodes_values =  sort { $a->{value} <=> $b->{value} } @nodes_values_to_sort;
        # we split the array into 2 distincts one, that will be returned to the monitor.js
        my @nodes = map { $_->{node} } @sorted_nodes_values;
        my @values = map { $_->{value} } @sorted_nodes_values;  

        $rep{'nodes'} = \@nodes;
        $rep{'values'} = \@values;
        $rep{'undef'} = \@nodes_undef;
        return \%rep;
    }
}

1;
