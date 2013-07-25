package model;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Represent an infrastructure configuration at a particular state.
 */
public class InfraConfiguration {

    /**
     * The hypervisors involved in the infrastructure configuration.
     */
    private List<Hypervisor> m_hypervisors;

    /**
     * The virtual machines involved in the infrastructure configuration.
     */
    private List<VirtualMachine> m_virtual_machines;

    /**
     * A mapping between the hypervisors ids to their index in the list (id => list index).
     */
    private Map<Integer, Integer> m_hvs_ids_mapping;

    /**
     * A mapping between the virtual machines ids to their index in the list (id => list index).
     */
    private Map<Integer, Integer> m_vms_ids_mapping;

    public InfraConfiguration(List<Hypervisor> hypervisors, List<VirtualMachine> virtual_machines) {
        this.m_hypervisors      = hypervisors;
        this.m_virtual_machines = virtual_machines;
        this.m_hvs_ids_mapping  = new HashMap<Integer, Integer>();
        this.m_vms_ids_mapping  = new HashMap<Integer, Integer>();
        for (int hv = 0; hv < this.m_hypervisors.size(); hv++) {
            this.m_hvs_ids_mapping.put(this.m_hypervisors.get(hv).getId(), hv);
        }
        for (int vm = 0; vm < this.m_virtual_machines.size(); vm++) {
            this.m_vms_ids_mapping.put(this.m_virtual_machines.get(vm).getId(), vm);
        }
    }

    /**
     * Copy constructor.
     * @param configuration The configuration to copy.
     */
    public InfraConfiguration(InfraConfiguration configuration) {
        this.m_hypervisors      = new ArrayList<Hypervisor>();
        this.m_virtual_machines = new ArrayList<VirtualMachine>();
        this.m_hvs_ids_mapping  = new HashMap<Integer, Integer>();
        this.m_vms_ids_mapping  = new HashMap<Integer, Integer>();
        for (int hv = 0; hv < configuration.getHypervisors().size(); hv++) {
            this.m_hypervisors.add(new Hypervisor(configuration.getHypervisors().get(hv)));
            this.m_hvs_ids_mapping.put(this.m_hypervisors.get(hv).getId(), hv);
        }
        for (int vm = 0; vm < configuration.getVirtualMachines().size(); vm++) {
            this.m_virtual_machines.add(new VirtualMachine(configuration.getVirtualMachines().get(vm)));
            this.m_vms_ids_mapping.put(this.m_virtual_machines.get(vm).getId(), vm);
        }
    }

    public List<Hypervisor> getHypervisors() {
        return this.m_hypervisors;
    }

    public List<VirtualMachine> getVirtualMachines() {
        return this.m_virtual_machines;
    }

    public Map<Integer, Integer> getHypervisorsIdsMapping() {
        return this.m_hvs_ids_mapping;
    }

    public Map<Integer, Integer> getVirtualMachinesIdsMapping() {
        return this.m_vms_ids_mapping;
    }

    /**
     * @param vm The virtual machine for which we want to know the hosting hypervisor.
     * @return The hypervisor hosting the virtual machine given in parameter.
     */
    public Hypervisor getHostingHypervisor(VirtualMachine vm) {
        Hypervisor hosting_hv = null;
        if (vm.getHypervisorId() != VirtualMachine.NO_HOST_HV_ID) {
            int hv_index = this.getHypervisorsIdsMapping().get(vm.getHypervisorId());
            hosting_hv   = this.getHypervisors().get(hv_index);
        }
        return hosting_hv;
    }

    /**
     * @param hv The hypervisor for which we want to know the hosted virtual machines.
     * @return The list of hosted virtual machines in the hypervisor given in parameters.
     */
    public List<VirtualMachine> getHostedVirtualMachines(Hypervisor hv) {
        List<VirtualMachine> hosted_vms = new ArrayList<VirtualMachine>();
        for (Integer key : hv.getHostedVirtualMachinesIds().keySet()) {
            int vm_index = this.getVirtualMachinesIdsMapping().get(key);
            hosted_vms.add(this.getVirtualMachines().get(vm_index));
        }
        return hosted_vms;
    }

    /**
     * Add an hypervisor to the infrastructure configuration.
     * WARNING : The added hypervisor must contain NO virtual machines. The method will not check it.
     * Idem for the id, it will not be checked if the id of the new hypervisor is already used in the infra.
     * @param hypervisor The hypervisor to add in the infrastructure.
     */
    public void addHypervisor(Hypervisor hypervisor) {
        this.m_hypervisors.add(hypervisor);
        this.m_hvs_ids_mapping.put(hypervisor.getId(), this.getHypervisors().size() - 1);
    }

    /**
     * Add an virtual machine to the infrastructure configuration.
     * WARNING : The added virtual machine must NOT be hosted by an hypervisor. The method will not check it.
     * Idem for the id, it will not be checked if the id of the new vm is already used in the infra.
     * @param virtual_machine The virtual machine to add in the infrastructure.
     */
    public void addVirtualMachine(VirtualMachine virtual_machine) {
        this.m_virtual_machines.add(virtual_machine);
        this.m_vms_ids_mapping.put(virtual_machine.getId(), this.getVirtualMachines().size() - 1);
    }

    public String toString() {
        String toReturn ="*** Hypervisors ***\n";

        List<VirtualMachine> hosted_vms = new ArrayList<VirtualMachine>();
        List<Hypervisor> hvs            = this.getHypervisors();

        for (int h = 0; h < hvs.size(); h++) {
            Hypervisor hv = hvs.get(h);
            int cpu_total = hv.getResources().get(Hypervisor.CPU_NB_KEY);
            int ram_total = hvs.get(h).getResources().get(Hypervisor.RAM_QTY_KEY);
            int cpu_free  = cpu_total;
            int ram_free  = ram_total;
            for (VirtualMachine vm : this.getHostedVirtualMachines(hv)) {
                hosted_vms.add(vm);
                cpu_free -= vm.getResources().get(VirtualMachine.CPU_NB_KEY);
                ram_free -= vm.getResources().get(VirtualMachine.RAM_QTY_KEY);
            }

            String middle_line = "| HV-" + h + " : { cpu = " + cpu_free + "/" + cpu_total + " ; ram = "
                                 + ram_free + "/" + ram_total + " } ||=>";

            List<VirtualMachine> vms = this.getHostedVirtualMachines(hv);
            for (int v = 0; v < vms.size(); v++) {
                VirtualMachine vm = vms.get(v);
                int index  = this.getVirtualMachinesIdsMapping().get(vm.getId());
                int vm_cpu = vm.getResources().get(VirtualMachine.CPU_NB_KEY);
                int vm_ram = vm.getResources().get(VirtualMachine.RAM_QTY_KEY);

                middle_line += " VM-" + index + " :  { cpu = " + vm_cpu + " ; ram = " + vm_ram + " } |";
            }

            String top_and_down_line = " ";
            for (int i = 0; i < middle_line.length() - 2; i++) {
                top_and_down_line += "-";
            }

            toReturn += "\n" + top_and_down_line + "\n" + middle_line + "\n" + top_and_down_line + "\n";
        }

        toReturn += "\n*** Unhosted Virtual machines ***\n";
        for (VirtualMachine vm : this.getVirtualMachines()) {
            if (!hosted_vms.contains(vm)) {
                int index  = this.getVirtualMachinesIdsMapping().get(vm.getId());
                int vm_cpu = vm.getResources().get(VirtualMachine.CPU_NB_KEY);
                int vm_ram = vm.getResources().get(VirtualMachine.RAM_QTY_KEY);
                toReturn += "\n" + "-> VM-" + index + " :  { cpu = " + vm_cpu + " ; ram = " + vm_ram + " }";
            }
        }

        return toReturn;
    }
}