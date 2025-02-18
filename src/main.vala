using Gtk;
using Gee;

delegate string read_config (string config_descriptor) throws GLib.Error;

int main (string[] args) {
    Map<string, string> argMap;

    try {
        argMap = parse_args (args);
    } catch (Error e) {
        printerr ("error: %s\n", e.message);
        printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
        return 1;
    }

    if (argMap.has_key ("-v") || argMap.has_key ("--version")) {
        print ("remontoire 1.4.3 (C) 2022 Ken Gilmer\n");
        return 0;
    }

    if (argMap.has_key ("-h") || argMap.has_key ("--help")) {
        print ("""
      Usage:
        remontoire (-c <file path> | -s <socket URI> | -h | -v) [-t <file path>]
      
      Help Options:
        -h, --help                           Show help options
      
      Application Options:
        -v, --version                        Display version number
        -s <Socket URI>                      Socket path for i3
        -c <Path to config file>             Config file
        -i <Read from standard input>        Read from standard input
        -t <Path to style file>              CSS file
        -p <comment line prefix>             Prefix of comment line
        """);
        print ("\n");
        return 0;
    }

    read_config config_reader;
    string config_descriptor;
    if (argMap.has_key ("-s")) {
        config_reader = read_socket_config;
        config_descriptor = argMap.get ("-s");
    } else if (argMap.has_key ("-c")) {
        config_reader = read_file_config;
        config_descriptor = argMap.get ("-c");
    } else if (argMap.has_key ("-i")) {
        config_reader = read_stdin_config;
        config_descriptor = "";
    } else {
        printerr ("Must specify -s <i3 Socket URI>, -c <Config file path> or -i <STDIN>.\n");
        printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
        return 1;
    }

    string line_prefix = "";
    if (argMap.has_key ("-p")) {
        line_prefix = argMap.get ("-p");
    }

    var app = new Gtk.Application ("org.regolith.remontoire", ApplicationFlags.FLAGS_NONE);
    var settings = new GLib.Settings ("org.regolith-linux.remontoire");

    app.activate.connect (() => {
        var window = app.active_window;
        if (window == null) {
            try {
                var configParser = new ConfigParser (config_reader (config_descriptor), line_prefix);
                window = new Remontoire.SliderWindow (app, configParser.parse (), settings);

                Gtk.CssProvider css_provider = new Gtk.CssProvider ();
                if (!argMap.has_key ("-t")) {
                    css_provider.load_from_resource ("/application/style/style.css");
                } else {
                    var file = File.new_for_path (argMap.get ("-t"));

                    if (!file.query_exists ()) {
                        printerr ("File '%s' doesn't exist.\n", file.get_path ());
                        Process.exit (1);
                    }
                    css_provider.load_from_file (file);
                }

                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
            } catch (PARSE_ERROR ex) {
                error ("Failed to start: " + ex.message);
            } catch (GLib.Error ex) {
                error ("Failed to start: " + ex.message);
            }
        }

        var geometry = Helper.getScreenSizeForWindow (window);
        var position = settings.get_string ("window-position");
        var x_padding = settings.get_int ("window-padding-width");
        var y_padding = settings.get_int ("window-padding-height");

        window.configure_event.connect (() => {
            int height, width;

            window.get_size (out width, out height);
            int x_position, y_position;

            switch (position) {
                case "north":
                    x_position = geometry.x + ((geometry.width - width) / 2);
                    y_position = geometry.y + y_padding;
                    break;
                case "south":
                    x_position = geometry.x + ((geometry.width - width) / 2);
                    y_position = geometry.y + geometry.height - height - y_padding;
                    break;
                case "west":
                    x_position = geometry.x + x_padding;
                    y_position = ((geometry.y + geometry.height - height) / 2);
                    break;
                case "east":
                default:
                    x_position = geometry.x + geometry.width - width - x_padding;
                    y_position = ((geometry.y + geometry.height - height) / 2);
                    break;
            }

            window.move (x_position, y_position);

            return false;
        });

        window.show_all ();
    });

    return app.run (new string[0]);
}

/**
 *  Parse config from socket connection to i3.
 */
string read_socket_config (string socket_address) throws GLib.Error {
    var client = new Grelier.Client (socket_address);

    return client.getConfig ().config;
}

/**
 * Parse config from file path.
 */
string read_file_config (string file_path) throws GLib.Error {
    var file = File.new_for_path (file_path);

    if (!file.query_exists ()) {
        printerr ("File '%s' doesn't exist.\n", file.get_path ());
        Process.exit (1);
    }

    var dis = new DataInputStream (file.read ());
    string line;
    var str_builder = new StringBuilder ();

    while ((line = dis.read_line (null)) != null) {
        str_builder.append (line);
        str_builder.append ("\n");
    }

    return str_builder.str;
}

string read_stdin_config (string unused) throws GLib.Error {
    var input = new StringBuilder ();
    var buffer = new char[1024];
    while (!stdin.eof ()) {
        string read_chunk = stdin.gets (buffer);
        if (read_chunk != null) {
            input.append (read_chunk);
        }
    }
    return input.str;
}
