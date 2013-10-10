package solver.selectors.values;

import static tools.Utils.*;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import model.Hypervisor;

import solver.CapacityManagementProblem;
import solver.Cause;
import solver.exception.ContradictionException;
import solver.search.strategy.selectors.InValueIterator;
import solver.variables.IntVar;

/**
 * DOES NOT SEEM TO WORK WELL
 * Hypervisor selection heuristic : Select the hypervisor relatively containing the minimum remaining
 * resources. This is calculated by giving a score corresponding to the sum for the cpu and ram increasing
 * rankings for each hypervisor, the one having the smallest score is the selected one.
 */
public class SelectHypervisorWrtSize implements InValueIterator {

    private static String CPU_KEY = Hypervisor.CPU_NB_KEY;
    private static String RAM_KEY = Hypervisor.RAM_QTY_KEY;

    /**
     * The hypervisors remaining cpu resources variables.
     */
    IntVar[] m_used_cpu_vars;

    /**
     * The hypervisors remaining ram resources variables.
     */
    IntVar[] m_hv_used_ram_vars;

    Map<String, int[]> m_VMsResources;
    private boolean m_selectMinHypervisor;
    private boolean m_domainBreaker;

    /**
     *
     * @param used_resources Resources domain used by the hypervisors of the infrastructure
     * @param m_VMsResources Resources domain used by the virtual machines of the infrastructure
     * @param selectMinHypervisor if true the heuristic will choose the hypervisor with minimal
     *        remaining size, if false the hypervisor with maximal remaining size
     * @param domainBreaker Enable domaing breaking
     */
    public SelectHypervisorWrtSize(Map<String, IntVar[]> used_resources, Map<String, int[]> m_VMsResources, boolean selectMinHypervisor, boolean domainBreaker) {

        this.m_used_cpu_vars       = used_resources.get(CPU_KEY);
        this.m_hv_used_ram_vars    = used_resources.get(RAM_KEY);
        this.m_VMsResources        = m_VMsResources;
        this.m_selectMinHypervisor = selectMinHypervisor;
        this.m_domainBreaker       = domainBreaker;
    }

    /**
     * Hypervisor selection heuristic. Select either biggest or smallest hypervisor of the current
     * domain. Hypervisor are ranked by cpu and ram and a global ranking is done by summing their
     * two ranks
     */
    @Override
    public int selectValue(IntVar var) {

        int selected_hv = var.getLB();
        if (var.hasEnumeratedDomain()) {

            int[][] remaining_resources = computeRemainingResources(var);

            if (this.m_domainBreaker) {
                ArrayList<Integer> incompatible_hv_ids = this.computeIncompatibleHypervisors(var, remaining_resources);

                if (! incompatible_hv_ids.isEmpty()) {
                    /* Remove incompatible HV */
                    for (Integer hv_id : incompatible_hv_ids) {
                        try {
                            if (var.getDomainSize() == 1)
                                break; /* Prevent to remove all hypervisors */
                            var.removeValue(hv_id, Cause.Null);
                        } catch (ContradictionException e) {
                            e.printStackTrace();
                        }
                    }
                    /* TODO avoid recomputing all the resources, only remove deleted ones */
                    remaining_resources = computeRemainingResources(var);
                }
            }

            int[] domain = this.getDomain(var);
            int length = domain.length;

            if (length == 1) {
                selected_hv = domain[0];
            }
            else {
                    /* Compute Hypervisor scores*/
                Integer[] sorted_cpu = makeIndexArray(length);
                Integer[] sorted_ram = makeIndexArray(length);
                Arrays.sort(sorted_ram, makeArrayIndexIncreasingComparator(remaining_resources[0]));
                Arrays.sort(sorted_cpu, makeArrayIndexIncreasingComparator(remaining_resources[1]));

                Integer[] score_ram = this.manageDraw(sorted_ram, remaining_resources[0]);
                Integer[] score_cpu = this.manageDraw(sorted_cpu, remaining_resources[1]);

                int[] scores  = new int[length];
                Arrays.fill(scores, 0);

                for (int i = 0; i < length; i++) {
                    scores[ i ] += score_cpu[i];
                    scores[ i ] += score_ram[i];
                }

                // Sort scores
                Integer[] sorted_scores_indexes = makeIndexArray(length);
                Arrays.sort(sorted_scores_indexes, makeArrayIndexIncreasingComparator(scores));


                int selected_index = this.m_selectMinHypervisor ? 0 : sorted_scores_indexes.length-1;
                selected_hv = domain[sorted_scores_indexes[selected_index]];
            }
        }
//        if (this.m_domainBreaker)
//            removeSameHV(var, selected_hv);

        return selected_hv;
    }

    /**
     * Compute current remaining ressources of each hypervisors
     * @param var Current selected virtual machine hypervisors domain
     * @return Two lines matrices. Line 0 corresponding to remaining ram, line 1 corresponding to
     * remaining cpu
     */
    private int[][] computeRemainingResources(IntVar var) {
        /* Compute remaining resources of each hypervisor */
        int[] domain = this.getDomain(var);
        int length = domain.length;
        int[][] remaining_resources = new int[2][length];

        for (int j = 0; j < length; j++) {
            int i = domain[j];
            remaining_resources[0][j] = this.m_hv_used_ram_vars[i].getUB() - this.m_hv_used_ram_vars[i].getLB();
            remaining_resources[1][j] = this.m_used_cpu_vars[i].getUB() - this.m_used_cpu_vars[i].getLB();
        }
        return remaining_resources;
    }

    /**
     * Compute the list of hypervisors of the virtual machine domains that can accept the vm
     * according to their resources
     * @param var Current selected virtual machine hypervisors domain
     * @param remaining_resources hypervisors resources. Line 0 corresponds to ram, line 1 to cpu
     * @return
     */
    private ArrayList<Integer> computeIncompatibleHypervisors(IntVar var, int[][] remaining_resources) {

        String[] split = var.getName().split(CapacityManagementProblem.VM_ASSIGN_PREFIX+"_",0);
        int vm_id = Integer.decode(split[1]);
        int vm_ram = this.m_VMsResources.get(RAM_KEY)[vm_id];
        int vm_cpu = this.m_VMsResources.get(CPU_KEY)[vm_id];

        int [] domain = this.getDomain(var);
        ArrayList<Integer> incompatibleHV = new ArrayList<Integer>(domain.length);

        for (int j = 0 ; j < domain.length ; j++) {
            if (remaining_resources[0][j] < vm_ram || remaining_resources[1][j] < vm_cpu) {
                incompatibleHV.add(domain[j]);
            }
        }
        return incompatibleHV;
    }

    /**
     * Compute the list of hypervisors indexes in which the vm can be placed
     * @param var Current selected virtual machine hypervisors domain
     * @return list of hypervisors indexes in which the vm can be placed
     */
    private int[] getDomain(IntVar var) {
        int [] result = new int[var.getDomainSize()];
        result[0] = var.getLB();
        for (int i = 1 ; i < result.length ; i++) {
            result[i] = var.nextValue(result[i-1]);
        }
        return result;
    }

    /**
     * Modify ranking of hypervisors by setting same rank of similar hypervisors
     * @param sorted_index ranking of hypervisors
     * @param original_tab scores of hypervisors
     * @return rank of hypervisors with same rank when hypervisors are similar
     */
    private Integer[] manageDraw(Integer[] sorted_index, int[] original_tab) {
        Integer[] result = new Integer[sorted_index.length];

        result[sorted_index [0]] = 0;

        for (int i = 1; i < sorted_index.length; i++) {
            if (original_tab[ sorted_index[i] ] == original_tab[ sorted_index[i - 1] ]) {
                result[ sorted_index[i] ] = result[ sorted_index[i-1] ];
            }
            else {
                result[ sorted_index[i] ] = i;
            }
        }
        return result;
    }


    /**
     * Domain Breaker remove from domain similar hypervisors
     * WARNING : Need to be corrected or re-thinked since it seems to bug and to skip solutions
     * during the solving
     *
     * @param var
     * @param value
     */
    private void removeSameHV(IntVar var, int value) {

        int[] domain = this.getDomain(var);

        int res_cpu_remaining = this.m_used_cpu_vars[value].getUB() - this.m_used_cpu_vars[value].getLB();
        int res_ram_remaining = this.m_hv_used_ram_vars[value].getUB() - this.m_hv_used_ram_vars[value].getLB();

        List<Integer> dom_to_delete = new ArrayList<Integer>(var.getDomainSize());

        for (int index : domain) {
            if (index != value) {
                int cpu_remaining = this.m_used_cpu_vars[index].getUB() - this.m_used_cpu_vars[index].getLB();
                int ram_remaining = this.m_hv_used_ram_vars[index].getUB() - this.m_hv_used_ram_vars[index].getLB();

                if (res_cpu_remaining == cpu_remaining && res_ram_remaining == ram_remaining) {
                    dom_to_delete.add(index);
                }
            }
        }
        for (Integer dom_to_delete_value : dom_to_delete) {
            try {
                var.removeValue(dom_to_delete_value, Cause.Null);
            } catch (ContradictionException e) {
                e.printStackTrace();
            }
        }
    }
}
