package solver.selectors.values;

import static tools.Utils.*;

import java.util.Arrays;
import java.util.Map;

import model.Hypervisor;

import solver.search.strategy.selectors.InValueIterator;
import solver.variables.IntVar;

/**
 * DOES NOT SEEM TO WORK WELL
 * Hypervisor selection heuristic : Select the hypervisor relatively containing the minimum remaining
 * resources. This is calculated by giving a score corresponding to the sum for the cpu and ram increasing
 * rankings for each hypervisor, the one having the smallest score is the selected one.
 */
public class MinRemainingRessourcesHV implements InValueIterator {

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

    public MinRemainingRessourcesHV(Map<String, IntVar[]> used_resources) {
        this.m_used_cpu_vars    = used_resources.get(CPU_KEY);
        this.m_hv_used_ram_vars = used_resources.get(RAM_KEY);
    }

    @Override
    public int selectValue(IntVar var) {
        int selected_hv = var.getLB();
        if (var.hasEnumeratedDomain()) {
            // Compute HVs scores
            int length    = this.m_hv_used_ram_vars.length;
            int[] cpu_remaining = new int[length];
            int[] ram_remaining = new int[length];
            for (int i = 0; i < length; i++) {
                cpu_remaining[i] = this.m_used_cpu_vars[i].getUB() - this.m_used_cpu_vars[i].getLB();
                ram_remaining[i] = this.m_hv_used_ram_vars[i].getUB() - this.m_hv_used_ram_vars[i].getLB();
            }
            Integer[] sorted_cpu = makeIndexArray(length);
            Integer[] sorted_ram = makeIndexArray(length);
            Arrays.sort(sorted_cpu, makeArrayIndexIncreasingComparator(cpu_remaining));
            Arrays.sort(sorted_ram, makeArrayIndexIncreasingComparator(ram_remaining));
            int[] scores = new int[length];
            for (int i = 0; i < scores.length; i++) {
                scores[ sorted_cpu[i] ] += i;
                scores[ sorted_ram[i] ] += i;
            }

            // Sort scores
            Integer[] sorted_scores_indexes = makeIndexArray(length);
            Arrays.sort(sorted_scores_indexes, makeArrayIndexIncreasingComparator(scores));

            // Return the best inside the domain
            int i = 0;
            do {
                selected_hv = sorted_scores_indexes[i];
                i++;
            } while ( (!var.contains(selected_hv)) && (i < length) );
        }
        return selected_hv;
    }
}
