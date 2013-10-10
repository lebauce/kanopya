package utils;

import java.util.ArrayList;
import java.util.List;

import model.Constraints;
import model.Host;
import model.Constraints.Network.Interface;
import model.Host.Network.Iface;
import model.Host.Storage.HardDisk;


/**
 * Generator of Host Deployment Problem instances.
 * @author Dimitri Justeau
 */
public class InstanceGenerator {

    ////////////////////////////
    /* Lower and Upper Bounds */
    ////////////////////////////

    // CPU
    private final static int CPU_NB_CORES_LOWB         = 1;
    private final static int CPU_NB_CORES_UPB          = 10;

    // RAM (The quantity of RAM follows a geometric serie's law, with a ratio of two, we so define the first
    //      term of that serie and the maximum subscript to generate correct random values)
    private final static int RAM_QTY_0                 = 128;
    private final static int RAM_QTY_MAX_SUBSCRIPT     = 5;

    // Network
    private final static int NETWORK_MAX_IFACES_NUMBER = 5;
    private final static int NETWORK_MAX_BONDS_NUMBER  = 5;
    private final static int NETWORK_MAX_NETCONFS      = 5;

    // Tags
    private final static int TAGS_MAX_NUMBER           = 5;

    // Storage
    private final static int STORAGE_MAX_HDS_NUMBER    = 3;
    private final static int STORAGE_MIN_HD_SIZE       = 20;
    private final static int STORAGE_MAX_HD_SIZE       = 1000;

    /* Private empty constructor : Utility class */
    private InstanceGenerator() {}

    /**
     * Generate a physical infrastructure with a given number of hosts.
     * @param nb_hosts The number of available hosts in the infrastructure to generate.
     * @return The physical infrastructure, as an array of Host objects.
     */
    public static Host[] generateInfrastructure(int nb_hosts) {
        Host[] physical_infrastructure = new Host[nb_hosts];
        for (int i = 0; i < nb_hosts; i++) {
            // Generate random number of cores
            int cpu_nb_cores = (int)
                    (Math.random()*(CPU_NB_CORES_UPB - CPU_NB_CORES_LOWB + 1) + CPU_NB_CORES_LOWB);

            // Generate random quantity of ram -> We first choose if there will be one or two slots used, and
            // Then generate randomly a value for each slot.
            int ram_nb_slots = (int) (Math.random()*2 + 1);
            int ram_qty  = 0;
            for (int s = 0; s < ram_nb_slots; s++) {
                int subscript = (int) (Math.random()*RAM_QTY_MAX_SUBSCRIPT + 1);
                ram_qty += RAM_QTY_0 * Math.pow(2, subscript);
            }

            // Generate network
            int nb_ifaces  = (int) (Math.random() * NETWORK_MAX_IFACES_NUMBER + 1);
            List<Iface> ifaces = new ArrayList<Iface>();
            for (int j = 0; j < nb_ifaces; j++) {
                int nb_bonds    = (int) (Math.random() * (NETWORK_MAX_BONDS_NUMBER + 1));
                int nb_netconfs = (int) (Math.random() * (NETWORK_MAX_NETCONFS + 1));
                List<Integer> netconfs  = new ArrayList<Integer>();
                for (int k = 0; k < nb_netconfs; k++) {
                    int net;
                    do {
                        net = (int) (Math.random() * (NETWORK_MAX_NETCONFS + 1));
                    } while (netconfs.contains(net));
                    netconfs.add(net);
                }
                Iface iface = new Iface();
                iface.setBondsNumber(nb_bonds);
                iface.setNetIPs(netconfs);
                ifaces.add(iface);
            }

            // Generate Storage
            int nb_hard_disks = (int) (Math.random() * (STORAGE_MAX_HDS_NUMBER + 1));
            List<HardDisk> hard_disks = new ArrayList<HardDisk>();
            for (int hd = 0; hd < nb_hard_disks; hd++) {
                int size = (int) 
                        (Math.random()*(STORAGE_MAX_HD_SIZE - STORAGE_MIN_HD_SIZE + 1) + STORAGE_MIN_HD_SIZE);
                HardDisk harddisk = new HardDisk(size);
                hard_disks.add(harddisk);
            }

            // Generate tags
            int nb_tags         = (int) (Math.random() * TAGS_MAX_NUMBER + 1);
            List<Integer> tags  = new ArrayList<Integer>();
            for (int k = 0; k < nb_tags; k++) {
                int tag;
                do {
                    tag = (int) (Math.random() * (TAGS_MAX_NUMBER + 1));
                } while (tags.contains(tag));
                tags.add(tag);
            }

            // Generate host number i
            physical_infrastructure[i] =  new Host(
                    new Host.CPU(cpu_nb_cores),
                    new Host.RAM(ram_qty),
                    new Host.Network(ifaces),
                    new Host.Storage(hard_disks),
                    tags.toArray(new Integer[tags.size()])
            );
        }
        return physical_infrastructure;
    }

    /**
     * Generate a set of user constraints for the selection of a free host in a physical infrastructure.
     * @return The user constraints stored in Constraints object.
     */
    public static Constraints generateConstraints() {
        // Generate random min and max number of cores
        int cpu_nb_cores_min =
                (int) (Math.random()*(CPU_NB_CORES_UPB - CPU_NB_CORES_LOWB + 1) + CPU_NB_CORES_LOWB);

        // Generate random min ram quantity (Same process as in the generatePhysicalInfrastructure method)
        int ram_nb_slots = (int) (Math.random()*2 + 1);
        int ram_qty_min  = 0;
        for (int s = 0; s < ram_nb_slots; s++) {
            int subscript = (int) (Math.random()*RAM_QTY_MAX_SUBSCRIPT + 1);
            ram_qty_min += RAM_QTY_0 * Math.pow(2, subscript);
        }

        // Generate interfaces constraints
        int nb_interfaces  = (int) (Math.random() * NETWORK_MAX_IFACES_NUMBER + 1);
        List<Interface> interfaces = new ArrayList<Interface>();
        for (int j = 0; j < nb_interfaces; j++) {
            int nb_bonds    = (int) (Math.random() * (NETWORK_MAX_BONDS_NUMBER + 1));
            int nb_netconfs = (int) (Math.random() * (NETWORK_MAX_NETCONFS + 1));
            List<Integer> netconfs  = new ArrayList<Integer>();
            for (int k = 0; k < nb_netconfs; k++) {
                int net;
                do {
                    net = (int) (Math.random() * (NETWORK_MAX_NETCONFS + 1));
                } while (netconfs.contains(net));
                netconfs.add(net);
            }
            Interface interf = new Interface();
            interf.setBondsNumberMin(nb_bonds);
            interf.setNetIPsMin(netconfs);
            interfaces.add(interf);
        }

        // Generate storage constraints
        int storage_hd_nb_min = (int) (Math.random() * (STORAGE_MAX_HDS_NUMBER + 1));

        // Generate tags
        int nb_tags_min        = (int) (Math.random() * TAGS_MAX_NUMBER + 1);
        List<Integer> tags_min = new ArrayList<Integer>();
        for (int k = 0; k < nb_tags_min; k++) {
            int tag;
            do {
                tag = (int) (Math.random() * (TAGS_MAX_NUMBER + 1));
            } while (tags_min.contains(tag));
            tags_min.add(tag);
        }

        return new Constraints(
                new Constraints.CPU(cpu_nb_cores_min),
                new Constraints.RAM(ram_qty_min),
                new Constraints.Network(interfaces),
                new Constraints.Storage(storage_hd_nb_min),
                tags_min.toArray(new Integer[tags_min.size()]),
                new Integer[0]
        );
    }

    public static void main(String[] args) {
        try {
            Constraints c = generateConstraints();
            Host[] hosts  = generateInfrastructure(100);
            for (int i = 0; i < hosts.length; i++) {
                System.out.println(i + " - " + hosts[i]);
            }
            System.out.println(c);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
