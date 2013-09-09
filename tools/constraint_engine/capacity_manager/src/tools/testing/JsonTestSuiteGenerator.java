package tools.testing;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;

import model.InfraConfiguration;

import static tools.generators.InfrastructureGenerator.*;
import static tools.JsonIO.*;

/**
 * Utility class for generating test suites and store them into json files.
 */
public class JsonTestSuiteGenerator {

    public static String DESCRITPION_FILE_NAME = "description.json";
    public static String TESTSUITE_NAME_KEY    = "name";
    public static String NB_HVS_KEY            = "nbs_hvs";
    public static String NB_ASSIGNED_VMS_KEY   = "nbs_assigned_vms";
    public static String NB_UNASSIGNED_VMS_KEY = "nbs_unassigned_vms";

    private JsonTestSuiteGenerator() {}

    /**
     * Generate a test suite and store it into json files, at the specified folder. The length of nb_hvs and
     * nb_vms must be equal. Also generate a json describing the test suite. In some cases the generation of
     * a test case (with assignment generation) can fail, if so the method indicates it in the console and pop
     * it from the list and from the description file. If all of the test cases fail, nothing is generated.
     * @param nbs_hvs The numbers of hypervisors in each test case.
     * ( { nb_hvs 1, nb_hvs2, ... } )
     * @param nbs_vms The number of assigned and unassigned virtual machines in each test case 
     * ( { {nb_assigned 1, nb_unassigned 1}, ... }
     * @param dest_folder The destination folder for the whole test suite.
     * @param name A name describing the test suite.
     */
    public static void generateTestSuite(int[] nbs_hvs, int[][] nbs_vms, String dest_folder, String name) {
        if ( nbs_hvs.length == nbs_vms.length ) {
            System.out.println("Generating test suite...");

            File folder = new File(dest_folder);
            if(!folder.exists()){
                folder.mkdirs();
            }

            Map<String, Object> description = new HashMap<String, Object>();
            description.put(TESTSUITE_NAME_KEY, name);

            List<Integer> success_nbs_hvs            = new ArrayList<Integer>();
            List<Integer> success_nbs_assigned_vms   = new ArrayList<Integer>();
            List<Integer> success_nbs_unassigned_vms = new ArrayList<Integer>();

            int fails = 0;

            for (int i = 0; i < nbs_hvs.length; i++) {
                int nb_hvs            = nbs_hvs[i];
                int nb_assigned_vms   = nbs_vms[i][0];
                int nb_unassigned_vms = nbs_vms[i][1];

                InfraConfiguration infra;
                if (nb_assigned_vms == 0) {
                    infra = generateUnassignedInfraConfiguration(nb_hvs, nb_unassigned_vms);
                } else
                if (nb_unassigned_vms == 0) {
                    infra = generateAssignedInfraConfiguration(nb_hvs, nb_assigned_vms);
                } else {
                    infra = generatePartlyAssignedInfraConfiguration(
                            nb_hvs,
                            nb_assigned_vms,
                            nb_unassigned_vms
                    );
                }

                if (infra != null) {
                    writeConfiguration(infra, dest_folder + "/" + name + "_" + (i - fails));
                    success_nbs_hvs.add(nb_hvs);
                    success_nbs_assigned_vms.add(nb_assigned_vms);
                    success_nbs_unassigned_vms.add(nb_unassigned_vms);
                } else {
                    System.out.println("- Generation of test case " + i + " failed.");
                    fails ++;
                }
            }
            if (fails == nbs_hvs.length) {
                System.out.println("Test suite generation failed.");
            } else {
                description.put(NB_HVS_KEY, success_nbs_hvs);
                description.put(NB_ASSIGNED_VMS_KEY, success_nbs_assigned_vms);
                description.put(NB_UNASSIGNED_VMS_KEY, success_nbs_unassigned_vms);
                ObjectMapper mapper = new ObjectMapper();
                ObjectWriter writter = mapper.writer().withDefaultPrettyPrinter();
                try {
                    File desc_file = new File(dest_folder + "/" + DESCRITPION_FILE_NAME);
                    if (!desc_file.exists()) {
                        desc_file.createNewFile();
                    }
                    writter.writeValue(desc_file, description);
                } catch (IOException e) {
                    e.printStackTrace();
                }

                if (fails == 0) {
                    System.out.println("Test suite generation successful !");
                } else {
                    System.out.println("Test suite generation partially successful (" + fails + " test cases "
                            + "could not be generated.");
                }
            }
        } else {
            System.out.println("The test suite could not be generated because the lengths of the wanted" + 
                    " numbers of hypervisors and virtual machines are different.");
        }
    }

    public static void main(String[] args) {
        int nb_tests    = 10;
        int[] hvs_nbs    = new int[nb_tests];
        int[][] vms_nbs = new int[nb_tests][2];
        int step        = 5;
        for (int i = 0; i < nb_tests; i++) {
            hvs_nbs[i]    = 50;
            vms_nbs[i][0] = step * i;
            vms_nbs[i][1] = 1;
        }
        generateTestSuite(
                hvs_nbs,
                vms_nbs,
                "resources/selectHypervisorSingleNoMigrations/(50)hvs_(0-50)assigned_vms",
                "select_hv_single_no_migration"
        );
//        generateTestSuite(new int[] {1}, new int[][] { {4, 0} }, "resources", "test");
    }
}
