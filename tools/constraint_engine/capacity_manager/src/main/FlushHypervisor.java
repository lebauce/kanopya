package main;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.ObjectMapper;

import model.Hypervisor;
import model.InfraConfiguration;
import model.VirtualMachine;
import solver.VMsPPNMEmptyOneHv;
import solver.VMsPackingProblem;
import solver.search.loop.monitors.SearchMonitorFactory;
import tools.JsonIO;

public class FlushHypervisor {

    /**
     * Main class for FlushHypervisor
     * Try to find a new hypervisor for all the virtual machines of a given hypervisor
     * @param args Json file respresenting infrastructure, hypervisor_id to flush, (optional)
     * timelimit in milliseconds
     *
     *  Print to standard output JSON string representing for each virtual machine of the hypervisor
     *  the choosen new hypervisor
     */
    public static void main(String[] args) {

        String infra_file      = args[0];
        String hypervisor_id_s = args[1];
        String timelimit_s     = (args.length >= 3) ? args[2] : "0";

        try {
            InfraConfiguration config = JsonIO.loadConfiguration(infra_file);

            /* Unassign virtual machines of flushing hypervisor and try to recontruct infra
             * minimizing number of virtual machines put on this hypervisor
             */
            int hypervisor_id         = Integer.decode(hypervisor_id_s);
            Integer internal_hv_id    = config.getHypervisorsIdsMapping().get(hypervisor_id);
            Hypervisor hypervisor     = config.getHypervisors().get(internal_hv_id);
            List<VirtualMachine> vms  = config.unassignVMs(hypervisor);

            VMsPackingProblem problem = new VMsPPNMEmptyOneHv(config,hypervisor,vms.size());

            /* Uncomment this line to print details about resolution and the tree resolution */
            // SearchMonitorFactory.log(problem.getSolver(), true, false);

            /* Uncomment this line to print details about solution research every 10s */
            // SearchMonitorFactory.statEveryXXms(problem.getSolver(), 10000);

            /* Set a resolution time limit: will return best currently find solution */
            int timelimit = Integer.decode(timelimit_s);
            if (timelimit > 0)
                SearchMonitorFactory.limitTime(problem.getSolver(), timelimit);

            problem.solve();

            problem.restoreFinalConfiguration();

            InfraConfiguration final_configuration = problem.getFinalConfiguration();

            if (final_configuration != null) {
                Map<Integer,Integer> hypervisors = new HashMap<Integer,Integer>();

                for (VirtualMachine vm : vms) {
                    Integer vm_internal_index = final_configuration.getVirtualMachinesIdsMapping().get(vm.getId());
                    hypervisors.put(vm.getId(), final_configuration.getVirtualMachines().get(vm_internal_index).getHypervisorId());
                }

                ObjectMapper mapper = new ObjectMapper();
                String hvs_json = mapper.writeValueAsString(hypervisors);
                System.out.print(hvs_json);
            }
            else {
                System.err.println("Error, cannot recreate infrastructure");
                System.exit(2);
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.err.print(e.toString());
            System.exit(1);
        }
    }

}
