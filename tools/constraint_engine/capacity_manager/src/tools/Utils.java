package tools;

import java.util.Comparator;

/**
 * Some unclassifiables utils methods.
 */
public class Utils {

    private Utils() {}

    public static ArrayIndexDecreasingComparator makeArrayIndexDecreasingComparator(int[] array) {
        return new ArrayIndexDecreasingComparator(array);
    }

    public static ArrayIndexIncreasingComparator makeArrayIndexIncreasingComparator(int[] array) {
        return new ArrayIndexIncreasingComparator(array);
    }

    /**
     * @param length
     * @return Make an Integer index array ( [0,1,2,3,...,lenght-1]).
     */
    public static Integer[] makeIndexArray(int length) {
        Integer[] indexes = new Integer[length];
        for (int i = 0; i < length; i++) {
            indexes[i] = i;
        }
        return indexes;
    }

    /**
     * Comparator for sorting decreasingly the index array corresponding to a value array.
     */
    public static class ArrayIndexDecreasingComparator implements Comparator<Integer> {

        private final Integer[] m_array;

        private ArrayIndexDecreasingComparator(int[] array) {
            this.m_array = new Integer[array.length];
            for (int i = 0; i < array.length; i++) {
                this.m_array[i] = array[i];
            }
        }

        @Override
        public int compare(Integer index1, Integer index2) {
            return m_array[index2].compareTo(m_array[index1]);
        }
    }

    /**
     * Comparator for sorting increasingly the index array corresponding to a value array.
     */
    public static class ArrayIndexIncreasingComparator implements Comparator<Integer> {

        private final Integer[] m_array;

        private ArrayIndexIncreasingComparator(int[] array) {
            this.m_array = new Integer[array.length];
            for (int i = 0; i < array.length; i++) {
                this.m_array[i] = array[i];
            }
        }

        @Override
        public int compare(Integer index1, Integer index2) {
            return m_array[index1].compareTo(m_array[index2]);
        }
    }
}
