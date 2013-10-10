package utils;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

/**
 * Hopcroft-Karp algorithm implementation.
 * @author Dimitri Justeau
 */
public class HopcroftKarp {

    /**
     * The NIL node id.
     */
    private static final int NIL = -1;

    /**
     * The distance of the NIL node.
     */
    private static int DIST_NIL;

    /**
     * The dimension of the partition A.
     */
    private static int dimA;

    /**
     * The dimension of the partition B.
     */
    private static int dimB;

    /**
     * The adjacency vector of the partition A.
     */
    private static int[][] adj_A;

    /**
     * The distance vector of the partition A.
     */
    private static int[] dist_A;

    /**
     * To get the node from B connected to a node from A.
     */
    private static int[] pair_A;

    /**
     * To get the node from A connected to a node from B.
     */
    private static int[] pair_B;

    private HopcroftKarp() {}

    /**
     * Compute the maximum matching cardinality using the HopcroftKarp algorithm.
     * @param matrix The adjacency submatrix representing the Bipartite graph.
     * @return The maximum matching cardinality.
     */
    public static int maximumMatchingCard(int[][] matrix) {
        // Initialize the dimensions.
        dimA       = matrix[0].length;
        dimB       = matrix.length;

        // Initialize the A adjacency vector.
        adj_A = new int[dimA][];
        for (int a = 0; a < dimA; a++) {
            List<Integer> neighbors = new ArrayList<Integer>();
            for (int b = 0; b < dimB; b++) {
                if (matrix[b][a] > 0) {
                    neighbors.add(b);
                }
            }
            adj_A[a] = new int[neighbors.size()];
            for (int i = 0; i < neighbors.size(); i++) {
                adj_A[a][i] = neighbors.get(i);
            }
        }

        // Initialize the dist vector;
        dist_A = new int[dimA];

        // Initialize the pair vectors and start the algorithm.
        pair_A = new int[dimA];
        pair_B = new int[dimB];
        for (int a = 0; a < dimA; a++) {
            pair_A[a] = NIL;
        }
        for (int b = 0; b < dimB; b++) {
            pair_B[b] = NIL;
        }
        int matching = 0;
        while ( BreadthFirstSearch() ) {
            for (int a = 0; a < dimA; a++) {
                if (pair_A[a] == NIL) {
                    if ( DepthFistSearch(a) ) {
                        matching += 1;
                    }
                }
            }
        }
        return matching;
    }

    /**
     * Perform a Breadth First Search
     * @return true if it still possible to construct an augmenting path.
     */
    private static boolean BreadthFirstSearch() {
        LinkedList<Integer> Queue = new LinkedList<Integer>();
        for (int a = 0; a < dimA; a++) {
            if (pair_A[a] == -1) {
                dist_A[a] = 0;
                Queue.add(a);
            } else {
                dist_A[a] = Integer.MAX_VALUE;
            }
        }
        DIST_NIL = Integer.MAX_VALUE;
        while (!Queue.isEmpty()) {
            int a  = Queue.pop();
            if (dist_A[a] < DIST_NIL) {
                for (int b : adj_A[a]) {
                    int d2 = (pair_B[b] == NIL) ? DIST_NIL : dist_A[ pair_B[b] ];
                    if ( d2 == Integer.MAX_VALUE ) {
                        if (pair_B[b] == NIL) {
                            DIST_NIL = dist_A[a] + 1;
                        } else {
                            dist_A[ pair_B[b] ] = dist_A[a] + 1;
                            Queue.add(pair_B[b]);
                        }
                    }
                }
            }
        }
        return (DIST_NIL != Integer.MAX_VALUE);
    }

    /**
     * Perform a Depth First Search from the node a.
     * @param a The starting node.
     * @return true if the matching had been augmented.
     */
    private static boolean DepthFistSearch(int a) {
        if (a != NIL) {
            for (int b : adj_A[a]) {
                int d = (pair_B[b] == NIL) ? DIST_NIL : dist_A[ pair_B[b] ];
                if (d == dist_A[a] + 1) {
                    if (DepthFistSearch(pair_B[b])) {
                        pair_B[b] = a;
                        pair_A[a] = b;
                        return true;
                    }
                }
            }
            dist_A[a] = Integer.MAX_VALUE;
            return false;
        }
        return true;
    }
}
