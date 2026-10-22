public class Helper {

    /**
     * Return the screen dimentions in pixels that containes the passed-in window.
     */
    public static Gdk.Rectangle getScreenSizeForWindow (Gtk.Window window) {
        var display = Gdk.Display.get_default ();
        var monitor = display.get_monitor_at_window (window.get_window ());

        return monitor.get_geometry ();
    }

    /**
     * The expanded categories are saved as one comma-separated string. A
     * category name can contain commas, so "%" and "," in names are saved
     * as "%25" and "%2C".
     */
    public static string join_categories (Gee.Collection<string> categories) {
        var result = new StringBuilder ();
        foreach (var category in categories) {
            result.append (category.replace ("%", "%25").replace (",", "%2C"));
            result.append (",");
        }
        return result.str;
    }

    public static Gee.Set<string> split_categories (string saved) {
        var categories = new Gee.HashSet<string>();
        int start = 0;
        while (start < saved.length) {
            int end = saved.index_of_char (',', start);
            if (end < 0) {
                end = saved.length;
            }
            if (end > start) {
                categories.add (saved.substring (start, end - start).replace ("%2C", ",").replace ("%25", "%"));
            }
            start = end + 1;
        }
        return categories;
    }
}
