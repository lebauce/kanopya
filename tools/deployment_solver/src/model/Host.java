package model;

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

    public Host() {}

    public Host(CPU cpu, RAM ram, Network network) {
        super();
        this.m_cpu = cpu;
        this.m_ram = ram;
        this.m_network = network;
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

    public String toString() {
        String host = "Host :";
        host += "\n" + "\t" + this.getCpu();
        host += "\n" + "\t" + this.getRam();
        host += "\n" + "\t" + this.getNetwork();
        return host;
    }

    /**
     * POJO representing the CPU of a host.
     *
     * @author Dimitri Justeau
     */
    public static class CPU {

        /**
         * The number of cores in the CPU.
         */
        private int m_nb_cores;

        public CPU() {}

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
     *
     * @author Dimitri Justeau
     */
    public static class RAM {

        /**
         * The quantity of RAM in mo.
         */
        private int m_qty;

        public RAM() {}

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
     *
     * @author Dimitri Justeau
     */
    public static class Network {

        /**
         * The ifaces of the network.
         */
        private List<Iface> m_ifaces;

        public Network() {
            this.m_ifaces = null;
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
         *
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
                m_netips = null;
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
}