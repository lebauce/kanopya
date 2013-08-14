package solver;

import solver.constraints.IntConstraintFactory;
import solver.variables.IntVar;
import solver.variables.VariableFactory;
import model.Hypervisor;
import model.InfraConfiguration;

public class VMsPPNMEmptyOneHv extends VMsPPNoMigration {

    /**
     * Hypervisor of which we want to minimize the number of virtual machines
     */
    private Hypervisor m_hypervisor;

    /**
     * Number of virtual machines put in m_hypervisor
     */
    IntVar m_num_of_vm_in_hv;


    public VMsPPNMEmptyOneHv(InfraConfiguration initial_config, Hypervisor hypervisor, int num_of_vm) {
        super(initial_config);
        this.m_hypervisor = hypervisor;
        this.configureNumOfVMMinimization();
    }

    /**
     * Set variable m_num_of_vm_in_hv equals to the number of virtual machines put in hypervisor
         * m_hypervisor in order to minimize it
     */
    private void configureNumOfVMMinimization() {
        int local_index = this.getInitialConfiguration().getHypervisorsIdsMapping().get(m_hypervisor.getId());
        m_num_of_vm_in_hv = VariableFactory.enumerated("num_of_vm_in_hv",0,this.m_bool_matrix.length,this.m_solver);
        this.m_solver.post(IntConstraintFactory.sum(this.m_bool_matrix_inv[local_index], this.m_num_of_vm_in_hv));
    }

    /**
     * Set objective to minimize the number of virtual machines in hypervisor computed
     * in m_num_of_vm_in_hv
     */
    @Override
    public boolean solve() {
        this.m_solver.findOptimalSolution(ResolutionPolicy.MINIMIZE, this.m_num_of_vm_in_hv);
        if ( !this.m_solver.getSearchLoop().getSolutionpool().isEmpty() ) {
            return true;
        } else {
            return false;
        }
    }
}
