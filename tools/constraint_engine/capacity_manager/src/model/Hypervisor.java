package model;

import java.util.HashMap;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;

/**
 * Hypervisor's data structure.
 */
public class Hypervisor {

    public static String CPU_NB_KEY  = "cpu";
    public static String RAM_QTY_KEY = "ram";

    public static int DEFAULT_ID = -1;

    /**
     * The unique identifier of the hypervisor.
     */
    private int m_id;

    /**
     * The resources of the hypervisor (resource_name => value).
     */
    private Map<String, Integer> m_resources;

    /**
     * The hosted virtual machines in the hypervisor (vm_id => true if hosted, null if not).
     */
    private Map<Integer, Boolean> m_hosted_vms_ids;

    public Hypervisor(int id, Map<String, Integer> resources, Map<Integer, Boolean> hosted_vms_ids) {
        this.m_id             = id;
        this.m_resources      = resources;
        this.m_hosted_vms_ids = hosted_vms_ids;
    }

    /**
     * Copy constructor.
     * @param hypervisor The hypervisor to copy.
     */
    public Hypervisor(Hypervisor hypervisor) {
        this.m_id             = hypervisor.getId();
        this.m_resources      = new HashMap<String, Integer>();
        this.m_hosted_vms_ids = new HashMap<Integer, Boolean>();
        for (String key : hypervisor.getResources().keySet()) {
            this.m_resources.put(key, hypervisor.getResources().get(key));
        }
        for (Integer key : hypervisor.getHostedVirtualMachinesIds().keySet()) {
            this.m_hosted_vms_ids.put(key, hypervisor.getHostedVirtualMachinesIds().get(key));
        }
    }

    public Hypervisor() {
        this(DEFAULT_ID, new HashMap<String, Integer>(), new HashMap<Integer, Boolean>());
    }

    @JsonIgnore
    public int getId() {
        return this.m_id;
    }

    @JsonIgnore
    public void setId(int id) {
        this.m_id = id;
    }

    public Map<String, Integer> getResources() {
        return m_resources;
    }

    public void setResources(Map<String, Integer> resources) {
        this.m_resources = resources;
    }

    @JsonProperty("vm_ids")
    public Map<Integer, Boolean> getHostedVirtualMachinesIds() {
        return this.m_hosted_vms_ids;
    }

    @JsonProperty("vm_ids")
    public void setHostedVirtualMachinesIds(Map<Integer, Boolean> hosted_vms_ids) {
        this.m_hosted_vms_ids = hosted_vms_ids;
    }

    public String toString() {
        ObjectMapper mapper  = new ObjectMapper();
        ObjectWriter writter = mapper.writer().withDefaultPrettyPrinter();
        String toReturn = "Hypervisor " + this.getId() + " :\n";
        try {
            String json = writter.writeValueAsString(this);
            toReturn += json.replaceAll("(?m)^", "\t");
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }
        return toReturn;
    }
}