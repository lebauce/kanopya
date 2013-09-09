package model;

import java.util.ArrayList;
import java.util.List;

/**
 * POJO representing a host.
 * @author Dimitri Justeau
 */
public class Host {

    /**
     * The CPU of the host.
     */
    private CPU m_cpu;

    /**
     * The Ram of the host.
     */
    private RAM m_ram;

    /**
     * The network of the host.
     */
    private Network m_network;

    /**
     * The storage of the host.
     */
    private Storage m_storage;

    /**
     * The tags of the host.
     */
    private Integer[] m_tags;

    public Host() {
        this.m_cpu     = new CPU();
        this.m_ram     = new RAM();
        this.m_network = new Network();
        this.m_storage = new Storage();
        this.m_tags    = new Integer[0];
    }

    public Host(CPU cpu, RAM ram, Network network, Storage storage, Integer[] tags) {
        super();
        this.m_cpu     = cpu;
        this.m_ram     = ram;
        this.m_network = network;
        this.m_storage = storage;
        this.m_tags    = tags;
    }

    // GETTERS

    public CPU getCpu() {
        return m_cpu;
    }

    public RAM getRam() {
        return m_ram;
    }

    public Network getNetwork() {
        return m_network;
    }

    public Storage getStorage() {
        return m_storage;
    }

    public Integer[] getTags() {
        return m_tags;
    }

    // SETTERS

    public void setCpu(CPU cpu) {
        this.m_cpu = cpu;
    }

    public void setRam(RAM ram) {
        this.m_ram = ram;
    }

    public void setNetwork(Network network) {
        this.m_network = network;
    }

    public void setStorage(Storage storage) {
        this.m_storage = storage;
    }

    public void setTags(Integer[] tags) {
        m_tags = tags;
    }

    public String toString() {
        String host = "Host :";
        host += "\n" + "\t" + this.getCpu();
        host += "\n" + "\t" + this.getRam();
        host += "\n" + "\t" + this.getNetwork();
        host += "\n" + "\t" + this.getStorage();
        host += "\n" + "\t" + "Tags :";
        for (Integer tag : this.getTags()) {
            host += "\n" + "\t\t" + tag;
        }
        return host;
    }

    /**
     * POJO representing the CPU of a host.
     * @author Dimitri Justeau
     */
    public static class CPU {

        /**
         * The number of cores in the CPU.
         */
        private int m_nb_cores;

        public CPU() {
            this.m_nb_cores = 0;
        }

        public CPU(int nb_cores) {
            super();
            this.m_nb_cores = nb_cores;
        }

        // GETTERS AND SETTERS

        public int getNbCores() {
            return m_nb_cores;
        }

        public void setNbCores(int nb_cores) {
            this.m_nb_cores = nb_cores;
        }

        public String toString() {
            String cpu = "CPU :";
            cpu += "\n" + "\t\t" + "Nb of cores : " + this.getNbCores();
            return cpu;
        }
    }

    /**
     * POJO representing the RAM of a host.
     * @author Dimitri Justeau
     */
    public static class RAM {

        /**
         * The quantity of RAM in mo.
         */
        private int m_qty;

        public RAM() {
            this.m_qty = 0;
        }

        public RAM(int qty) {
            super();
            this.m_qty = qty;
        }

        // GETTERS AND SETTERS

        public int getQty() {
            return m_qty;
        }

        public void setQty(int qty) {
            this.m_qty = qty;
        }

        public String toString() {
            String ram = "RAM :";
            ram += "\n" + "\t\t" + "Qty : " + this.getQty();
            return ram;
        }
    }

    /**
     * POJO representing the network features of a host.
     * @author Dimitri Justeau
     */
    public static class Network {

        /**
         * The ifaces of the network.
         */
        private List<Iface> m_ifaces;

        public Network() {
            this.m_ifaces = new ArrayList<Iface>();
        }

        public Network(List<Iface> ifaces) {
            super();
            this.m_ifaces = ifaces;
        }

        // GETTERS AND SETTERS

        public List<Iface> getIfaces() {
            return m_ifaces;
        }

        public void setIfaces(List<Iface> ifaces) {
            this.m_ifaces = ifaces;
        }

        public String toString() {
            String net = "Network :";
            net += "\n" + "\t\t" + "Ifaces : ";
            for (Iface iface : this.getIfaces()) {
                net += "\n" + "\t\t\t" + iface;
            }
            return net;
        }

        /**
         * POJO representing a iface.
         * @author Dimitri Justeau
         */
        public static class Iface {

            /**
             * The number of bonds (0 means that there is no bonding
             * configuration).
             */
            private int m_bonds_number;

            /**
             * The NetIPs of the iface.
             */
            private List<Integer> m_netips;

            public Iface() {
                m_bonds_number = 0;
                m_netips = new ArrayList<Integer>();
            }

            // GETTERS AND SETTERS

            public int getBondsNumber() {
                return m_bonds_number;
            }

            public List<Integer> getNetIPs() {
                return m_netips;
            }

            public void setBondsNumber(int bonds_number) {
                this.m_bonds_number = bonds_number;
            }

            public void setNetIPs(List<Integer> netips) {
                this.m_netips = netips;
            }

            public String toString() {
                String net = "Iface :";
                net += "\n" + "\t\t\t\t" + "Nb of bonds : "
                        + this.getBondsNumber();
                String netips = "[ ";
                for (int netip : this.getNetIPs()) {
                    netips += netip + " ";
                }
                net += "\n" + "\t\t\t\t" + "NetIPs : " + netips + "]";
                return net;
            }
        }
    }

    /**
     * POJO representing the storage devices of a host.
     * @author Dimitri Justeau
     */
    public static class Storage {

        /**
         * The hard disks.
         */
        private List<HardDisk> m_hard_disks;

        public Storage(List<HardDisk> hard_disks) {
            this.m_hard_disks = hard_disks;
        }

        public Storage() {
            this(new ArrayList<HardDisk>());
        }

        // GETTERS AND SETTERS

        public List<HardDisk> getHardDisks() {
            return this.m_hard_disks;
        }

        public void setHardDisks(List<HardDisk> hard_disks) {
            this.m_hard_disks = hard_disks;
        }

        /**
         * @return The total number of hard disks.
         */
        public int computeHardDisksNumber() {
            return this.getHardDisks().size();
        }

        public String toString() {
            String storage = "Storage :";
            storage += "\n" + "\t\t" + "Hard Disks : ";
            for (HardDisk hd : this.getHardDisks()) {
                storage += "\n" + "\t\t\t" + hd;
            }
            return storage;
        }

        /**
         * POJO representing a hard disk.
         * @author Dimitri Justeau
         */
        public static class HardDisk {

            /**
             * The size of the hard disk, in Go.
             */
            private int m_size;

            public HardDisk(int size) {
                this.m_size = size;
            }

            public HardDisk() {
                this(0);
            }

            // GETTERS AND SETTERS

            public int getSize() {
                return this.m_size;
            }

            public void setSize(int size) {
                this.m_size = size;
            }

            public String toString() {
                String hd = "HardDisk :";
                hd += "\n" + "\t\t\t\t" + "Size (Go) : " + this.getSize();
                return hd;
            }
        }
    }
}