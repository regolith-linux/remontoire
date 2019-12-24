
class Helper {

    /**
     * Return the screen dimentions in pixels that containes the passed-in window.
     */
    public static Gdk.Rectangle getScreenSizeForWindow(Gtk.Window window) {
        var gdkWindow = window.get_window();
        var display = Gdk.Display.get_default();
        var monitor = display.get_monitor_at_window(gdkWindow);
        return monitor.get_geometry();
    }
}