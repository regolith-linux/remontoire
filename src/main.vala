/**
 * Application entry-point.
 */
int main (string[] args) {
	var app = new Gtk.Application ("org.regolith.remontoire", ApplicationFlags.FLAGS_NONE);
	app.activate.connect (() => {
		var win = app.active_window;
		if (win == null) {
			win = new Remontoire.Window (app);
		}

        var geometry = Helper.getScreenSizeForWindow(win);
        int height, width;

		win.show_all ();

        const int padding = 5;

		win.get_size(out width, out height);
        var x_position = geometry.width - width - padding;
        var y_position = 0 + padding;

        win.move(x_position, y_position);
	});

	return app.run (args);
}
