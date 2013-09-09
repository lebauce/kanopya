package solver.selectors.values;

import static tools.Utils.makeArrayIndexIncreasingComparator;
import static tools.Utils.makeIndexArray;

import java.util.Arrays;
import java.util.Map;

import model.Hypervisor;
import solver.search.strategy.selectors.InValueIterator;
import solver.variables.IntVar;

/**
 * Hypervisor selection heuristic : Select the relatively biggest hypervisor for hosting a virtual machine.
 * A decreasing ranking is initialy given to each hypervisor according to the cpu and ram criterions, the
 * selected hypervisor is the one with the lowest sum (called score) of those rankings (0 corresponds to the
 * biggest value for a given criterion).
 */
public class BiggestHV implements InValueIterator {

    private static String CPU_KEY = Hypervisor.CPU_NB_KEY;
    private static String RAM_KEY = Hypervisor.RAM_QTY_KEY;

    /**
     * The sorted indexes array of the hypervisors.
     */
    Integer[] m_sorted_scores_indexes;

    public BiggestHV(Map<String, IntVar[]> resources) {
        // Compute HVs scores
        IntVar[] cpu_vars   = resources.get(CPU_KEY);
        IntVar[] ram_vars   = resources.get(RAM_KEY);

        int length = cpu_vars.length; 

        int[] cpu_upbs = new int[length];
        int[] ram_upbs = new int[length];
        for (int i = 0; i < length; i++) {
            cpu_upbs[i] = cpu_vars[i].getUB();
            ram_upbs[i] = ram_vars[i].getUB();
        }
        Integer[] sorted_cpu = makeIndexArray(length);
        Integer[] sorted_ram = makeIndexArray(length);
        Arrays.sort(sorted_cpu, makeArrayIndexIncreasingComparator(cpu_upbs));
        Arrays.sort(sorted_ram, makeArrayIndexIncreasingComparator(ram_upbs));
        int[] scores = new int[length];
        for (int i = 0; i < scores.length; i++) {
            scores[ sorted_cpu[i] ] += i;
            scores[ sorted_ram[i] ] += i;
        }

        // Sort scores
        this.m_sorted_scores_indexes = makeIndexArray(length);
        Arrays.sort(this.m_sorted_scores_indexes, makeArrayIndexIncreasingComparator(scores));

    }

    @Override
    public int selectValue(IntVar var) {
        int selected_hv = var.getLB();
        int i = 0;
        do {
            selected_hv = this.m_sorted_scores_indexes[i];
            i++;
        } while ( (!var.contains(selected_hv)) && (i < this.m_sorted_scores_indexes.length) );
        return selected_hv;
    }
}
