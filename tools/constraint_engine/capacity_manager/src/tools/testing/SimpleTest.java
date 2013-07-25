package tools.testing;

import model.InfraConfiguration;
import solver.CapacityManagementProblem;
import solver.VMsPPNoMigrations;
import solver.VMsPackingProblem;
import tools.JsonIO;

import static tools.generators.InfrastructureGenerator.*;

public class SimpleTest {

    private CapacityManagementProblem m_problem;

    public SimpleTest(CapacityManagementProblem problem) {
        this.m_problem = problem;
    }

    public void solveProblem() {
        System.out.println("Solving the " + this.m_problem.getClass().getSimpleName() + "\n");
        long t = System.currentTimeMillis();
        this.m_problem.solve();
        t -= System.currentTimeMillis();
        t *= -1;
        try {
            this.m_problem.restoreFinalConfiguration();
        } catch (Exception e) {
            e.printStackTrace();
        }
        System.out.println("\nSolving time : " + t + " ms");
        System.out.println("Final configuration : \n");
        this.m_problem.prettyOut();
    }

    public static void main(String[] args) {

            String dir = "resources/";
            String filename = "test";
            InfraConfiguration config;
            try {
                config = JsonIO.loadConfiguration(dir+filename+".json");
                if (config != null) {
                    VMsPackingProblem problem = new VMsPPNoMigrations(config);
                    SimpleTest test = new SimpleTest(problem);

                    test.solveProblem();
                } else {
                    System.out.println("Generation of a partly assigned infrastructure failed.");
                }
            } catch (Exception e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
//        InfraConfiguration config = generateUnassignedInfraConfiguration(30, 30);
//        if (config != null) {
//            VMsPackingProblem problem = new VMsPackingProblem(config);
//            SimpleTest test = new SimpleTest(problem);
//            SearchMonitorFactory.limitTime(test.m_problem.getSolver(), 10000);
//            SearchMonitorFactory.log(test.m_problem.getSolver(), true, false);
//            test.solveProblem();
//        } else {
//            System.out.println("Generation of a partly assigned infrastructure failed.");
//        }
    }
}
