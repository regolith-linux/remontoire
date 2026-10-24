/*
 * Grelier.Client must read the whole reply of the window manager, however
 * large it is and however many chunks it arrives in.
 */

const int GET_CONFIG = 9;

void send_all (Socket conn, uint8[] data) throws GLib.Error {
    int sent = 0;
    while (sent < data.length) {
        sent += (int) conn.send (data[sent : data.length]);
    }
}

/*
 * Answers one request on socket_path with payload, split into chunks.
 */
Thread<bool> fake_wm (Socket server, string payload, int chunks) {
    return new Thread<bool> ("fake-wm", () => {
        try {
            var conn = server.accept ();
            uint8[] request = new uint8[14];
            int got = 0;
            while (got < request.length) {
                got += (int) conn.receive (request[got : request.length]);
            }

            var header = new ByteArray ();
            header.append ("i3-ipc".data);
            uint32 length = payload.length;
            uint32 type = GET_CONFIG;
            uint8[] word = new uint8[4];
            Memory.copy (word, &length, 4);
            header.append (word);
            Memory.copy (word, &type, 4);
            header.append (word);
            send_all (conn, header.data);

            uint8[] data = payload.data;
            int chunk = data.length / chunks + 1;
            for (int offset = 0; offset < data.length; offset += chunk) {
                send_all (conn, data[offset : int.min (offset + chunk, data.length)]);
                Thread.usleep (20000);
            }
            conn.close ();
        } catch (GLib.Error e) {
            critical ("fake window manager: %s", e.message);
            return false;
        }
        return true;
    });
}

/* A GET_CONFIG reply as i3 sends it, for a config that includes no other file. */
string config_reply (string config) {
    var builder = new Json.Builder ();
    builder.begin_object ();
    builder.set_member_name ("config");
    builder.add_string_value (config);
    builder.set_member_name ("included_configs");
    builder.begin_array ();
    builder.begin_object ();
    builder.set_member_name ("path");
    builder.add_string_value ("/etc/i3/config");
    builder.set_member_name ("raw_contents");
    builder.add_string_value (config);
    builder.set_member_name ("variable_replaced_contents");
    builder.add_string_value (config);
    builder.end_object ();
    builder.end_array ();
    builder.end_object ();
    var generator = new Json.Generator ();
    generator.set_root (builder.get_root ());
    return generator.to_data (null);
}

string get_config_through (string payload, int chunks) throws GLib.Error {
    var dir = DirUtils.make_tmp ("remontoire-test-XXXXXX");
    var path = Path.build_filename (dir, "ipc.sock");
    var server = new Socket (SocketFamily.UNIX, SocketType.STREAM, SocketProtocol.DEFAULT);
    server.bind (new UnixSocketAddress (path), true);
    server.listen ();

    var wm = fake_wm (server, payload, chunks);
    var client = new Grelier.Client (path);
    var config = client.getConfig ().config;
    assert (wm.join ());

    server.close ();
    FileUtils.unlink (path);
    DirUtils.remove (dir);
    return config;
}

void test_small_reply () {
    var config = "## Launch // Terminal // <Super> Enter ##\n";
    try {
        assert (get_config_through (config_reply (config), 1) == config);
    } catch (GLib.Error e) {
        error (e.message);
    }
}

void test_large_reply_in_chunks () {
    var builder = new StringBuilder ();
    for (int i = 0; i < 6000; i++) {
        builder.append_printf ("## Category %d // Action number %d // <Super><Shift> F%d ##\n", i % 10, i, i % 12);
    }
    var config = builder.str;
    assert (config.length > 256 * 1024);
    try {
        assert (get_config_through (config_reply (config), 7) == config);
    } catch (GLib.Error e) {
        error (e.message);
    }
}

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/ipc/small_reply", test_small_reply);
    Test.add_func ("/ipc/large_reply_in_chunks", test_large_reply_in_chunks);
    return Test.run ();
}
