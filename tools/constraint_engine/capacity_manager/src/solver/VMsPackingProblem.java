package solver;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import solver.constraints.IntConstraintFactory;
import solver.search.solution.SolutionPoolFactory;
import solver.search.strategy.selectors.values.InDomainRandom;
import solver.search.strategy.strategy.Assignment;
import solver.selectors.variables.BiggestUnassignedVM;
import solver.variables.IntVar;
import model.Hypervisor;
import model.InfraConfiguration;
import model.VirtualMachine;

/**
 * Virtual machines assignment problem (Knapsack on each VM caracteristic).
 * The target is to assign all the virtual machines of the initial infrastructure on the hypervisors of the
 * same infrastructure. The result
 */
public class VMsPackingProblem extends CapacityManagementProblem {

    public VMsPackingProblem(InfraConfiguration initial_config) {
        super(initial_config);
        this.buildPackingProblem();
    }

    /**
     * Build the generic virtual machines on hypervisors packing problem.
     */
    private void buildPackingProblem() {

        // Post Knapsack constraints (CPU and RAM) for each hypervisor
        for (int j = 0; j < this.m_initial_config.getHypervisors().size(); j++) {

            IntVar hv_free_cpu = this.m_HVsResources.get(Hypervisor.CPU_NB_KEY)[j];
            IntVar hv_used_cpu = this.m_HVsUsages.get(Hypervisor.CPU_NB_KEY)[j];
            IntVar hv_free_ram = this.m_HVsResources.get(Hypervisor.RAM_QTY_KEY)[j];
            IntVar hv_used_ram = this.m_HVsUsages.get(Hypervisor.RAM_QTY_KEY)[j];

            /* CPU Knapsack */
            this.m_solver.post(
                    IntConstraintFactory.knapsack(
                            this.m_bool_matrix_inv[j],
                            hv_free_cpu,
                            hv_used_cpu,
                            this.m_VMsResources.get(VirtualMachine.CPU_NB_KEY),
                            this.m_VMsResources.get(VirtualMachine.CPU_NB_KEY)
                    )
            );
            /* Ram Knapsack */
            this.m_solver.post(
                    IntConstraintFactory.knapsack(
                            this.m_bool_matrix_inv[j],
                            hv_free_ram,
                            hv_used_ram,
                            this.m_VMsResources.get(VirtualMachine.RAM_QTY_KEY),
                            this.m_VMsResources.get(VirtualMachine.RAM_QTY_KEY)
                    )
            );
        }
        this.breakVmSymetries();
    }

    /**
     * Symetries breaker: create groups of equivalent virtual machines (same quantity of ram,
     * same number of cpu) and put an order in assigned hypervisor on a same group in order to avoid to test
     * symetrical configurations
     */
    private void breakVmSymetries() {
        List<VirtualMachine> unassigned_vms = this.m_initial_config.getUnassignedVirtualMachines();

        Map<Integer, Boolean> vm_index = new HashMap<Integer,Boolean>();

        for (VirtualMachine vm : unassigned_vms) {
            vm_index.put(this.getInitialConfiguration().getVirtualMachinesIdsMapping().get(vm.getId()), true);
        }

        List<List<Integer>> vm_groups = new ArrayList<List<Integer>>(unassigned_vms.size());

        /* Construct groups of same ressources VM */
        while(! vm_index.isEmpty()) {
            Iterator<Integer> vm_iterator = vm_index.keySet().iterator();
            Integer first_vm = vm_iterator.next();

            vm_iterator.remove();
            int first_vm_ram = this.m_VMsResources.get(VirtualMachine.RAM_QTY_KEY)[first_vm];
            int first_vm_cpu = this.m_VMsResources.get(VirtualMachine.CPU_NB_KEY)[first_vm];
            ArrayList<Integer> vm_group = new ArrayList<Integer>(unassigned_vms.size());
            vm_group.add(first_vm);
            while (vm_iterator.hasNext()) {
                Integer compare_vm = vm_iterator.next();
                if (first_vm_ram == this.m_VMsResources.get(VirtualMachine.RAM_QTY_KEY)[compare_vm]
                    && first_vm_cpu == this.m_VMsResources.get(VirtualMachine.CPU_NB_KEY)[compare_vm]) {
                        vm_group.add(compare_vm);
                        vm_iterator.remove();
                }
            }
            vm_groups.add(vm_group);
        }

        /* Set an order in the assigned hypervisor number in order to break symetrical solutions */
        for (List<Integer> group : vm_groups) {
            if (group.size() > 1) {
                for (int i = 1; i < group.size(); i++) {
                    this.m_solver.post(IntConstraintFactory.arithm(this.m_VMs[group.get(i-1)], "<=", this.m_VMs[group.get(i)]));
                }
            }
        }
    }

    @Override
    public void configureSolver() {
        this.m_solver.set(
                new Assignment(
                        new BiggestUnassignedVM(
                                this.m_VMs,
                                this.m_VMsResources
                        ),
                        new InDomainRandom(System.currentTimeMillis())
//                        new MinRemainingRessourcesHV(this.m_HVsUsages)
//                        new BiggestHV(m_HVsResources)
                )
        );
        this.m_solver.set(SolutionPoolFactory.LAST_ONE.make());
    }

    @Override
    public boolean solve() {
        return this.m_solver.findSolution();
    }

    @Override
    public void restoreFinalConfiguration() {
        if ( !this.m_solver.getSearchLoop().getSolutionpool().isEmpty() ) {
            this.m_solver.getSearchLoop().getSolutionpool().getBest().restore();
            this.m_final_config = new InfraConfiguration(this.m_initial_config);
            List<VirtualMachine> vms = this.m_final_config.getVirtualMachines();
            List<Hypervisor> hvs     = this.m_final_config.getHypervisors();
            for (Hypervisor hv : hvs) {
                hv.setHostedVirtualMachinesIds(new HashMap<Integer, Boolean>());
            }
            for (int vm = 0; vm < this.m_final_config.getVirtualMachines().size(); vm++) {
                int hv_id = this.m_final_config.getHypervisors().get(this.m_VMs[vm].getValue()).getId();
                vms.get(vm).setHypervisorId(hv_id);
                Hypervisor hosting_hv = this.m_final_config.getHostingHypervisor(vms.get(vm));
                hosting_hv.getHostedVirtualMachinesIds().put(vms.get(vm).getId(), true);
            }
        }
    }
}
