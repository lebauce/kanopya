package solver;

import java.util.HashMap;
import java.util.List;

import solver.constraints.IntConstraintFactory;
import solver.search.solution.SolutionPoolFactory;
import solver.search.strategy.selectors.values.InDomainRandom;
import solver.search.strategy.strategy.Assignment;
import solver.selectors.values.BiggestHV;
import solver.selectors.values.MinRemainingRessourcesHV;
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

            // CPU Knapsack
            this.m_solver.post(
                    IntConstraintFactory.knapsack(
                            this.m_bool_matrix_inv[j],
                            hv_free_cpu,
                            hv_used_cpu,
                            this.m_VMsResources.get(VirtualMachine.CPU_NB_KEY),
                            this.m_VMsResources.get(VirtualMachine.CPU_NB_KEY)
                    )
            );
            // Ram Knapsack
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