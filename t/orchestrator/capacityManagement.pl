#use lib qw(/home/tgenin/.gvfs/sftp for hedera on 192.168.0.131/opt/kanopya/lib/orchestrator);
use lib qw(
    /opt/kanopya/lib/administrator
    /opt/kanopya/lib/common
    /opt/kanopya/lib/executor
    /opt/kanopya/lib/external
    /opt/kanopya/lib/monitor
    /opt/kanopya/lib/orchestrator
);
use CapacityManagement;
use Data::Dumper;
use Clone qw(clone);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});
my $log = get_logger("administrator");

#my $infra = manualInfra();
my $infra = automaticInfra();
my $infra2 = clone($infra);

my $cm = CapacityManagement->new(test => 1,infra=>$infra);
$cm->optimIaas();
my $cm2 = CapacityManagement->new(test => 1,infra=>$infra2);
my $stat2 = $cm2->computeInfraChargeStat();
my $stat1 = $cm->computeInfraChargeStat();


#

#my @test = map  { @{ $infra->{hvs}->{$_}->{vm_ids} } } (keys %{$infra->{hvs}});
#print "****\n";
#print "@test \n";
#print "size of = ".@test." lul \n";
#
#my @test2 = map  { @{ $infra->{hvs}->{$_}->{vm_ids} } } (keys %{$infra2->{hvs}});
#print "****\n";
#print "@test2 \n";
#print "size of = ".@test2." lul \n";


sub manualInfra{
my $infra = {
          vms => {
                     1 => {cpu => 3, ram => 1},
                     3 => {cpu => 1, ram => 3},
                     5 => {cpu => 1, ram => 2},
                     6 => {cpu => 1, ram => 2},
                     7 => {cpu => 1, ram => 2},
                     8 => {cpu => 1, ram => 2},
                   },
          hvs => {  1 => {vm_ids  => [1],
                        hv_capa => {cpu => 4,ram => 8}},
                    2 => {vm_ids  => [3],
                          hv_capa => {cpu => 4,ram => 8}},
                    3 => {vm_ids  => [5,6],
                          hv_capa => {cpu => 4,ram => 8}},
                    4 => {vm_ids  => [7,8],
                          hv_capa => {cpu => 4,ram => 8}},
                   }
        };


    $infra = {
              'vms' => {
                         '214' => {
                                    'cpu' => '1',
                                    'ram' => '2147483648'
                                  },
                         '216' => {
                                    'cpu' => '1',
                                    'ram' => '2147483648'
                                  },
                         '218' => {
                                    'cpu' => '1',
                                    'ram' => '4147483648'
                                  }
                       },
              'hvs' => {
                         '72' => {
                                   'vm_ids' => [
                                                 '218'
                                               ],
                                   'hv_capa' => {
                                                  'cpu' => '4',
                                                  'ram' => '8589934592'
                                                }
                                 },
                         '71' => {
                                   'vm_ids' => [
                                                 '216',
                                                 '214'
                                               ],
                                   'hv_capa' => {
                                                  'cpu' => '4',
                                                  'ram' => '8589934592'
                                                }
                                 }
                       }
            };
    return $infra;
};

sub automaticInfra{
    srand(1);
    my $vms;
    my $hvs;
    
    my $hv_capa     = {ram => 32, cpu => 16};
    my $num_hvs     = 50;
    my $max_size_vm = {ram => 16, cpu => 8};
    my $num_vm_max  = 4;
    
    my $vm_counter  = 0;
    
    for my $index_hv (0..$num_hvs-1){
        my @hv;
        
        my $remaining_size = clone($hv_capa);
        my $num_vm = int(rand($num_vm_max))+1;

        VM:for my $index_vm (0..$num_vm-1){

            my $size = {
                ram => int(rand($max_size_vm->{ram}))+1,
                cpu => int(rand($max_size_vm->{cpu}))+1,
            };
            
            if(
               $remaining_size->{ram} >= $size->{ram}
            && $remaining_size->{cpu} >= $size->{cpu}
            
            ){

                $remaining_size->{ram} -= $size->{ram};
                $remaining_size->{cpu} -= $size->{cpu};
                
                push @hv, $vm_counter;
                $vms->{$vm_counter} = $size;
                $vm_counter++;
            }else{
                last VM;
            }
        }
        $hvs->{$index_hv}->{vm_ids} = \@hv;
        $hvs->{$index_hv}->{hv_capa} = clone($hv_capa);
    }
    
    my $rep = {
        hvs     => $hvs,
        vms     => $vms,
    };
    return $rep;
}
