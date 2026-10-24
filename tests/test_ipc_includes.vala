/*
 * The config read over IPC must contain the keybinding comments of every
 * file the window manager includes, for i3 (which sends them) and for sway
 * (which sends only the main config).
 */

const int GET_CONFIG = 9;
const int GET_VERSION = 7;

string tmp_dir;

void send_all (Socket conn, uint8[] data) throws GLib.Error {
    int sent = 0;
    while (sent < data.length) {
        sent += (int) conn.send (data[sent : data.length]);
    }
}

string to_json (Json.Node root) {
    var generator = new Json.Generator ();
    generator.set_root (root);
    return generator.to_data (null);
}

/*
 * A window manager that answers GET_CONFIG with config_reply and
 * GET_VERSION with version_reply until the client disconnects.
 */
Thread<bool> fake_wm (Socket server, string config_reply, string version_reply) {
    return new Thread<bool> ("fake-wm", () => {
        try {
            var conn = server.accept ();
            while (true) {
                uint8[] request = new uint8[14];
                int got = 0;
                while (got < request.length) {
                    ssize_t len = conn.receive (request[got : request.length]);
                    if (len == 0) {
                        return true;
                    }
                    got += (int) len;
                }
                uint32 type = 0;
                Memory.copy (&type, &request[10], 4);
                string payload = type == GET_CONFIG ? config_reply : version_reply;

                var message = new ByteArray ();
                message.append ("i3-ipc".data);
                uint8[] word = new uint8[4];
                uint32 length = payload.length;
                Memory.copy (word, &length, 4);
                message.append (word);
                Memory.copy (word, &type, 4);
                message.append (word);
                message.append (payload.data);
                send_all (conn, message.data);
            }
        } catch (GLib.Error e) {
            return true;
        }
    });
}

string get_config (string config_reply, string version_reply) throws GLib.Error {
    var path = Path.build_filename (tmp_dir, "ipc.sock");
    var server = new Socket (SocketFamily.UNIX, SocketType.STREAM, SocketProtocol.DEFAULT);
    server.bind (new UnixSocketAddress (path), true);
    server.listen ();

    var wm = fake_wm (server, config_reply, version_reply);
    string config;
    {
        var client = new Grelier.Client (path);
        config = client.getConfig ().config;
    }
    wm.join ();
    server.close ();
    FileUtils.unlink (path);
    return config;
}

void write_file (string relative_path, string contents) throws GLib.Error {
    var path = Path.build_filename (tmp_dir, relative_path);
    DirUtils.create_with_parents (Path.get_dirname (path), 0755);
    FileUtils.set_contents (path, contents);
}

/* Lines of config that are keybinding comments. */
string bindings (string config) {
    var result = new StringBuilder ();
    foreach (unowned string line in config.split ("\n")) {
        if (line.strip ().has_prefix ("## ")) {
            result.append (line.strip ());
            result.append_c ('\n');
        }
    }
    return result.str;
}

void test_i3_included_configs () {
    var builder = new Json.Builder ();
    builder.begin_object ();
    builder.set_member_name ("config");
    builder.add_string_value ("## Main // In main // <Super> m ##\ninclude /etc/x/*\n");
    builder.set_member_name ("included_configs");
    builder.begin_array ();
    string[,] files = {
        { "/etc/x/config", "## Main // In main // <Super> m ##\ninclude /etc/x/*\n" },
        { "/etc/x/10_a", "set $mod Mod4\n## A // In partial a // <Super> a ##\nbindsym $mod+a nop" },
        { "/etc/x/20_b", "## B // In partial b // $mod b ##\n" }
    };
    for (int i = 0; i < files.length[0]; i++) {
        builder.begin_object ();
        builder.set_member_name ("path");
        builder.add_string_value (files[i, 0]);
        builder.set_member_name ("raw_contents");
        builder.add_string_value (files[i, 1]);
        builder.set_member_name ("variable_replaced_contents");
        builder.add_string_value (files[i, 1].replace ("$mod", "Mod4"));
        builder.end_object ();
    }
    builder.end_array ();
    builder.end_object ();

    try {
        var config = get_config (to_json (builder.get_root ()), "{}");
        assert_cmpstr (bindings (config), CompareOperator.EQ,
                       "## Main // In main // <Super> m ##\n" +
                       "## A // In partial a // <Super> a ##\n" +
                       "## B // In partial b // $mod b ##\n");
    } catch (GLib.Error e) {
        error (e.message);
    }
}

/*
 * Once an included file has a config error (such as a duplicate binding), i3
 * leaves it and the files included after it out of included_configs, though
 * it still loads their bindings: read those files.
 */
void test_i3_left_out_includes () {
    try {
        write_file ("etc/i3/config.d/10_a", "## A // Sent by i3 // <Super> a ##\n");
        write_file ("etc/i3/config.d/20_b", "## B // Left out // <Super> b ##\ninclude ../extra\n");
        write_file ("etc/i3/extra", "## Extra // Left out, nested // <Super> e ##\n");
        string main_path = Path.build_filename (tmp_dir, "etc/i3/config");
        string main_config = "## Main // In main // <Super> m ##\ninclude config.d/*\n";
        write_file ("etc/i3/config", main_config);

        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("config");
        builder.add_string_value (main_config);
        builder.set_member_name ("included_configs");
        builder.begin_array ();
        string[,] files = {
            { main_path, main_config },
            { Path.build_filename (tmp_dir, "etc/i3/config.d/10_a"), "## A // Sent by i3 // <Super> a ##\n" }
        };
        for (int i = 0; i < files.length[0]; i++) {
            builder.begin_object ();
            builder.set_member_name ("path");
            builder.add_string_value (files[i, 0]);
            builder.set_member_name ("raw_contents");
            builder.add_string_value (files[i, 1]);
            builder.end_object ();
        }
        builder.end_array ();
        builder.end_object ();

        var config = get_config (to_json (builder.get_root ()), "{}");
        assert_cmpstr (bindings (config), CompareOperator.EQ,
                       "## Main // In main // <Super> m ##\n" +
                       "## A // Sent by i3 // <Super> a ##\n" +
                       "## B // Left out // <Super> b ##\n" +
                       "## Extra // Left out, nested // <Super> e ##\n");
    } catch (GLib.Error e) {
        error (e.message);
    }
}

void test_sway_includes () {
    try {
        Environment.set_variable ("REMONTOIRE_TEST_DIR", tmp_dir, true);
        Environment.set_variable ("HOME", Path.build_filename (tmp_dir, "home"), true);
        write_file ("etc/sway/config.d/20_second", "## Second // From config.d // <Super> 2 ##\n");
        write_file ("etc/sway/config.d/10_first", "## First // From config.d // <Super> 1 ##\ninclude ../extra\n");
        write_file ("etc/sway/config.d/.hidden", "## Hidden // Not included // <Super> h ##\n");
        write_file ("etc/sway/extra", "## Extra // Relative to the including file // <Super> e ##\n");
        write_file ("home/.config/sway/config.d/user", "## User // From the home directory // <Super> u ##\ninclude $REMONTOIRE_TEST_DIR/etc/sway/config.d/*\n");
        write_file ("var/one", "## Var // Braced variable // <Super> v ##\n");
        string main_config = "## Main // In main // <Super> m ##\n" +
                             "include config.d/*\n" +
                             "include ~/.config/sway/config.d/*\n" +
                             "include ${REMONTOIRE_TEST_DIR}/var/one\n" +
                             "include /nonexistent/config.d/*\n";
        write_file ("etc/sway/config", main_config);

        var config_reply = new Json.Builder ();
        config_reply.begin_object ();
        config_reply.set_member_name ("config");
        config_reply.add_string_value (main_config);
        config_reply.end_object ();
        var version_reply = new Json.Builder ();
        version_reply.begin_object ();
        version_reply.set_member_name ("loaded_config_file_name");
        version_reply.add_string_value (Path.build_filename (tmp_dir, "etc/sway/config"));
        version_reply.end_object ();

        var config = get_config (to_json (config_reply.get_root ()), to_json (version_reply.get_root ()));
        // Every file once, in the order sway reads them (a file that was
        // already read is not read again).
        assert_cmpstr (bindings (config), CompareOperator.EQ,
                       "## Main // In main // <Super> m ##\n" +
                       "## First // From config.d // <Super> 1 ##\n" +
                       "## Extra // Relative to the including file // <Super> e ##\n" +
                       "## Second // From config.d // <Super> 2 ##\n" +
                       "## User // From the home directory // <Super> u ##\n" +
                       "## Var // Braced variable // <Super> v ##\n");
    } catch (GLib.Error e) {
        error (e.message);
    }
}

void remove_tree (string path) {
    if (FileUtils.test (path, FileTest.IS_DIR) && !FileUtils.test (path, FileTest.IS_SYMLINK)) {
        try {
            var dir = Dir.open (path);
            string ? name;
            while ((name = dir.read_name ()) != null) {
                remove_tree (Path.build_filename (path, name));
            }
        } catch (FileError e) {
            warning (e.message);
        }
        DirUtils.remove (path);
    } else {
        FileUtils.unlink (path);
    }
}

int main (string[] args) {
    Test.init (ref args);
    try {
        tmp_dir = DirUtils.make_tmp ("remontoire-test-XXXXXX");
    } catch (FileError e) {
        error (e.message);
    }
    Test.add_func ("/ipc/i3_included_configs", test_i3_included_configs);
    Test.add_func ("/ipc/i3_left_out_includes", test_i3_left_out_includes);
    Test.add_func ("/ipc/sway_includes", test_sway_includes);
    int result = Test.run ();
    remove_tree (tmp_dir);
    return result;
}
