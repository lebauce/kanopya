package solver;

import java.util.ArrayList;
import java.util.List;

import solver.constraints.Arithmetic;
import solver.constraints.IntConstraintFactory;
import solver.search.solution.SolutionPoolFactory;
import solver.search.strategy.strategy.Assignment;
import solver.selectors.values.SelectHypervisorWrtSize;
import solver.selectors.variables.BiggestUnassignedVM;
import solver.variables.BoolVar;
import solver.variables.IntVar;
import solver.variables.VariableFactory;
import model.Hypervisor;
import model.InfraConfiguration;
import model.VirtualMachine;

public class VMsPPMinMigrations extends VMsPackingProblem {

    IntVar m_num_of_migrations;
    BoolVar[] m_hasMigrated;
    int[] initial_assigment;
    List<VirtualMachine> assigned_virtual_machines;

    public VMsPPMinMigrations(InfraConfiguration initial_config, List<VirtualMachine> vms, Hypervisor hv) {
        super(initial_config);
        this.configureFixHypervisor(vms,hv);
        this.configureNumOfVMMinimization();
    }

    private void configureFixHypervisor(List<VirtualMachine> vms, Hypervisor hv) {

        int hv_index = this.getInitialConfiguration().getHypervisorsIdsMapping().get(hv.getId());

        for (VirtualMachine vm : vms) {
            int vm_index = this.getInitialConfiguration().getVirtualMachinesIdsMapping().get(vm.getId());
            this.m_solver.post(IntConstraintFactory.arithm(this.m_VMs[vm_index], "=", hv_index));
        }
    }

    /**
     * Create a new constraint variable representing the number of migrations to minimize
     */
    private void configureNumOfVMMinimization() {
        InfraConfiguration config = this.getInitialConfiguration();
        List<VirtualMachine> all_virtual_machines = config.getVirtualMachines();

        assigned_virtual_machines = new ArrayList<VirtualMachine>(all_virtual_machines.size());

        for (VirtualMachine vm : all_virtual_machines) {
            if (vm.getHypervisorId() >= 0) {
                assigned_virtual_machines.add(vm);
            }
        }

        m_num_of_migrations = VariableFactory.enumerated("num_of_vm_in_hv",
                                                 0,
                                                 assigned_virtual_machines.size(),
                                                 this.m_solver);

        initial_assigment = new int[assigned_virtual_machines.size()];

        for (int i = 0; i< initial_assigment.length; i++) {
            int hypervisor_id = assigned_virtual_machines.get(i).getHypervisorId();
            initial_assigment[i] = config.getHypervisorsIdsMapping().get(hypervisor_id);
        }

        this.minDiffAssigment(initial_assigment);
    }

    private void minDiffAssigment(int[] initial_assigment) {
        Solver solver = this.getSolver();
        m_hasMigrated = VariableFactory.boolArray("has_migrated",
                                                initial_assigment.length,
                                                solver);

        for(int i = 0; i < m_hasMigrated.length; i++) {
            int vm_index = this.getInitialConfiguration().getVirtualMachinesIdsMapping().get(assigned_virtual_machines.get(i).getId());
            Arithmetic constraint = IntConstraintFactory.arithm(this.m_VMs[vm_index], "!=", initial_assigment[i]);
            Arithmetic notconstraint = IntConstraintFactory.arithm(this.m_VMs[vm_index], "=", initial_assigment[i]);
            solver.post(IntConstraintFactory.implies(m_hasMigrated[i], constraint));
            solver.post(IntConstraintFactory.implies(VariableFactory.not(m_hasMigrated[i]), notconstraint));
        }

        solver.post(IntConstraintFactory.sum(m_hasMigrated, m_num_of_migrations));
    }

    /**
     * Configure solver to minimize variable m_num_of_migrations
     */
    @Override
    public boolean solve() {
        this.m_solver.findOptimalSolution(ResolutionPolicy.MINIMIZE, this.m_num_of_migrations);
        if ( !this.m_solver.getSearchLoop().getSolutionpool().isEmpty() ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * Set heuristics use for virtual machine selection and hypervisor selection during solving
     */
    @Override
    public void configureSolver() {

        boolean selectMinHypervisor;
//      selectMinHypervisor = (this.getInitialConfiguration().getUnassignedVirtualMachines().size() == 1);
      selectMinHypervisor = true;
      this.m_solver.set(
              new Assignment(
                      new BiggestUnassignedVM(
                              this.m_VMs,
                              this.m_VMsResources
                      ),
//                      new InDomainRandom(System.currentTimeMillis())
//                       new MinRemainingRessourcesHV(this.m_HVsUsages)
                      new SelectHypervisorWrtSize(this.m_HVsUsages, this.m_VMsResources, selectMinHypervisor, true)
//                      new BiggestHV(m_HVsResources)
//                      new LBWithDomainBreaker(this.m_HVsUsages)
              )
      );
      this.m_solver.set(SolutionPoolFactory.LAST_ONE.make());
    }
}
