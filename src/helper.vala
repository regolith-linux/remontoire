
class Helper {

    /**
     * Return the screen dimentions in pixels that containes the passed-in window.
     */
    public static Gdk.Rectangle getScreenSizeForWindow (Gtk.Window window) {
        var display = Gdk.Display.get_default ();
        var monitor = display.get_monitor_at_window (window.get_window ());

        return monitor.get_geometry ();
    }
}
