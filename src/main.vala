using Gtk;

delegate string read_config(string config_descriptor) throws GLib.Error;

static string? socket = null;
static bool version = false;
static string? directory = null;
const GLib.OptionEntry[] options = {
    // --version
    { "version", 'v', 0, OptionArg.NONE, ref version, "Display version number", null },
    // --socket SOCKETPATH || -s SOCKETPATH
    { "socket", 's', 0, OptionArg.STRING, ref socket, "Socket path for i3", "<Socket URI>" },
    // --file FIlENAME || -f FILENAME
    { "file", 'c', 0, OptionArg.FILENAME, ref directory, "Config file", "<Path to config file>" },
    // list terminator
    { null }
};

int main (string[] args) {
    try {
        var opt_context = new OptionContext ();
        opt_context.set_help_enabled (true);
        opt_context.add_main_entries (options, null);
        opt_context.parse (ref args);
    } catch (OptionError e) {
        printerr ("error: %s\n", e.message);
        printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
        return 1;
    }

    if (version) {
        print ("remontoire 1.2.3 © 2020 Ken Gilmer\n");
        return 0;
    }

    if ((socket != null && directory != null) || (socket == null && directory == null)) {
        printerr ("Must specify either socket path or file path.\n");
        printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
        return 1;
    }

    read_config config_reader;
    string config_descriptor;
    if (socket != null) {
        config_reader = read_socket_config;
        config_descriptor = socket;
    } else {
        config_reader = read_file_config;
        config_descriptor = directory;
    }

    var app = new Gtk.Application ("org.regolith.remontoire", ApplicationFlags.FLAGS_NONE);
    var settings = new GLib.Settings("org.regolith-linux.remontoire");

    app.activate.connect (() => {
        var window = app.active_window;
        if (window == null) {
            try {
                var configParser = new ConfigParser(config_reader(config_descriptor));
                window = new Remontoire.SliderWindow (app, configParser.parse(), settings);

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

/**
 *  Parse config from socket connection to i3.
 */ 
string read_socket_config(string socket_address) throws GLib.Error {
    var client = new Grelier.Client(socket_address);

    return client.getConfig().config;
}

/** 
 * Parse config from file path.
 */
string read_file_config(string file_path) throws GLib.Error {
    var file = File.new_for_path (file_path);

    if (!file.query_exists ()) {
        printerr ("File '%s' doesn't exist.\n", file.get_path ());
        Process.exit (1);
    }

    var dis = new DataInputStream (file.read ());
    string line;
    var str_builder = new StringBuilder();
    
    while ((line = dis.read_line (null)) != null) {
        str_builder.append(line);
        str_builder.append("\n");        
    }

    return str_builder.str;
}