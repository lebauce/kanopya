package utils;

import java.util.ArrayList;
import java.util.List;

import model.Constraints;
import model.Host;
import model.Host.Network.Iface;

/**
 * Utils methods for presolving the host's networks sub problem.
 * @author Dimitri Justeau
 */
public class NetworkUtils {

    private NetworkUtils() {}

    /**
     * Given a list of network matrices, identify which ones admit a saturating
     * matching on the netconfs partition (columns).
     * @param matrices The network matrices.
     * @return An list containing the index of the matching networks.
     */
    public static List<Integer> matchingNetworks(final List<int[][]> matrices) {
        // Init list.
        final List<Integer> candidates = new ArrayList<Integer>();

        for (int j = 0; j < matrices.size(); j++) {
            int[][] current = matrices.get(j);
            if (current.length > 0) {
                int dimA = current[0].length;
                int dimB = current.length;
                if (dimA <= dimB) {
                    if (HopcroftKarp.maximumMatchingCard(current) == dimA) {
                        candidates.add(j);
                    }
                }
            }
        }

        return candidates;
    }

    /**
     * Construct the network matrices of a list of host according to a given
     * constraints instance.
     * @param hosts The hosts.
     * @param constraints The constraints.
     */
    public static List<int[][]> constructNetworkMatrices(final Host[] hosts, final Constraints constraints) {
        // Init list.
        final List<int[][]> matrices = new ArrayList<int[][]>();

        // Number of netconfs groups (column dimension)
        final int groups_number = constraints.getNetwork().getInterfaces().size();

        for (int j = 0; j < hosts.length; j++) {
            Host host = hosts[j];
            // Number of lines : ifaces
            int ifaces_number = host.getNetwork().getIfaces().size();
            int[][] cost_matrix = new int[ifaces_number][groups_number];
            for (int iface = 0; iface < ifaces_number; iface++) {
                int current_bonds = host.getNetwork().getIfaces().get(iface).getBondsNumber();
                List<Integer> current_netconfs =  host.getNetwork().getIfaces().get(iface).getNetIPs();

                for (int group = 0; group < groups_number; group++) {
                    int current_min_bonds =constraints.getNetwork().
                    getInterfaces().get(group).getBondsNumberMin();
                    List<Integer> current_group =
                            constraints.getNetwork().getInterfaces().get(group).getNetIPsMin();

                    boolean fit = current_netconfs.
                            containsAll(current_group) && current_bonds >= current_min_bonds;
                    cost_matrix[iface][group] = fit ? current_bonds - current_min_bonds + 1 : 0;
                }
            }
            matrices.add(cost_matrix);
        }
        return matrices;
    }

    /**
     * Compute the arbitrary cost of the network of a host.
     * @param host The host.
     * @param bond_weight The weight of a bond.
     * @param netIP_weight The weight of a netIP.
     * @return The cost of the network :
     *              iface_cost   = total_bonds_number * bond_weight + total_netIP_number * netIP_weight,
     *              network_cost = sum(iface_cost's).
     */
    public static int computeNetworkCost(Host host, int bond_weight, int netIP_weight) {
        int total_cost = 0;
        for (Iface iface : host.getNetwork().getIfaces()) {
            total_cost += iface.getBondsNumber() * bond_weight + iface.getNetIPs().size() * netIP_weight;
        }
        return total_cost;
    }
}
