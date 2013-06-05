package main;

import java.io.File;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import model.Constraints;
import model.Host;
import model.JsonLoader;

import com.fasterxml.jackson.databind.ObjectMapper;

public class getHost {

    /**
     * Main method to call externally.
     * @param args {infrastructure json dir, constraints json dir, result dir}
     * @throws Exception
     */
    public static void main(String[] args) throws Exception {
        if (args.length != 3) {
            throw new Exception(
                    "Incorrect main arguments, must be : {infra json dir, constraints dir, result dir}"
            );
        } else {
            String infra_dir       = args[0];
            String constraints_dir = args[1];
            String result_dir      = args[2];

            Host[] hosts            = JsonLoader.loadInfrastructure(infra_dir);
            Constraints constraints = JsonLoader.loadConstraints(constraints_dir);

            HostsDeployment deployment = new HostsDeployment(hosts, constraints);

            List<String> contradictions = deployment.checkContradictions();

            Map<String, Object> resultMap = new HashMap<String, Object>();
            int selected_host = -1;

            if (contradictions.isEmpty()) {
                deployment.execute();
                selected_host = deployment.getSelectedHost();
            } else {
                resultMap.put("contradictions", contradictions);
            }

            resultMap.put("selectedHostIndex", selected_host);
            ObjectMapper mapper = new ObjectMapper();
            try {
              File f = new File(result_dir);
              if(!f.exists()){
                  f.createNewFile();
              }
                mapper.writeValue(f, resultMap);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
