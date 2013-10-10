package model;

import java.io.File;
import java.util.List;



import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Class for loading instances of Host and Constraints from JSON files.
 * @author Dimitri Justeau
 */
public class JsonLoader {

    /* Utility class */
    private JsonLoader() {}

    /**
     * Extract a Constraints object from a JSON file.
     * @param dir The direction to the json file.
     * @return The user constraints stored in a Constraints object.
     */
    public static Constraints loadConstraints(String dir) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        return mapper.readValue(new File(dir), Constraints.class);
    }

    /**
     * Extract an infrastructure (array of Hosts) from a JSON file.
     * @return The infrastructure stored in an array of Host objects.
     */
    public static Host[] loadInfrastructure(String dir) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        List<Host> lhosts   = mapper.readValue(new File(dir), new TypeReference<List<Host>>() {});
        return lhosts.toArray(new Host[lhosts.size()]);
    }
}
