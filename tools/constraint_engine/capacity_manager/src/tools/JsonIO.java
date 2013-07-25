package tools;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;

import model.Hypervisor;
import model.InfraConfiguration;
import model.VirtualMachine;

/**
 * Utilitary class to convert Json to model / model to Json.
 */
public class JsonIO {

    public static String HYPERVISORS_KEY      = "hvs";
    public static String VIRTUAL_MACHINES_KEY = "vms";
    public static String FILE_SUFFIX          = ".json";

    private JsonIO() {}

    /**
     * Convert an InfraConfiguration object to a JSON structure and write it into a file. Proceed by writing
     * one Json file containing the virtual machines in a hash and another the hypervisors in a hash.
     * Those two hashes are stored in a hash with the keys HYPERVISORS_KEY and VIRTUAL_MACHINES_KEY.
     * @param configuration The configuration to convert and write.
     * @param dest_basename The destination files basename (will be appended with ".json").
     */
    public static void writeConfiguration(InfraConfiguration configuration, String dest_basename) {
        ObjectMapper mapper = new ObjectMapper();
        try {
            File file = new File(dest_basename + FILE_SUFFIX);
            if(!file.exists()){
                file.createNewFile();
            }
            ObjectWriter writter = mapper.writer().withDefaultPrettyPrinter();
            Map<Integer, Hypervisor> hvs = new HashMap<Integer, Hypervisor>();
            Map<Integer, VirtualMachine> vms = new HashMap<Integer, VirtualMachine>();

            for (Hypervisor hv : configuration.getHypervisors()) {
                hvs.put(hv.getId(), hv);
            }
            for (VirtualMachine vm : configuration.getVirtualMachines()) {
                vms.put(vm.getId(), vm);
            }
            Map<String, Object> infra_hash = new HashMap<String, Object>();
            infra_hash.put(HYPERVISORS_KEY, hvs);
            infra_hash.put(VIRTUAL_MACHINES_KEY, vms);

            writter.writeValue(file, infra_hash);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * Loads an InfraConfiguration from a Json file. The structure of the json file is the same as the one
     * written in the writeConfiguration method.
     * @param hvs_filename The hypervisors list file name.
     * @param vms_filename The virtual machines list file name.
     * @return The loaded infrastucture configuration.
     * @throws Exception if there is an IO problem.
     */
    public static InfraConfiguration loadConfiguration(String filename) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Map<Integer, Object>> infra = mapper.readValue(
                new File(filename),
                new TypeReference<Map<String, Object>>() {}
        );

        String hvs_json = mapper.writeValueAsString(infra.get(HYPERVISORS_KEY));
        String vms_json = mapper.writeValueAsString(infra.get(VIRTUAL_MACHINES_KEY));

        Map<Integer, Hypervisor> hvs = mapper.readValue(
                hvs_json,
                new TypeReference<Map<Integer, Hypervisor>>() {}
        );

        Map<Integer, VirtualMachine> vms = mapper.readValue(
                vms_json,
                new TypeReference<Map<Integer, VirtualMachine>>() {}
        );

        return new InfraConfiguration(
                new ArrayList<Hypervisor>( hvs.values() ),
                new ArrayList<VirtualMachine> ( vms.values() )
        );
    }
}
