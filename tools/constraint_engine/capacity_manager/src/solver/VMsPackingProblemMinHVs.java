package solver;

import solver.constraints.IntConstraintFactory;
import solver.variables.IntVar;
import solver.variables.VariableFactory;
import model.InfraConfiguration;

/**
 * An extension of the virtual machines packing problem where the number of unused hypervisors is maximized.
 */
public class VMsPackingProblemMinHVs extends VMsPackingProblem{

    /**
     * The number of unused hypervisors.
     */
    private IntVar m_unused_hv_nb;

    public VMsPackingProblemMinHVs(InfraConfiguration initial_config) {
        super(initial_config);
        this.buidObjective();
    }

    /**
     * Build the objective variable, ie the variable representing the number of unused hypervisors.
     */
    private void buidObjective() {
        // sum each inverse assignment matrix rows <=> number of hosted VMs
        IntVar[] sums = VariableFactory.boundedArray(
                "sum",
                this.m_bool_matrix_inv.length,
                0,
                this.m_VMs.length,
                this.m_solver
        );
        for (int i = 0; i < this.m_bool_matrix_inv.length; i++) {
            this.m_solver.post(IntConstraintFactory.sum(this.m_bool_matrix_inv[i], sums[i]));
        }
        this.m_unused_hv_nb = VariableFactory.bounded(
                "unused_hvs",
                0,
                this.m_bool_matrix_inv.length,
                this.m_solver
        );
        this.m_solver.post(IntConstraintFactory.count(0, sums, this.m_unused_hv_nb));
    }

    @Override
    public boolean solve() {
        this.m_solver.findOptimalSolution(ResolutionPolicy.MAXIMIZE, this.m_unused_hv_nb);
        if ( !this.m_solver.getSearchLoop().getSolutionpool().isEmpty() ) {
            return true;
        } else {
            return false;
        }
    }
}
