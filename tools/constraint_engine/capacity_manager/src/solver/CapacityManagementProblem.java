package solver;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import solver.constraints.IntConstraintFactory;
import solver.variables.BoolVar;
import solver.variables.IntVar;
import solver.variables.VariableFactory;
import model.Hypervisor;
import model.InfraConfiguration;
import model.VirtualMachine;

/**
 * Abstract class representing a problem related to a deployment/capacity management issue.
 */
public abstract class CapacityManagementProblem {

    /**
     * The Choco solver.
     */
    protected Solver m_solver;

    /**
     * The initial configuration of the infrastructure.
     */
    protected InfraConfiguration m_initial_config;

    /**
     * The final configuration after solving.
     */
    protected InfraConfiguration m_final_config;

    /**
     * The boolean assignment matrix M(i,j) = 1 <=> VM i is hosted on HV j.
     */
    protected BoolVar[][] m_bool_matrix;

    /**
     * The inverse boolean assignment matrix M(j,i) = 1 <=> HV j is hosting VM i.
     */
    protected BoolVar[][] m_bool_matrix_inv;

    /**
     * The virtual machines assignment variables : VMs[i] = j <=> VM i is hosted on HV j.
     */
    protected IntVar[] m_VMs;

    /**
     * The virtual machines resources. Ex : VMsResources {VirtualMachine.CPU_NB_KEY} [i] = 4
     *                                      <=> The VM i needs 4 CPU.
     */
    protected Map<String, int[]> m_VMsResources;

    /**
     * The hypervisors free resources. Ex : HVsResources {Hypervisor.RAM_QTY_KEY} [i] = 2048
     *                                           <=> there are 2048 Mo free on the HV i.
     */
    protected Map<String, IntVar[]> m_HVsResources;

    /**
     * The hypervisors used resources. Ex : HVsUsages {Hypervisor.CPU_NB_KEY} [i] = 4 <=> 4 cores of HV i are
     *                                                                                    currently used.
     */
    protected Map<String, IntVar[]> m_HVsUsages;

    public CapacityManagementProblem(InfraConfiguration initial_config) {
       this.m_solver         = new Solver(this.getClass().getSimpleName());
       this.m_initial_config = initial_config;
       this.m_final_config   = null;
       this.buildResources();
       this.buildAbstractProblem();
       this.configureSolver();
    }

    /**
     * @return The initial infrastructure configuration.
     */
    public InfraConfiguration getFinalConfiguration() {
        return this.m_final_config;
    }

    /**
     * @return The final infrastructure configuration.
     */
    public InfraConfiguration getInitialConfiguration() {
        return this.m_initial_config;
    }

    /**
     * @return The Choco solver attached to the problem.
     */
    public Solver getSolver() {
        return this.m_solver;
    }

    /**
     * Build virtual machines resources values and hypervisors resources variables.
     */
    private void buildResources() {
        // Build VMs resources
        List<VirtualMachine> vms = this.m_initial_config.getVirtualMachines();
        int[] cpu_values         = new int[vms.size()];
        int[] ram_values         = new int[vms.size()];

        for (int i = 0; i < vms.size(); i++) {
            cpu_values[i] = vms.get(i).getResources().get(VirtualMachine.CPU_NB_KEY);
            ram_values[i] = vms.get(i).getResources().get(VirtualMachine.RAM_QTY_KEY);
        }

        this.m_VMsResources = new HashMap<String, int[]>(vms.size());
        this.m_VMsResources.put(VirtualMachine.CPU_NB_KEY, cpu_values);
        this.m_VMsResources.put(VirtualMachine.RAM_QTY_KEY, ram_values);

        // Build HVs resources
        List<Hypervisor> hvs   = this.m_initial_config.getHypervisors();
        IntVar[] cpu_free_vars = new IntVar[hvs.size()];
        IntVar[] cpu_used_vars = new IntVar[hvs.size()];
        IntVar[] ram_free_vars = new IntVar[hvs.size()];
        IntVar[] ram_used_vars = new IntVar[hvs.size()];

        for (int j = 0; j < hvs.size(); j++) {
            int cpu_upB      = hvs.get(j).getResources().get(Hypervisor.CPU_NB_KEY);
            cpu_free_vars[j] = VariableFactory.bounded("cpu_free_hv_" + j, 0, cpu_upB, this.m_solver);
            cpu_used_vars[j] = VariableFactory.bounded("cpu_used_hv_" + j, 0, cpu_upB, this.m_solver);
            int ram_upB      = hvs.get(j).getResources().get(Hypervisor.RAM_QTY_KEY);
            ram_free_vars[j] = VariableFactory.bounded("ram_free_hv_" + j, 0, ram_upB, this.m_solver);
            ram_used_vars[j] = VariableFactory.bounded("ram_used_hv_" + j, 0, ram_upB, this.m_solver);
        }

        this.m_HVsResources = new HashMap<String, IntVar[]>(hvs.size());
        this.m_HVsResources.put(Hypervisor.CPU_NB_KEY, cpu_free_vars);
        this.m_HVsResources.put(Hypervisor.RAM_QTY_KEY, ram_free_vars);
        this.m_HVsUsages = new HashMap<String, IntVar[]>(hvs.size());
        this.m_HVsUsages.put(Hypervisor.CPU_NB_KEY, cpu_used_vars);
        this.m_HVsUsages.put(Hypervisor.RAM_QTY_KEY, ram_used_vars);
    }

    /**
     * Build the abstract problem, ie initialize variables and post channeling constraint between boolean
     * assignment variable and VM assignment vector.
     */
    private void buildAbstractProblem() {
        List<VirtualMachine> vms = this.m_initial_config.getVirtualMachines();
        List<Hypervisor> hvs     = this.m_initial_config.getHypervisors(); 

        // Build boolean variable assignment matrixes
        this.m_bool_matrix     = new BoolVar[vms.size()][hvs.size()];
        this.m_bool_matrix_inv = new BoolVar[hvs.size()][vms.size()];
        for (int i = 0; i < vms.size(); i++) {
            for (int j = 0; j < hvs.size(); j++) {
                this.m_bool_matrix[i][j]     = VariableFactory.bool("VM_" + i + "_on_HV_" + j, this.m_solver);
                this.m_bool_matrix_inv[j][i] = this.m_bool_matrix[i][j];
            }
        }

        // Build vm variable assignment vector
        this.m_VMs = VariableFactory.enumeratedArray("VM_assign", vms.size(), 0, hvs.size(), this.m_solver);

        // Post Channeling constraint between boolean assignment variables and assignement vector
        for (int i = 0; i < vms.size(); i++) {
            this.m_solver.post(
                    IntConstraintFactory.boolean_channeling(this.m_bool_matrix[i], this.m_VMs[i])
            );
        }
    }

    /**
     * Method to override for configuring the solver.
     */
    public abstract void configureSolver();

    /**
     * Method to override for lauching the resolution of the problem.
     * @return true if a solution had been found.
     */
    public abstract boolean solve();

    /**
     * Method to override for restoring the final configuration from the solver after the resolution.
     * @throws Exception if the solutions pool of the solver is empty
     */
    public abstract void restoreFinalConfiguration();

    /**
     * Method to override for printing a pretty text output for a solution.
     */
    public void prettyOut() {
        String mid        = "* Initial Infrastructure Configuration *";
        String top_bottom = "";
        for (int i = 0; i < mid.length(); i++) {
            top_bottom += "*";
        }
        System.out.println(top_bottom + "\n" + mid + "\n" + top_bottom + "\n");
        System.out.println(this.m_initial_config);

        mid        = "* Final Infrastructure Configuration *";
        top_bottom = "";
        for (int i = 0; i < mid.length(); i++) {
            top_bottom += "*";
        }
        System.out.println("\n" + top_bottom + "\n" + mid + "\n" + top_bottom + "\n");
        if (this.m_final_config != null) {
            System.out.println(this.m_final_config);
        } else {
            System.out.println("No final configuration had been found");
        }
    }
}
