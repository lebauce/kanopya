package tools.testing;

import java.io.File;
import java.io.IOException;
import java.lang.reflect.Constructor;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import model.InfraConfiguration;

import static tools.testing.JsonTestSuiteGenerator.*;
import static tools.JsonIO.*;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;

import solver.CapacityManagementProblem;
import solver.VMsPPNoMigrations;

/**
 * Test suite that is instanciated from json files all stored in the same folder.
 * Can launch a test suite for a given problem type, store results, solving times and generate graphs.
 */
public class JsonTestSuite {

    private static String SOLVING_TIMES_KEY = "solving times";

    private static String SOLUTIONS_FOUND   = "solutions found";

    private static String RESULTS_FILENAME  = "results.json";

    private Class m_problem_class;

    private String m_test_suite_folder;

    private Map<String, Object> m_description;

    private List<Long> m_solving_times;

    private List<Boolean> m_solutions_found;

    public JsonTestSuite(Class problem_class, String test_suite_folder) {
        this.m_problem_class     = problem_class;
        this.m_test_suite_folder = test_suite_folder;
        ObjectMapper mapper = new ObjectMapper();
        File desc_file      = new File(test_suite_folder + "/" + DESCRITPION_FILE_NAME);
        try {
            this.m_description  = mapper.readValue(desc_file, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            e.printStackTrace();
        }
        this.m_solving_times   = new ArrayList<Long>();
        this.m_solutions_found = new ArrayList<Boolean>();
    }

    public void launchTestSuite() {
        int nb_test_cases   = ( (List<Integer>) this.m_description.get(NB_HVS_KEY) ).size();
        String basename = this.m_test_suite_folder + "/" + this.m_description.get(TESTSUITE_NAME_KEY);

        for (int i = 0; i < nb_test_cases; i++) {
            try {
                InfraConfiguration config = loadConfiguration(
                        basename + "_" + i + FILE_SUFFIX
                );
                Constructor<CapacityManagementProblem> constructor = 
                        this.m_problem_class.getConstructor(InfraConfiguration.class);

                long t = System.currentTimeMillis();
                CapacityManagementProblem problem = constructor.newInstance(config);
                problem.solve();
                problem.restoreFinalConfiguration();
                t -= System.currentTimeMillis();
                t *= -1;

                boolean solution_found = problem.getFinalConfiguration() != null;
                this.m_solving_times.add(t);
                this.m_solutions_found.add(solution_found);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        Map<String, Object> results = new HashMap<String, Object>();
        results.put(SOLVING_TIMES_KEY, m_solving_times);
        results.put(SOLUTIONS_FOUND, m_solutions_found);
        ObjectMapper mapper         = new ObjectMapper();
        ObjectWriter writter        = mapper.writer().withDefaultPrettyPrinter();
        try {
            File results_file = new File(this.m_test_suite_folder + "/" + RESULTS_FILENAME);
            if (!results_file.exists()) {
                results_file.createNewFile();
            }
            writter.writeValue(results_file, results);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        JsonTestSuite test = new JsonTestSuite(
                VMsPPNoMigrations.class,
                "resources/selectHypervisorSingleNoMigrations/(50)hvs_(0-50)assigned_vms"
        );
        test.launchTestSuite();
    }
}
