package main;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import utils.InstanceGenerator;

import com.fasterxml.jackson.databind.ObjectMapper;

import model.Constraints;
import model.Host;
import model.JsonLoader;

public class Main {

    private static long test(int infra_size) {
        long t = System.currentTimeMillis();
        Host[] hosts = InstanceGenerator.generateInfrastructure(infra_size);
        Constraints c = InstanceGenerator.generateConstraints();
        HostsDeployment hd = new HostsDeployment(hosts, c);
        hd.execute();
        return System.currentTimeMillis() - t;
    }

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
            deployment.execute();
            int selected_host = deployment.getSelectedHost();

            Map<String, Object> resultMap = new HashMap<String, Object>();

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
