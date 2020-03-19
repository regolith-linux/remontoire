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
    var settings = new GLib.Settings("org.regolith-linux.remontoire");

    app.activate.connect (() => {
        var window = app.active_window;
        if (window == null) {
            try {
                window = new Remontoire.SliderWindow (app, new ConfigParser(args[1]), settings);                

                Gtk.CssProvider css_provider = new Gtk.CssProvider ();
                css_provider.load_from_resource ("/application/style/style.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);    
            } catch (PARSE_ERROR ex) {
                error("Failed to start: " + ex.message);
            } catch (GLib.Error ex) {
                error("Failed to start: " + ex.message);
            } 
        }

        var geometry = Helper.getScreenSizeForWindow(window);
        var position = settings.get_string("window-position");
        var x_padding = settings.get_int("window-padding-width");
        var y_padding = settings.get_int("window-padding-height");

        window.configure_event.connect (() => {
            int height, width;

            window.get_size(out width, out height);   

            int x_position, y_position;

            switch(position) {
                case "north":
                    x_position = ((geometry.width - width) / 2);
                    y_position = 0 + y_padding;
                    break;
                case "south":
                    x_position = ((geometry.width - width) / 2);
                    y_position = geometry.height - height - y_padding;
                    break;
                case "west":
                    x_position = 0 + x_padding;
                    y_position = ((geometry.height - height) / 2);
                    break;
                case "east":
                default:
                    x_position = geometry.width - width - x_padding;
                    y_position = ((geometry.height - height) / 2);
                    break;
            }

            window.move(x_position, y_position);                            

            return false;
        });
        
        window.show_all ();                        
    });

    return app.run (new string[0]);
}
