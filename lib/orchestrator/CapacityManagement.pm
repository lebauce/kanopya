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
package CapacityManagement;

use strict;
use warnings;
use Data::Dumper;
use Operation;
use Clone qw(clone);

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");

sub new {
    my $class = shift;
    my %args = @_;    
    General::checkParams(args => \%args, required => ['cluster_id']);    
    my $self = {};
    bless $self, $class;
    
    my $cluster_id = $args{cluster_id};
   
    $self->{_cluster_id} = $cluster_id;
    $self->{_infra}      = $self->_constructInfra();
    return $self;
}
sub getInfra{
    my ($self) = @_;
    return $self->{_infra};
}



sub _constructInfra{
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => []);
    
    #my $cluster_id = $self->{_cluster_id}; 
    
    my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $self->{_cluster_id});
    
    #GET LIST OF ALL HV
    my $hvs;
    my $opennebula = Entity->get(id => $cluster->getAttr(name => "host_manager_id"));
    my $hypervisors_r = $opennebula->{_dbix}->opennebula3_hypervisors;
    
    while (my $row = $hypervisors_r->next) {
        my $hypervisor = Entity::Host->get(id => $row->get_column('hypervisor_host_id'));
        my $hv_id = $row->get_column('hypervisor_host_id');
        $hvs->{$hv_id}->{'hv_capa'} = {
            ram => $hypervisor->getHostRAM(),
            cpu => $hypervisor->getHostCORE(),    
        };
        $hvs->{$hv_id}->{'vm_ids'} = [];
    }

    my $current_hosts   = $cluster->getHosts(administrator => Administrator->new);
    my $vms;

    while( my ($id, $vm) = each %$current_hosts) {
        $vms->{$id}->{ram} = $vm->getHostRAM();
        $vms->{$id}->{cpu} = $vm->getHostCORE();
        
        my $hvid      = $vm->getHyperVisorHostId();
        
        if(defined $hvs->{$hvid}){
            push @{$hvs->{$hvid}->{'vm_ids'}}, $id;
        }else{
            $hvs->{$hvid}->{'vm_ids'} = [$id];
        }
    }
   

    
    my $current_infra = {
        vms => $vms,
        hvs => $hvs,
    };
    
    $log->info(Dumper $current_infra);
    return $current_infra;
}

sub scaleMemoryHost{
    my ($self,%args) = @_;
    
    General::checkParams(args => \%args, required => ['host_id','memory']);
    
    my @hv_selection_ids = keys %{$self->{_infra}->{hvs}};
    
    $log->info("Call scaleMemoryMetric for host $args{host_id} and new value = $args{vcpu_number}");
    $self->_scaleMetric(
        infra            => $self->{_infra},
        vm_id            => $args{host_id},
        new_value        => $args{memory}*1024*1024, #Memory given in MB
        hv_selection_ids => \@hv_selection_ids,
        scale_metric     => 'ram',
    );
};

sub scaleCpuHost{
    my ($self,%args) = @_;
    
    General::checkParams(args => \%args, required => ['host_id','vcpu_number']);
        
    my @hv_selection_ids = keys %{$self->{_infra}->{hvs}};
    
    $log->info("Call scaleCpuMetric for host $args{host_id} and new value = $args{vcpu_number}");
    $self->_scaleMetric(
        infra            => $self->{_infra},
        vm_id            => $args{host_id},
        new_value        => $args{vcpu_number}, 
        hv_selection_ids => \@hv_selection_ids,
        scale_metric     => 'cpu',
    );
};

sub _scaleMetric {
    my ($self,%args) = @_;
   
    my $scale_metric     = $args{scale_metric}; 
    my $infra            = $args{infra};
    
    my $vm_id            = $args{vm_id};
    my $new_value        = $args{new_value};
    
    my $hv_selection_ids = $args{hv_selection_ids};
    
    $log->info(Dumper $infra);
    
    my $old_value = $infra->{vms}->{$vm_id}->{$scale_metric}; 
    my $delta     = $new_value - $old_value;
    
    
    my $hv_id    = $self->_getHvIdFromVmId(
                      hvs   => $infra->{hvs},
                      vm_id => $vm_id,
                   );
    
    
    if($delta < 0){
        $self->_scaleOrder(
            vm_id        => $vm_id, 
            new_value    => $new_value, 
            vms          => $infra->{vms},
            scale_metric => $scale_metric
        );
    }
    elsif($delta > 0){
        
        my $size_remaining = $self->_getHvSizeRemaining(
            infra => $infra,
            hv_id => $hv_id,
        );

        if($size_remaining->{$scale_metric} >= $delta){ # CAN SCALE ON THE SAME HV
            $self->_scaleOrder(
            vm_id => $vm_id, new_value => $new_value, vms => $infra->{vms}, scale_metric => $scale_metric
            );
        }
        else{
            $log->info("Cannot increase $scale_metric, try to migrate the VM");            
            #TRY TO MIGRATE THE VM IN ORDER TO SCALE IT
            my $result = $self->_migrateVmToScale(
                vm_id             => $vm_id,
                scale_metric      => $scale_metric, 
                new_value         => $new_value, 
                infra             => $infra,
                hv_selection_ids  => $hv_selection_ids,
            );
            
          if($result == 1){
              $self->_scaleOrder(
                  vm_id        => $vm_id, 
                  new_value    => $new_value,
                  vms          => $infra->{vms},
                  scale_metric => $scale_metric,
              );
            }else{ # TRY TO MIGRATE ANOTHER VM
            $log->info("Cannot migrate the VM, try to migrate another VM");            

              my $result = $self->_migrateOtherVmToScale(
                infra             => $infra,
                vm_id             => $vm_id,
                new_value         => $new_value,
                hv_selection_ids  => $hv_selection_ids,
                scale_metric      => $scale_metric,
              );
              
              if($result == 1){
                  $self->_scaleOrder(
                      vm_id        => $vm_id, 
                      new_value    => $new_value,
                      vms          => $infra->{vms},
                      scale_metric => $scale_metric,
                  );
              }else{
                  $log->info("NOT ENOUGH PLACE TO CHANGE $scale_metric OF $vm_id TO VALUE $new_value");
              }
              
            }
        }
    }
}

sub _getHvSizeOccupied{
    my ($self,%args) = @_;
    my $infra          = $args{infra};
    my $hv_id          = $args{hv_id};
    
    my $hv_vms = $infra->{hvs}->{$hv_id}->{vm_ids};
    my $size   = {cpu => 0, ram => 0};
    
    for my $vm_id (@$hv_vms){        
        $size->{cpu} += $infra->{vms}->{$vm_id}->{cpu};
        $size->{ram} += $infra->{vms}->{$vm_id}->{ram};
    }
    return $size;
}

sub _getHvSizeRemaining {
   my ($self,%args) = @_;
    my $infra          = $args{infra};
    my $hv_id          = $args{hv_id};

    my $size = $self->_getHvSizeOccupied(infra => $infra, hv_id => $hv_id);

#    print "# $hv_id \n";
#    print Dumper $size; 
    
    my $all_the_ram   = $infra->{hvs}->{$hv_id}->{hv_capa}->{ram};
    my $all_the_cpu   = $infra->{hvs}->{$hv_id}->{hv_capa}->{cpu};
    
    my $remaining_ram = $all_the_ram - $size->{ram};

    
    my $remaining_cpu = $all_the_cpu - $size->{cpu};
    
    my $size_rem = {
        ram   => $remaining_ram,
        cpu   => $remaining_cpu,
        ram_p => $remaining_ram / $all_the_ram,
        cpu_p => $remaining_cpu / $all_the_cpu,
    };
    return $size_rem;
}



sub _getHvIdFromVmId{
    my ($self,%args) = @_;
    my $hvs   = $args{hvs};
    my $vm_id = $args{vm_id};
    
    my $hv_id;
    
    HV:for my $hv_id_it (keys %$hvs){
        my $vm_ids = $hvs->{$hv_id_it}->{vm_ids};
        for my $vm_id_it (@$vm_ids){
            if($vm_id == $vm_id_it){
                $hv_id = $hv_id_it;
                last HV;
            }
        }
    }
    
    return $hv_id;
}

sub _scaleOrder{
    my ($self,%args) = @_;
    my $vm_id             = $args{vm_id};
    my $new_value         = $args{new_value};
    my $vms               = $args{vms};
    my $scale_metric      = $args{scale_metric};
    $vms->{$vm_id}->{$scale_metric} = $new_value;

    
     if($scale_metric eq 'ram'){
       $log->info("=> Operation scaling $scale_metric of vm $vm_id to $new_value");

        Operation->enqueue(
            type => 'ScaleMemoryHost',
            priority => 1,
            params => {
                host_id => $vm_id,
                memory  => $new_value / (1024*1024)
            }
        );
    }elsif ($scale_metric eq 'cpu'){
        $log->info("=> Operation scaling $scale_metric of vm $vm_id to $new_value");

       Operation->enqueue(
        type => 'ScaleCpuHost',
        priority => 1,
        params => {
            host_id    => $vm_id,
            cpu_number => $new_value
        }
    );
        
     }
}

sub _migrateVmOrder{
    my ($self,%args) = @_;
    my $vm_id      = $args{vm_id};
    my $hv_dest_id = $args{hv_dest_id};
    my $hvs        = $args{hvs};
    
    while (my ($hv_id, $hv) = each %$hvs) {
        my $count = 0;
        my $index_search;
        for my $vm_id_p (@{$hv->{vm_ids}}){
            if($vm_id == $vm_id_p){
                $index_search = $count; 
                last;
            }
            $count++
        }
        if(defined $index_search){
            splice @{$hv->{vm_ids}}, $index_search,1;
        }
    }
    
    push @{$hvs->{$hv_dest_id}->{vm_ids}}, $vm_id;

    Operation->enqueue(
        type => 'MigrateHost',
        priority => 1,
        params => {
           host_id        => $vm_id,
           hypervisor_dst => $hv_dest_id,
        }
    );
    
    $log->info("=> migration $vm_id to $hv_dest_id");
}

sub _migrateVmToScale{
    my ($self,%args) = @_;
    
    my $vm_id            = $args{vm_id}; 
    my $new_value        = $args{new_value}; 
    my $infra            = $args{infra};
    my $hv_selection_ids = $args{hv_selection_ids};
    my $scale_metric     = $args{scale_metric};
    
    my $wanted_metrics  = clone($infra->{vms}->{$vm_id});
    $wanted_metrics->{$scale_metric} = $new_value;
    
    my $hv_dest_id = $self->_findMinHVidRespectCapa(
        infra            => $infra,
        hv_selection_ids => $hv_selection_ids,
        wanted_metrics   => $wanted_metrics,
    );
    
    if(defined $hv_dest_id){
        $log->info("MIGRATION OF VM $vm_id in HV $hv_dest_id->{hv_id}");
        $self->_migrateVmOrder(
            vm_id      => $vm_id, 
            hv_dest_id => $hv_dest_id->{hv_id}, 
            hvs        => $infra->{hvs}
        );
        return 1;
    }else{
        return 0;
    }
}

sub _findMinHVidRespectCapa{
    my ($self,%args) = @_;
    my $hvs_selection_ids = $args{hv_selection_ids};
    my $wanted_metrics    = $args{wanted_metrics};
    my $infra             = $args{infra};
    
    
    my $rep;
    for my $hv_id (@$hvs_selection_ids){
        
        my $size_remaining = $self->_getHvSizeRemaining(
            infra => $infra,
            hv_id => $hv_id,
        );
        
        my $total_score = $size_remaining->{cpu_p} + $size_remaining->{ram_p};
        
        if(
               $wanted_metrics->{ram} <= $size_remaining->{ram}
            && $wanted_metrics->{cpu} <= $size_remaining->{cpu}
        ){
            
            if(defined $rep->{min_size_remaining}){
                if($total_score < $rep->{min_size_remaining}){
                    $rep->{min_size_remaining} = $total_score;
                    $rep->{hv_id}              = $hv_id;
                }
            }else{
                $rep->{min_size_remaining} = $total_score,
                $rep->{hv_id}              = $hv_id;
            }
        }
    }
    
    return $rep
}





sub _migrateOtherVmToScale{
    my ($self,%args) = @_;
    my $infra            = $args{infra};
    my $vm_id            = $args{vm_id}; 
    my $new_value        = $args{new_value}; 
    my $hv_selection_ids = $args{hv_selection_ids};
    my $scale_metric     = $args{scale_metric};

    my $hv_id            = $self->_getHvIdFromVmId(
                              hvs   => $infra->{hvs},
                              vm_id => $vm_id,
    );
    
    my $vms_in_hv        = $infra->{hvs}->{$hv_id}->{vm_ids};
    
    my $delta            = $new_value - $infra->{vms}->{$vm_id}->{$scale_metric}; 
    my $remaining_size   = $self->_getHvSizeRemaining(
                               infra => $infra,
                               hv_id => $hv_id,
                           ); 
    
    
    #Other vm which could be migrated instead of current vm (according to analyzed metric)
    my @other_vms        = grep {
                                #print ($infra->{vms}->{$_}->{$scale_metric});
                                  $infra->{vms}->{$_}->{$scale_metric}  + $remaining_size->{$scale_metric} >= $delta   #otherwise too small 
                               && $infra->{vms}->{$_}->{$scale_metric} < $new_value #otherwise the other one could have been migrated 
                               &&  $_ != $vm_id
                           } @$vms_in_hv;


    $log->info("Remaining size = $remaining_size->{$scale_metric}, Need size = $delta, potential VM to scale (according to $scale_metric) = @other_vms");
    
    
    #Find one with other metric OK
    my @sorted_vms = sort {$infra->{vms}->{$b}->{$scale_metric} <=> $infra->{vms}->{$a}->{$scale_metric}} @other_vms;
    my $hv_dest_id;
    my $vm_to_migrate_id;

    while((!defined $hv_dest_id) && (scalar @sorted_vms > 0)){
        

        $vm_to_migrate_id = pop @sorted_vms;
        $log->info("Check $vm_to_migrate_id migration possibility...");
        
        $hv_dest_id = $self->_findMinHVidRespectCapa(
            infra            => $infra,
            hv_selection_ids => $hv_selection_ids,
            wanted_metrics   =>  $infra->{vms}->{$vm_to_migrate_id},
        );
    }
    
    if(defined $hv_dest_id){
        $self->_migrateVmOrder(
            vm_id      => $vm_to_migrate_id, 
            hv_dest_id => $hv_dest_id->{hv_id}, 
            hvs        => $infra->{hvs}
        );
        return 1;
    }else{
        return 0;
    }
}




1;