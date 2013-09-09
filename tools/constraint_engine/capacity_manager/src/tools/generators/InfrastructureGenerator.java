package tools.generators;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import solver.VMsPackingProblem;

import model.Hypervisor;
import model.InfraConfiguration;
import model.VirtualMachine;

/**
 * Infrastucture's configuration generator (Unassigned, assigned of partly assigned).
 * Can generate virtual machines, hypervisors and full configurations.
 */
public class InfrastructureGenerator {

    // CPU bounds
    private final static int CPU_NB_CORES_LOWB         = 1;
    private final static int CPU_NB_CORES_UPB          = 12;

    // RAM bounds (The quantity of RAM follows a geometric serie's law, with a ratio of two, we so define the
    //              first term of that serie and the maximum subscript to generate correct random values)
    private final static int RAM_QTY_0                 = 128;
    private final static int RAM_QTY_MAX_SUBSCRIPT     = 5;

    // Hypervisor overcommitment factors
    private final static double OVERCOMMITMENT_CPU = 5;
    private final static double OVERCOMMITMENT_RAM = 2;

    private InfrastructureGenerator() {}

    /**
     * Try to generate an assigned infrastructure with the given parameters. Maximizing the success of the
     * method can be done by putting more hypervisors than virtual machines.
     * @param nb_hvs The number of hypervisors wanted in the result configuration.
     * @param nb_vms The number of assigned virtual machines wanted in the result configuration.
     * @return The generated configuration or the null object in case of failure.
     */
    public static InfraConfiguration generateAssignedInfraConfiguration(int nb_hvs, int nb_vms) {
        InfraConfiguration config = generateUnassignedInfraConfiguration(nb_hvs, nb_vms);
        VMsPackingProblem VMPP = new VMsPackingProblem(config);
        if (VMPP.solve()) {
            VMPP.restoreFinalConfiguration();
            return VMPP.getFinalConfiguration();
        } else {
            return null;
        }
    }

    /**
     * Try to generate a partly assigned infrastructure, with a given number of hypervisors, of assigned
     * virtual machines and of unassigned virtual machines. Maximizing the success of the method can be done
     * by putting more hypervisors than assigned virtual machines.
     * @param nb_hvs The number of wanted hypervisors.
     * @param nb_vms The number of wanted assigned virtual machines.
     * @param nb_unassigned_vms The number of wanted unassigned virtual machines.
     * @return The generated configuration or the null object in case of failure.
     */
    public static InfraConfiguration generatePartlyAssignedInfraConfiguration(int nb_hvs,
                                                                 int nb_vms,
                                                                 int nb_unassigned_vms) {
        InfraConfiguration config = generateAssignedInfraConfiguration(nb_hvs, nb_vms);
        if (config != null) {
            int size = config.getVirtualMachines().size();
            for (int i = 0; i < nb_unassigned_vms; i++) {
                config.addVirtualMachine(generateVirtualMachine(size + i));
            }
        }
        return config;
    }

    /**
     * Generate an unassigned infrastructure configuration.
     * @param nb_hvs The number of wanted hypervisors.
     * @param nb_vms The number of wanted virtual machines.
     * @return The generated infrastructure.
     */
    public static InfraConfiguration generateUnassignedInfraConfiguration(int nb_hvs, int nb_vms) {
        List<Hypervisor> hypervisors          = generateHypervisorsList(nb_hvs);
        List<VirtualMachine> virtual_machines = generateVirtualMachinesList(nb_vms);
        return new InfraConfiguration(hypervisors, virtual_machines);
    }

    /**
     * Randomly generates an hypervisors list with a given size, all hosting no virtual machines.
     * @param nb_hvs The number of hypervisors to generate.
     * @return A list containing the generated hypervisors.
     */
    public static List<Hypervisor> generateHypervisorsList(int nb_hvs) {
        List<Hypervisor> hvs = new ArrayList<Hypervisor>();
        for (int hv = 0; hv < nb_hvs; hv ++) {
            hvs.add(generateHypervisor(hv));
        }
        return hvs;
    }

    /**
     * Randomly generates a virtual machines list with a given size, all hosted by no hypervisor.
     * @param nb_vms The number of virtual machines to generate.
     * @return A list containing the generated virtual machines.
     */
    public static List<VirtualMachine> generateVirtualMachinesList(int nb_vms) {
        List<VirtualMachine> vms = new ArrayList<VirtualMachine>();
        for (int vm = 0; vm < nb_vms; vm ++) {
            vms.add(generateVirtualMachine(vm));
        }
        return vms;
    }

    /**
     * @param id The wanted id for the hypervisor.
     * @return A randomly generated hypervisor.
     */
    public static Hypervisor generateHypervisor(int id) {
        Hypervisor hv = new Hypervisor(
                id,
                generateResources(Hypervisor.CPU_NB_KEY, Hypervisor.RAM_QTY_KEY),
                new HashMap<Integer, Boolean>()
        );
        int hv_cpu = hv.getResources().get(Hypervisor.CPU_NB_KEY);
        int hv_ram = hv.getResources().get(Hypervisor.RAM_QTY_KEY);
        hv.getResources().put(Hypervisor.CPU_NB_KEY, (int) (hv_cpu * OVERCOMMITMENT_CPU));
        hv.getResources().put(Hypervisor.RAM_QTY_KEY, (int) (hv_ram * OVERCOMMITMENT_RAM));

        return hv;
    }

    /**
     * @param id The wanted id for the virtual machine.
     * @return A randomly generated virtual machine, not hosted by an hypervisor. 
     */
    public static VirtualMachine generateVirtualMachine(int id) {
        return new VirtualMachine(
                id,
                generateResources(VirtualMachine.CPU_NB_KEY, VirtualMachine.RAM_QTY_KEY),
                VirtualMachine.NO_HOST_HV_ID
        );
    }

    /**
     * @param cpu_key The key for the number of cpu cores.
     * @param ram_key The key for the quantity of ram.
     * @return A randomly generated resources map with the given keys.
     */
    private static Map<String, Integer> generateResources(String cpu_key, String ram_key) {
        int nb_cores  = (int) ( Math.random() * (CPU_NB_CORES_UPB - CPU_NB_CORES_LOWB) + CPU_NB_CORES_LOWB );
        int ram_slots = (int) ( Math.random() * 2 + 1 );
        int ram_qty   = 0;
        for (int s = 0; s < ram_slots; s++) {
            int subscript = (int) ( Math.random() * RAM_QTY_MAX_SUBSCRIPT + 1 );
            ram_qty += RAM_QTY_0 * Math.pow(2, subscript);
        }
        Map<String, Integer> resources = new HashMap<String, Integer>();
        resources.put(cpu_key, nb_cores);
        resources.put(ram_key, ram_qty);
        return resources;
    }
}