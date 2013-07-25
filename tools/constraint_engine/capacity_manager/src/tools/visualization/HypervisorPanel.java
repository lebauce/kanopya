package tools.visualization;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Stroke;
import java.util.List;

import javax.swing.JFrame;
import javax.swing.JPanel;

import tools.generators.InfrastructureGenerator;

import model.Hypervisor;
import model.InfraConfiguration;
import model.VirtualMachine;

public class HypervisorPanel extends JPanel {

    // Parameters relative to the visualization

    private static int SIZE          = 100;

    private static int WIDTH_FACTOR  = 2;

    private static int HEIGHT_FACTOR = 3;

    private static float THICKNESS   = 10;

    // Parameters relative to the panel

    private static int MARGIN_HOR   = (int) (SIZE / 3);

    private static int MARGIN_VERT  = (int) (SIZE / 3);

    private static int PANEL_WIDTH  = 2 * MARGIN_HOR + WIDTH_FACTOR * SIZE;

    private static int PANEL_HEIGHT = 2 * MARGIN_VERT + HEIGHT_FACTOR * SIZE;

    Hypervisor m_hypervisor;
    InfraConfiguration m_config;

    public HypervisorPanel(Hypervisor hypervisor, InfraConfiguration config) {
        super();
        this.m_hypervisor = hypervisor;
        this.m_config     = config;
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);

        // Compute dimensions
        List<VirtualMachine> hosted_vms = m_config.getHostedVirtualMachines(m_hypervisor);
        int total_height = HEIGHT_FACTOR * SIZE;
        int[] vm_cpu_heights = new int[ hosted_vms.size() ];
        int[] vm_ram_heights = new int[ hosted_vms.size() ];
        for (int i = 0; i < hosted_vms.size(); i++) {
            int vm_cpu = hosted_vms.get(i).getResources().get(VirtualMachine.CPU_NB_KEY);
            int vm_ram = hosted_vms.get(i).getResources().get(VirtualMachine.RAM_QTY_KEY);
            int hv_cpu = m_hypervisor.getResources().get(Hypervisor.CPU_NB_KEY);
            int hv_ram = m_hypervisor.getResources().get(Hypervisor.RAM_QTY_KEY);
            vm_cpu_heights[i] = (int) (( (double) vm_cpu / hv_cpu ) * total_height);
            vm_ram_heights[i] = (int) (( (double) vm_ram / hv_ram ) * total_height);
        }

        // Colors
        List<Color> colors    = Utils.generatePastelColors(hosted_vms.size() + 1);
        int current_color_idx = 0;

        /* Compute points */

        // Hypervisor box
        int x1 = MARGIN_HOR;
        int y1 = MARGIN_VERT;

        int x2 = x1;
        int y2 = y1 + HEIGHT_FACTOR * SIZE;

        int x3 = x2 + WIDTH_FACTOR * SIZE;
        int y3 = y2;

        int x4 = x3;
        int y4 = y3 - HEIGHT_FACTOR * SIZE;

        // Virtual machine cursor
        int vm_width = (int) (WIDTH_FACTOR * SIZE * 0.5 );
        int x_cpu = x2;
        int y_cpu = y2;
        int x_ram = x2 + vm_width;
        int y_ram = y_cpu;

        /* Print results */
        Graphics2D g2d = (Graphics2D) g;
        Stroke stroke  = new BasicStroke(THICKNESS, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND);
        g2d.setStroke(stroke);

        // Print virtual machines boxes
        for (int vm = 0; vm < hosted_vms.size(); vm++) {
            g2d.setColor(colors.get(current_color_idx));

            // CPU Box
            g2d.fillRect(x_cpu, y_cpu - vm_cpu_heights[vm], vm_width , vm_cpu_heights[vm]);
            y_cpu -= vm_cpu_heights[vm];

            // RAM
            g2d.fillRect(x_ram, y_ram - vm_ram_heights[vm], vm_width, vm_ram_heights[vm]);
            y_ram -= vm_ram_heights[vm];

            current_color_idx ++;
        }

        g2d.setColor(colors.get(current_color_idx));

        // Print Hypervisor box
        g2d.drawLine(x1, y1, x2, y2);
        g2d.drawLine(x2, y2, x3, y3);
        g2d.drawLine(x3, y3, x4, y4);

        // Print RAM / CPU separation line
        int sx1 = (int) (0.5 * (x1 + x4));
        int sy1 = y1;

        int sx2 = sx1;
        int sy2 = y2;

        g2d.drawLine(sx1, sy1, sx2, sy2);

        // Print RAM / CPU labels
    }

    public static void main(String[] args) {

        InfraConfiguration infra;
        do {
            infra = InfrastructureGenerator.generateAssignedInfraConfiguration(1, 3);
        } while (infra == null);

        HypervisorPanel hv_panel = new HypervisorPanel(infra.getHypervisors().get(0), infra);

        JFrame frame = new JFrame();
        frame.setContentPane(hv_panel);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setLocation(200, 300);
        frame.setSize(PANEL_WIDTH, PANEL_HEIGHT + MARGIN_VERT);
        frame.setVisible(true);
    }
}
