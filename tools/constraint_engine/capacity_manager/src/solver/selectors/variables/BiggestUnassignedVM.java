package solver.selectors.variables;

import java.util.Arrays;
import java.util.Map;

import model.VirtualMachine;

import solver.search.strategy.selectors.VariableSelector;
import solver.variables.IntVar;
import static tools.Utils.*;

/**
 * Virtual Machine selection heuristic : Select the relatively biggest virtual machine to assign. A decreasing 
 * ranking is initialy given to each virtual machine according to the cpu and ram criterions, the selected
 * virtual machine is the one with the lowest sum (called score) of those rankings (0 corresponds to the
 * biggest value for a given criterion).
 */
public class BiggestUnassignedVM implements VariableSelector<IntVar> {

    private static String CPU_KEY = VirtualMachine.CPU_NB_KEY;
    private static String RAM_KEY = VirtualMachine.RAM_QTY_KEY;

    /**
     * The virtual machine assignment variables.
     */
    IntVar[] m_VMs;

    /**
     * The scores of the virtual machines.
     */
    Integer[] m_sorted_scores_indexes;

    /**
     * The index of the biggest unassigned virtual machine.
     */
    int m_biggest_index;

    public BiggestUnassignedVM(IntVar[] VMs, Map<String, int[]> resources) {
        this.m_VMs    = VMs.clone();
        int[] cpu     = resources.get(CPU_KEY);
        int[] ram     = resources.get(RAM_KEY);
        int length    = this.m_VMs.length;
        int[] scores  = new int[length];
        for (int i = 0; i < length; i++) {
            scores[i] = 0;
        }
        // Compute scores
        Integer[] sorted_cpu = makeIndexArray(length);
        Integer[] sorted_ram = makeIndexArray(length);
        Arrays.sort(sorted_cpu, makeArrayIndexDecreasingComparator(cpu));
        Arrays.sort(sorted_ram, makeArrayIndexDecreasingComparator(ram));
        for (int i = 0; i < length; i++) {
            scores[ sorted_cpu[i] ] += i;
            scores[ sorted_ram[i] ] += i;
        }
        this.m_sorted_scores_indexes = makeIndexArray(length);
        Arrays.sort(sorted_cpu, makeArrayIndexIncreasingComparator(scores));
        this.m_biggest_index = 0;
    }

    @Override
    public void advance() {
        int i = 0;
        do {
            m_biggest_index = m_sorted_scores_indexes[i];
            i++;
        } while ( (this.m_VMs[this.m_biggest_index].getDomainSize() == 1) && (i < this.m_VMs.length) );
    }

    @Override
    public IntVar[] getScope() {
        return this.m_VMs;
    }

    @Override
    public IntVar getVariable() {
        return this.m_VMs[this.m_biggest_index];
    }

    @Override
    public boolean hasNext() {
        int idx = 0;
        for (; idx < this.m_VMs.length && this.m_VMs[idx].getDomainSize() == 1; idx++) {
        }
        return idx < this.m_VMs.length;
    }
}