package main;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import model.Constraints;
import model.Host;
import solver.ResolutionPolicy;
import solver.Solver;
import solver.constraints.IntConstraintFactory;
import solver.constraints.extension.LargeCSP;
import solver.constraints.propagators.extension.nary.IterTuplesTable;
import solver.search.loop.monitors.SearchMonitorFactory;
import solver.search.solution.SolutionPoolFactory;
import solver.variables.IntVar;
import solver.variables.VariableFactory;
import utils.AbstractProblem;
import utils.NetworkUtils;

/**
 * Constraint based Host(s) Deployment solver.
 * @author Dimitri Justeau
 */
public class HostsDeployment extends AbstractProblem {

    ////////////////////////////
    /* Physical infrastucture */
    ////////////////////////////

    // Physical infrastructure instance's structure (all the simple characteristics that can be stored in a
    // tuple of integers).
    private final static int INDEX_HOST         = 0;
    private final static int INDEX_CPU_NB_CORES = 1;
    private final static int INDEX_RAM_QTY      = 2;
    private final static int INDEX_NETWORK_COST = 3;
    private final static int INDEX_TAGS_COST    = 4;

    private final static int HOST_NB_PARAMS     = 5;

    // Physical infrastructure instance
    private Host[] infrastructure;

    // Hosts tuples
    private List<int[]> host_tuples;
    // Network cost matrixes
    private List<int[][]> network_matrices;

    List<Integer> network_candidates;
    List<Integer> tags_candidates;
    List<Integer> candidates;

    //////////////////////
    /* User constraints */
    //////////////////////

    // User constraints instance
    private Constraints constraints;

    ////////////////////////////
    /* Lower and Upper Bounds */
    ////////////////////////////

    // CPU
    private int cpu_nb_cores_lowB;
    private int cpu_nb_cores_upB;
    // RAM
    private int ram_qty_lowB;
    private int ram_qty_upB;
    // Network Cost
    private int network_cost_lowB;
    private int network_cost_upB;
    // Tags Cost
    private int tags_cost_lowB;
    private int tags_cost_upB;

    ////////////
    /* Coeffs */
    ////////////

    // Factor for arbitrary pre-ajusting the variables scale
    private final static double RAM_FACTOR     = 1d/100;
    private final static double CPU_FACTOR     = 10d;
    private final static double NETWORK_FACTOR = 10d;
    private final static double TAGS_FACTOR    = 10d;

    // Scale factor in wich all the costs criterions will be adjusted in the total cost variable
    private final static int SCALE_FACTOR      = 100;

    // Weights of each criterions in the total cost variable
    private final static int CPU_WEIGHT        = 1;
    private final static int RAM_WEIGHT        = 1;
    private final static int NETWORK_WEIGHT    = 1;
    private final static int TAGS_WEIGHT       = 1;

    // Weights for the network costs
    private final static int NET_BOND_WEIGHT   = 1;
    private final static int NET_IP_WEIGHT     = 1;

    // Computed coeffs ensuring that each criterion cost is between 0 and SCALE_FACTOR
    private int cpu_coeff;
    private int ram_coeff;
    private int network_coeff;
    private int tags_coeff;

    ///////////////
    /* Variables */
    ///////////////

    private IntVar index_host;
    private IntVar cpu_nb_cores;
    private IntVar ram_qty;
    private IntVar network_cost;
    private IntVar tags_cost;

    private IntVar total_cost;

    public HostsDeployment(Host[] infrastructure, Constraints constraints) {
        this.infrastructure = infrastructure;
        this.constraints    = constraints;
        init();
    }

    /**
     * Init lower and upper bounds, store tuples, construct network cost matrices, compute cost coeffs.
     */
    private void init() {
        // Construct matrices
        network_matrices = NetworkUtils.constructNetworkMatrices(infrastructure, constraints);

        // Init bounds and tuples //
        cpu_nb_cores_lowB = -1;
        cpu_nb_cores_upB  = -1;
        ram_qty_lowB      = -1;
        ram_qty_upB       = -1;
        network_cost_lowB = -1;
        network_cost_upB  = -1;
        tags_cost_lowB    = -1;
        tags_cost_upB     = -1;
        host_tuples       = new ArrayList<int[]>();

        for (int h = 0; h < infrastructure.length; h++) {
            Host host = infrastructure[h];

            // Tuple
            int[] tuple = new int[HOST_NB_PARAMS];
            tuple[INDEX_HOST]         = h;
            tuple[INDEX_CPU_NB_CORES] = (int) ( host.getCpu().getNbCores() * CPU_FACTOR);
            tuple[INDEX_RAM_QTY]      = (int) ( host.getRam().getQty() * RAM_FACTOR );
            tuple[INDEX_NETWORK_COST] = (int) ( NetworkUtils.computeNetworkCost(
                                                    host,
                                                    NET_BOND_WEIGHT,
                                                    NET_IP_WEIGHT) * NETWORK_FACTOR );
            tuple[INDEX_TAGS_COST]    = (int) ( host.getTags().length * TAGS_FACTOR );

            host_tuples.add(tuple);

            // Lower and upper bounds
            if ( cpu_nb_cores_lowB == -1 || tuple[INDEX_CPU_NB_CORES] < cpu_nb_cores_lowB ) {
                cpu_nb_cores_lowB = tuple[INDEX_CPU_NB_CORES];
            }
            if ( cpu_nb_cores_upB == -1 || tuple[INDEX_CPU_NB_CORES] > cpu_nb_cores_upB ) {
                cpu_nb_cores_upB = tuple[INDEX_CPU_NB_CORES];
            }
            if ( ram_qty_lowB == -1 || tuple[INDEX_RAM_QTY] < ram_qty_lowB ) {
                ram_qty_lowB = tuple[INDEX_RAM_QTY];
            }
            if ( ram_qty_upB == -1 || tuple[INDEX_RAM_QTY] > ram_qty_upB ) {
                ram_qty_upB = tuple[INDEX_RAM_QTY];
            }
            if ( network_cost_lowB == -1 || tuple[INDEX_NETWORK_COST] < network_cost_lowB ) {
                network_cost_lowB = tuple[INDEX_NETWORK_COST];
            }
            if ( network_cost_upB == -1 || tuple[INDEX_NETWORK_COST] > network_cost_upB ) {
                network_cost_upB = tuple[INDEX_NETWORK_COST];
            }
            if ( tags_cost_lowB == -1 || tuple[INDEX_TAGS_COST] < tags_cost_lowB ) {
                tags_cost_lowB = tuple[INDEX_TAGS_COST];
            }
            if ( tags_cost_upB == -1 || tuple[INDEX_TAGS_COST] > tags_cost_upB ) {
                tags_cost_upB = tuple[INDEX_TAGS_COST];
            }
        }

        // Compute cost coeffs, for each criterion, coeff is : weight * SCALE_FACTOR / (upB - lowB).
        // If lowB = upB, we just assign 0 since all the solutions will have the same cost for that criterion.
        cpu_coeff     = ( cpu_nb_cores_lowB == cpu_nb_cores_upB ) ?
                0 : CPU_WEIGHT * SCALE_FACTOR / (cpu_nb_cores_upB - cpu_nb_cores_lowB);

        ram_coeff     = ( ram_qty_lowB == ram_qty_upB ) ?
                0 : RAM_WEIGHT * SCALE_FACTOR / (ram_qty_upB - ram_qty_lowB);

        network_coeff = ( network_cost_lowB == network_cost_upB ) ?
                0 : NETWORK_WEIGHT * SCALE_FACTOR / (network_cost_upB - network_cost_lowB);

        tags_coeff    = ( tags_cost_lowB == tags_cost_upB ) ?
                0 : TAGS_WEIGHT * SCALE_FACTOR / (tags_cost_upB - tags_cost_lowB);

        // Pre filtering
        candidates = new ArrayList<Integer>();
        /* Network */
        network_candidates = NetworkUtils.matchingNetworks(network_matrices);
        /* Tags */
        tags_candidates = new ArrayList<Integer>();
        List<Integer> tags_min = Arrays.asList(constraints.getTagsMin());
        for (int h = 0; h < infrastructure.length; h++) {
            Host host = infrastructure[h];
            List<Integer> tags = Arrays.asList(host.getTags());
            if (tags.containsAll(tags_min)) {
                tags_candidates.add(h);
                if (network_candidates.contains(h)) {
                    candidates.add(h);
                }
            }
        }
    }

    /**
     * Check simple contradictions on the current instance and return their descriptions.
     * @return A list of Strings containing the descriptions of found contradictions.
     */
    public List<String> checkContradictions() {
        List<String> contradictions = new ArrayList<String>();
        // Check if the infrastructure is empty
        if (host_tuples.isEmpty()) {
            contradictions.add("The list of hosts is empty");
            return contradictions;
        }
        // Check CPU contradiction
        if (cpu_nb_cores_upB < (int) (constraints.getCpu().getNbCoresMin() * CPU_FACTOR)) {
            contradictions.add("None of the free hosts can match the minimum core number constraint");
        }
        // Check RAM contradiction
        if (ram_qty_upB < (int) (constraints.getRam().getQtyMin() * RAM_FACTOR)) {
            contradictions.add("None of the free hosts can match the minimum ram quantity constraint");
        }
        // Check Network contradiction
        if (network_candidates.isEmpty()) {
            contradictions.add("None of the free hosts can match the network configuration constraint");
        }
        // Check Tags contradiction
        if (tags_candidates.isEmpty()) {
            contradictions.add("None of the free hosts can match the minimal tags set constraint");
        }
        return contradictions;
    }

    @Override
    public void createSolver() {
        solver = new Solver("Host(s) Deployment");
    }

    @Override
    public void buildModel() {
        // Build variables
        index_host = VariableFactory.bounded(
                "index_host",
                0,
                infrastructure.length,
                solver
        );
        cpu_nb_cores = VariableFactory.bounded(
                "cpu_nb_cores",
                cpu_nb_cores_lowB,
                cpu_nb_cores_upB,
                solver
        );
        ram_qty = VariableFactory.bounded(
                "ram_qty",
                ram_qty_lowB,
                ram_qty_upB,
                solver
        );
        network_cost = VariableFactory.bounded(
                "network_cost",
                network_cost_lowB,
                network_cost_upB,
                solver
        );
        tags_cost = VariableFactory.bounded(
                "tags_cost",
                tags_cost_lowB,
                tags_cost_upB,
                solver
        );
        total_cost = VariableFactory.bounded(
                "total_cost",
                0,
                SCALE_FACTOR * (cpu_coeff + ram_coeff + network_coeff + tags_coeff),
                solver
        );

        // Post constraints

        /* CPU */
        int scaled_min_cpu = (int) ( constraints.getCpu().getNbCoresMin() * CPU_FACTOR );
        solver.post(IntConstraintFactory.arithm(cpu_nb_cores, ">=", scaled_min_cpu));

        /* RAM */
        int scaled_min_ram = (int) ( constraints.getRam().getQtyMin() * RAM_FACTOR );
        solver.post(IntConstraintFactory.arithm(ram_qty, ">=", scaled_min_ram));

        /* Feasible tuples */
        List<int[]> feasible_tuples = new ArrayList<int[]>();
        for (Integer candidate : candidates) {
            feasible_tuples.add(host_tuples.get(candidate));
        }
        IntVar[] vars = {
                index_host,
                cpu_nb_cores,
                ram_qty,
                network_cost,
                tags_cost
        };
        int[] offsets = {
                index_host.getLB(),
                cpu_nb_cores.getLB(),
                ram_qty.getLB(),
                network_cost.getLB(),
                tags_cost.getLB()
        };
        int[] dom_sizes = {
                index_host.getDomainSize(),
                cpu_nb_cores.getDomainSize(),
                ram_qty.getDomainSize(),
                network_cost.getDomainSize(),
                tags_cost.getDomainSize()
        };
        IterTuplesTable relation = new IterTuplesTable(feasible_tuples, offsets, dom_sizes);
        solver.post(IntConstraintFactory.table(vars, relation, LargeCSP.Type.AC32.name()));

        /* Total cost variable */
        IntVar[] offset_vars = {
                VariableFactory.offset(cpu_nb_cores, -1 * cpu_nb_cores_lowB),
                VariableFactory.offset(ram_qty, -1 * ram_qty_lowB),
                VariableFactory.offset(network_cost, -1 * network_cost_lowB),
                VariableFactory.offset(tags_cost, -1 * tags_cost_lowB)
        };
        solver.post(
            IntConstraintFactory.scalar(
                offset_vars,
                new int[] {cpu_coeff, ram_coeff, network_coeff, tags_coeff},
                total_cost
            )
        );
    }

    @Override
    public void configureSearch() {
        solver.set(SolutionPoolFactory.LAST_ONE.make());
    }

    @Override
    public void solve() {
        solver.findOptimalSolution(ResolutionPolicy.MINIMIZE, total_cost);
    }

    /**
     * @return The index of the selected host (-1 if no host had been found).
     */
    public int getSelectedHost() {
        if (!solver.getSearchLoop().getSolutionpool().isEmpty()) {
            solver.getSearchLoop().getSolutionpool().getBest().restore();
            return index_host.getValue();
        } else {
            return -1;
        }
    }

    @Override
    public void prettyOut() {
        if (!solver.getSearchLoop().getSolutionpool().isEmpty()) {
            solver.getSearchLoop().getSolutionpool().getBest().restore();
            System.out.println("Selected host : " + index_host.getValue());
            System.out.println("\t" + infrastructure[index_host.getValue()]);
        }
    }
}