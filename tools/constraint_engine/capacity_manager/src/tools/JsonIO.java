package tools;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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

        List<Hypervisor> list_hvs = new ArrayList<Hypervisor>();
        for(Integer key : hvs.keySet()) {
            Hypervisor hv = hvs.get(key);
            hv.setId(key);
            list_hvs.add(hv);
        }

        List<VirtualMachine> list_vms = new ArrayList<VirtualMachine>();
        for(Integer key : vms.keySet()) {
            VirtualMachine vm = vms.get(key);
            vm.setId(key);
            list_vms.add(vm);
        }

        return new InfraConfiguration(list_hvs, list_vms);
    }

    /**
     *
     * @param resource_json JSON String representing vm resources in hash map e.g. { "ram" : 1024, "cpu" : 2}
     * @return Corresponding Java hash map
     * @throws Exception Parsing or I/O errors
     */

    public static Map<String,Integer> loadVmResource(String resource_json) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Integer> resources = mapper.readValue(resource_json, new TypeReference<Map<String, Integer>>() {});
        return resources;
    }


    public static List<Map<String, Integer>> loadVmsResource(String resources_json) throws Exception {
            ObjectMapper mapper = new ObjectMapper();
            List<Map<String, Integer>> resources = mapper.readValue(
                                                               resources_json,
                                                               new TypeReference<List<Map<String, Integer>>>() {}
                                                           );
            return resources;
    }

    public static Map<Integer, Map <String,Integer>> loadVmResources(String vms_resources_json)  throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        Map<Integer, Map <String,Integer>> resources = mapper.readValue(vms_resources_json, new TypeReference<Map<Integer, Map <String,Integer>>>() {});
        return resources;
    }

    public static void main(String[] args) {
        String s = "{ \"ram\" : 1024, \"cpu\" : 2}";
        Map<String, Integer> resources;
        try {
            resources = loadVmResource(s);
            System.out.println(resources.get("ram"));
            System.out.println(resources.get("cpu"));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
