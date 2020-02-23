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
                window = new Remontoire.Window (app, new ConfigParser(args[1]));
                window.icon = IconTheme.get_default().load_icon("dialog-information", 48, 0);
            } catch (PARSE_ERROR ex) {
                error("Failed to start: " + ex.message);
            } catch (GLib.Error ex) {
                error("Failed to start: " + ex.message);
            } 
        }       
        
        int lastWindowWidth = 0, lastWindowHeight = 0;

        window.check_resize.connect (() => {
            const int padding = 6;
            int height, width;

            window.get_size(out width, out height);   
            
            // Check to see if window width has changed, if so, reposition.
            if (width != lastWindowWidth || height != lastWindowHeight) {
                var geometry = Helper.getScreenSizeForWindow(window);

                var x_position = geometry.width - width - padding;
                var y_position = ((geometry.height - height) / 2);

                window.move(x_position, y_position);
                lastWindowWidth = width;
                lastWindowHeight = height;
                print(@"resized $height\n");
            }
        });
        
        window.show_all ();                        
    });

    return app.run (new string[0]);
}
