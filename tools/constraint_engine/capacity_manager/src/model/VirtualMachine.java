package model;

import java.util.HashMap;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;

/**
 * Virtual Machine's data structure.
 */
public class VirtualMachine {

    public static String CPU_NB_KEY  = "cpu";
    public static String RAM_QTY_KEY = "ram";

    public static int DEFAULT_ID    = -1;
    public static int NO_HOST_HV_ID = -1;

    /**
     * The unique identifier of the virtual machine.
     */
    private int m_id;

    /**
     * The resources of the virtual machine (resource_name => value).
     */
    private Map<String, Integer> m_resources;

    /**
     * The id of the hypervisor hosting the virtual machine (NO_HOST_HV_ID means not hosted).
     */
    private int m_hypervisor_id;

    public VirtualMachine(int id, Map<String, Integer> resources, int hypervisor_id) {
        this.m_id            = id;
        this.m_resources     = resources;
        this.m_hypervisor_id = hypervisor_id;
    }

    /**
     * Copy constructor.
     * @param virtual_machine The virtual machine to copy.
     */
    public VirtualMachine(VirtualMachine virtual_machine) {
        this.m_id            = virtual_machine.getId();
        this.m_hypervisor_id = virtual_machine.getHypervisorId();
        this.m_resources     = new HashMap<String, Integer>();
        for (String key : virtual_machine.getResources().keySet()) {
            this.m_resources.put(key, virtual_machine.getResources().get(key));
        }
    }

    public VirtualMachine() {
        this(DEFAULT_ID, new HashMap<String, Integer>(), NO_HOST_HV_ID);
    }

    public int getId() {
        return this.m_id;
    }

    public void setId(int id) {
        this.m_id = id;
    }

    public Map<String, Integer> getResources() {
        return m_resources;
    }

    public void setResources(Map<String, Integer> resources) {
        this.m_resources = resources;
    }

    @JsonProperty("hv_id")
    public int getHypervisorId() {
        return m_hypervisor_id;
    }

    @JsonProperty("hv_id")
    public void setHypervisorId(int hypervisor_id) {
        this.m_hypervisor_id = hypervisor_id;
    }

    public String toString() {
        ObjectMapper mapper  = new ObjectMapper();
        ObjectWriter writter = mapper.writer().withDefaultPrettyPrinter();
        String toReturn = "Virtual Machine " + this.getId() + " :\n";
        try {
            String json = writter.writeValueAsString(this);
            toReturn += json.replaceAll("(?m)^", "\t");
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }
        return toReturn;
    }
}