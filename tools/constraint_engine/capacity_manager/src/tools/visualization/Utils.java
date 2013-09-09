package tools.visualization;

import java.awt.Color;
import java.util.ArrayList;
import java.util.List;

public class Utils {

    public static List<Color> generatePastelColors(int nb_colors) {
        List<Color> colors = new ArrayList<Color>();
        List<Integer> inthere = new ArrayList<Integer>();
        for (int i = 0; i < nb_colors; i++) {
            int e;
            do {
                e = (int) ( 4 * (Math.random() * 90) );
            }
            while ( inthere.contains(e) && inthere.size() < 89 );
            Color c = Color.getHSBColor( (float) ( (Math.random() * 360) ), 0.3f, 0.9f );
            inthere.add(e);
            colors.add(c);
        }
        return colors;
    }
}
