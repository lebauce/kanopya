package solver;

import solver.constraints.IntConstraintFactory;
import model.InfraConfiguration;
import model.VirtualMachine;

/**
 * Extension of the Virtual Machine Packing Problem where migrations of already packed vms are forbidden.
 */
public class VMsPPNoMigrations extends VMsPackingProblem {

    public VMsPPNoMigrations(InfraConfiguration initial_config) {
        super(initial_config);
        this.fixPackedVMsDomains();
    }

    /**
     * Fix the domains of the already packed VMs to forbid their migration.
     */
    private void fixPackedVMsDomains() {
        for (int i = 0; i < this.m_VMs.length; i++) {
            int hv_id    = this.m_initial_config.getVirtualMachines().get(i).getHypervisorId();
            if (hv_id != VirtualMachine.NO_HOST_HV_ID) {
                int hv_index = this.m_initial_config.getHypervisorsIdsMapping().get(hv_id);
                this.m_solver.post(IntConstraintFactory.arithm(this.m_VMs[i], "=", hv_index));
            }
        }
    }
}
