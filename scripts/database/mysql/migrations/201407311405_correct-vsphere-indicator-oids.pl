use strict;
use warnings;
use Kanopya::Database;

# Repair tables: use VM indicators for vSphere VM hosts and HV indicators for vSphere HV hosts. 

my $dbh = Kanopya::Database::dbh;
my ($sth, $rv, $res);

my $hv_hosts = $dbh->selectcol_arrayref(
    "SELECT vsphere5_hypervisor_id FROM vsphere5_hypervisor"
);

### FIRST PART - NODEMETRICS

my $vm_oid = 'vsphere_vm.summary.quickStats.overallCpuUsage';
my $hv_oid = 'vsphere_hv.summary.quickStats.overallCpuUsage';

my $nodemetrics = $dbh->selectall_arrayref(
    "SELECT nm.nodemetric_id, ind.indicator_oid, n.node_id, n.host_id, nm.nodemetric_indicator_id "
    . " FROM nodemetric nm"
    . " INNER JOIN node n ON nm.nodemetric_node_id = n.node_id"
    . " INNER JOIN collector_indicator ci ON ci.collector_indicator_id = nm.nodemetric_indicator_id"
    . " INNER JOIN indicator ind ON ind.indicator_id = ci.indicator_id"
    . " AND ind.indicator_oid IN ('$vm_oid', '$hv_oid')"
);
my @problematic_nodemetrics;
foreach my $res (@$nodemetrics) {
    my $nm_id      = $res->[0];
    my $nm_ind_oid = $res->[1];
    my $nm_host_id = $res->[3];
    
    my $ind_type = 'vm';
    if ($nm_ind_oid =~ /^vsphere_hv/) {
        $ind_type = 'hv';
    }
    
    my $node_type = 'vm';
    foreach my $hv_host_id (@$hv_hosts) {
        if ($hv_host_id == $nm_host_id) {
            $node_type = 'hv';
            last;
        }
    }
    
    if ($ind_type ne $node_type) {
        push @problematic_nodemetrics, $res;
        print "Problematic nodemetric found: $nm_id\n";
    }
}

foreach my $problematic_nodemetric (@problematic_nodemetrics) {
    # Does a corrected version already exist ?
    my $pb_nm_id   = $problematic_nodemetric->[0];
    my $pb_ind_oid = $problematic_nodemetric->[1];
    my $pb_node_id = $problematic_nodemetric->[2];
    my $pb_ci_id   = $problematic_nodemetric->[4];
    my $other_oid;
    if ($pb_ind_oid eq $vm_oid) {
        $other_oid = $hv_oid;
    } else {
        $other_oid = $vm_oid;
    }
    
    my $found = 0;
    foreach my $nodemetric (@$nodemetrics) {
        my $nm_ind_oid = $nodemetric->[1];
        my $nm_node_id = $nodemetric->[2];
        if ($nm_ind_oid eq $other_oid and $nm_node_id == $pb_node_id) {
            $found = 1;
            last;
        }
    }
    
    my $nr_rows_affected;
    if ($found) {
        $nr_rows_affected = $dbh->do("DELETE FROM nodemetrics WHERE nodemetrics_id = $pb_nm_id");
        print "$nr_rows_affected deleted\n";        
    } else {
        $nr_rows_affected = $dbh->do(
            "UPDATE nodemetric SET nodemetric_indicator_id = ("
                . " SELECT ci.collector_indicator_id FROM collector_indicator ci"
                . " INNER JOIN indicator i ON i.indicator_id = ci.indicator_id"
                . " WHERE i.indicator_oid = '$other_oid' AND ci.collector_manager_id = ("
                    . " SELECT collector_manager_id FROM collector_indicator "
                    . " WHERE collector_indicator_id = $pb_ci_id))"
            . " WHERE nodemetric_id = $pb_nm_id"
        );
        print "$nr_rows_affected updated\n";
    }
}


### SECOND PART - COLLECT

my $collect_data = $dbh->selectall_arrayref(
    "SELECT indset.indicatorset_id, indset.indicatorset_name, n.host_id, cl.service_provider_id"
    . " FROM indicatorset indset, node n, collect cl"
    . " WHERE cl.indicatorset_id = indset.indicatorset_id"
    . " AND indset.indicatorset_name IN ('vsphere_vm', 'vsphere_host')"
    . " AND n.node_id = (SELECT node_id FROM node WHERE node.service_provider_id = cl.service_provider_id LIMIT 1)"
);

my @problematic_collectdata;
foreach my $res (@$collect_data) {
    my $indset_name = $res->[1];
    my $host_id     = $res->[2];
        
    my $ind_type = ($indset_name eq 'vsphere_host' ? 'hv' : 'vm');
    
    my $node_type = 'vm';
    foreach my $hv_host_id (@$hv_hosts) {
        if ($hv_host_id == $host_id) {
            $node_type = 'hv';
            last;
        }
    }
    
    if ($ind_type ne $node_type) {
        push @problematic_collectdata, $res;
        print "Problematic nodemetric found: $indset_name, $host_id\n";
    }
}

foreach my $res (@problematic_collectdata) {
    # Does a corrected version already exist ?
    my $indset_id   = $res->[0];
    my $indset_name = $res->[1];
    my $host_id     = $res->[2];
    my $sp_id       = $res->[3];
    my $other_indset_name = ($indset_name eq 'vsphere_host' ? 'vsphere_vm' : 'vsphere_host');
        
    my $found = 0;
    foreach my $cd (@$collect_data) {
        my $this_indset_name = $cd->[1];
        my $this_host_id     = $cd->[2];
        
        if ($this_indset_name eq $other_indset_name and $this_host_id == $host_id) {
            $found = 1;
            last;
        }
    }
    
    my $nr_rows_affected;
    if ($found) {
        $nr_rows_affected = $dbh->do(
            "DELETE FROM collect WHERE indicatorset_id = $indset_id AND service_provider_id = $sp_id"
        ); 
        print "$nr_rows_affected deleted\n";        
    } else {
        $nr_rows_affected = $dbh->do(
            "UPDATE collect SET indicatorset_id = ("
                . " SELECT indicatorset_id FROM indicatorset WHERE indicatorset_name = '$other_indset_name')"
            . " WHERE indicatorset_id = $indset_id AND service_provider_id = $sp_id"
        );
        print "$nr_rows_affected updated\n";
    }
}
