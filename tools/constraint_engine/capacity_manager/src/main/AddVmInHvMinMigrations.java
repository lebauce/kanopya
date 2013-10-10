package main;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.ObjectMapper;

import model.Hypervisor;
import model.InfraConfiguration;
import model.VirtualMachine;
import solver.VMsPPMinMigrations;
import solver.VMsPackingProblem;
import solver.search.loop.monitors.SearchMonitorFactory;
import tools.JsonIO;

public class AddVmInHvMinMigrations {


    /**
     * Main class for AddVmInHvMinMigrations
     * Try to put non assigned virtual machines of given infrastructure (hypervisor set to -1 in the
     * infrastructure). If VMs cannot be naturally put on the infrastructures, only migrations of
     * the given hypervisor virtual machines are allowed. Constraint engine tries to minimize the
     * number of migrations
     *
     * @param args Json file respresenting infrastructure, hypervisor_id, (optional)
     * timelimit in milliseconds
     *
     *  Print to standard output JSON string representing for each virtual machine of the hypervisor
     *  the choosen new hypervisor
     */

    public static void main(String[] args) {
        String infra_file       = args[0];
        String hypervisor_id_s  = args[1];
        String timelimit_s     = (args.length >= 3) ? args[2] : "0";

        try {
            InfraConfiguration config = JsonIO.loadConfiguration(infra_file);
            Integer hypervisor_id     = Integer.decode(hypervisor_id_s);

            Hypervisor hv = config.getHypervisors().get(config.getHypervisorsIdsMapping().get(hypervisor_id));

            List<VirtualMachine> vms = config.getUnassignedVirtualMachines();
            VMsPackingProblem problem = new VMsPPMinMigrations(config, vms, hv);

            int timelimit = Integer.decode(timelimit_s);
            if (timelimit > 0)
                SearchMonitorFactory.limitTime(problem.getSolver(), timelimit);


            /* Uncomment this line to print details about resolution and the tree resolution */
            // SearchMonitorFactory.log(problem.getSolver(), true, false);

            /* Uncomment this line to print details about solution research every 10s */
            // SearchMonitorFactory.statEveryXXms(problem.getSolver(), 10000);

            problem.solve();

            problem.restoreFinalConfiguration();

            InfraConfiguration final_configuration = problem.getFinalConfiguration();

            if (final_configuration != null) {

                Map<Integer,Integer> result = new HashMap<Integer,Integer>();
                for (int i = 0; i < config.getVirtualMachines().size() ; i++) {
                    VirtualMachine vm_init  = config.getVirtualMachines().get(i);
                    int hv_id = vm_init.getHypervisorId();
                    if (hv_id != -1) {
                        VirtualMachine vm_final = final_configuration.getVirtualMachines().get(i);
                        if (hv_id != vm_final.getHypervisorId()) {
                            result.put(vm_final.getId(),vm_final.getHypervisorId());
                        }
                    }
                }

                ObjectMapper mapper = new ObjectMapper();
                String result_json = mapper.writeValueAsString(result);
                System.out.print(result_json);

            }
            else {
                System.err.print("Cannot assign all the virtual machines");
                System.exit(2);
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.err.print(e.toString());
            System.exit(1);
        }
    }

}
