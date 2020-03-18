using Gtk;
/**
 * Application entry-point.
 */
int main (string[] args) {
    if (args.length != 2) {
		print("usage: remontoire <i3 socket path>\n");
		return 1;
	}
    
    var app = new Gtk.Application ("org.regolith.remontoire", ApplicationFlags.FLAGS_NONE);
    
    app.activate.connect (() => {
        var window = app.active_window;
        if (window == null) {
            try {
                window = new Remontoire.SliderWindow (app, new ConfigParser(args[1]));                

                Gtk.CssProvider css_provider = new Gtk.CssProvider ();
                css_provider.load_from_resource ("/application/style/style.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);    
            } catch (PARSE_ERROR ex) {
                error("Failed to start: " + ex.message);
            } catch (GLib.Error ex) {
                error("Failed to start: " + ex.message);
            } 
        }       
        
        int lastWindowWidth = 0, lastWindowHeight = 0;
        var geometry = Helper.getScreenSizeForWindow(window);

        window.configure_event.connect (() => {
            const int padding = 6;
            int height, width;

            window.get_size(out width, out height);   
            
            var x_position = geometry.width - width - padding;
            var y_position = ((geometry.height - height) / 2);

            window.move(x_position, y_position);
            lastWindowWidth = width;
            lastWindowHeight = height;                            

            return false;
        });
        
        window.show_all ();                        
    });

    return app.run (new string[0]);
}
