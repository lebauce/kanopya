package solver;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.List;

import solver.constraints.IntConstraintFactory;
import solver.search.solution.SolutionPoolFactory;
import solver.search.strategy.strategy.Assignment;
import solver.selectors.values.SelectHypervisorWrtSize;
import solver.selectors.variables.BiggestUnassignedVM;
import model.Hypervisor;
import model.InfraConfiguration;
import model.VirtualMachine;

/**
 * Extension of the Virtual Machine Packing Problem where migrations of already packed vms are forbidden.
 */
public class VMsPPNoMigration extends VMsPackingProblem {

    public VMsPPNoMigration(InfraConfiguration initial_config) {
        super(initial_config);
        this.fixPackedVMsDomains();
    }

    public VMsPPNoMigration(InfraConfiguration initial_config, List<Hypervisor> hypervisors) {
        super(initial_config);
        this.fixPackedVMsDomains(hypervisors);
    }

    private void fixPackedVMsDomains() {
        this.fixPackedVMsDomains(new ArrayList<Hypervisor>(0));
    }

    /**
     * Fix the domains of the already packed VMs to forbid their migration.
     * @param hypervisors
     */
    private void fixPackedVMsDomains(List<Hypervisor> hypervisors) {

        Map<Integer, Boolean> hm = new HashMap<Integer,Boolean>();
        for (Hypervisor hv : hypervisors) {
            hm.put(hv.getId(),true);
        }

        for (int i = 0; i < this.m_VMs.length; i++) {
            int hv_id    = this.m_initial_config.getVirtualMachines().get(i).getHypervisorId();
            if (hv_id != VirtualMachine.NO_HOST_HV_ID) {
                if (! hm.containsKey(hv_id)) {
                    int hv_index = this.m_initial_config.getHypervisorsIdsMapping().get(hv_id);
                    this.m_solver.post(IntConstraintFactory.arithm(this.m_VMs[i], "=", hv_index));
                }
            }
        }
    }

    /**
     * Set heuristics use for virtual machine selection and hypervisor selection during solving
     */
    @Override
    public void configureSolver() {

        boolean selectMinHypervisor;
//        selectMinHypervisor = (this.getInitialConfiguration().getUnassignedVirtualMachines().size() == 1);
        selectMinHypervisor = true;
        this.m_solver.set(
                new Assignment(
                        new BiggestUnassignedVM(
                                this.m_VMs,
                                this.m_VMsResources
                        ),
//                        new InDomainRandom(System.currentTimeMillis())
//                         new MinRemainingRessourcesHV(this.m_HVsUsages)
                        new SelectHypervisorWrtSize(this.m_HVsUsages, this.m_VMsResources, selectMinHypervisor, true)
//                        new BiggestHV(m_HVsResources)
//                        new LBWithDomainBreaker(this.m_HVsUsages)
                )
        );
        this.m_solver.set(SolutionPoolFactory.LAST_ONE.make());
    }

}
