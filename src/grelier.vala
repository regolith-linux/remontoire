/**
 * A client library for i3-wm that deserializes into idomatic Vala response objects.
 */
namespace Grelier {
    enum I3_COMMAND {
        RUN_COMMAND,
        GET_WORKSPACES,
        SUBSCRIBE,
        GET_OUTPUTS,
        GET_TREE,
        GET_MARKS,
        GET_BAR_CONFIG,
        GET_VERSION,
        GET_BINDING_MODES,
        GET_CONFIG,
        SEND_TICK,
        SYNC
    }

    public errordomain I3_ERROR {
        RPC_ERROR
    }

    // https://i3wm.org/docs/ipc.html#_version_reply
    public class VersionReply {
        public string human_readable { get; private set; }
        public string loaded_config_file_name { get; private set; }
        public string minor { get; private set; }
        public string patch { get; private set; }
        public string major { get; private set; }

        internal VersionReply (Json.Node responseJson) {
            human_readable = responseJson.get_object ().get_string_member ("human_readable");
            loaded_config_file_name = responseJson.get_object ().get_string_member ("loaded_config_file_name");
            minor = responseJson.get_object ().get_string_member ("minor");
            patch = responseJson.get_object ().get_string_member ("patch");
            major = responseJson.get_object ().get_string_member ("major");
        }
    }

    // https://i3wm.org/docs/ipc.html#_config_reply
    public class ConfigReply {
        public string config { get; private set; }

        internal ConfigReply (string config) {
            this.config = config;
        }
    }

    public class Client {
        private Socket socket;
        private uint8[] magic_number = "i3-ipc".data;
        private DataInputStream input;

        public Client (string i3Socket) throws GLib.Error {
            var socketAddress = new UnixSocketAddress (i3Socket);

            socket = new Socket (SocketFamily.UNIX, SocketType.STREAM, SocketProtocol.DEFAULT);
            assert (socket != null);

            socket.connect (socketAddress);
            socket.set_blocking (true);

            input = new DataInputStream (new UnixInputStream (socket.fd, false));
            input.byte_order = DataStreamByteOrder.HOST_ENDIAN;
        }

        ~Client () {
            if (socket != null) {
                try {
                    socket.close ();
                } catch (GLib.Error e) {
                    warning ("Failed to close the i3 socket: %s", e.message);
                }
            }
        }

        private uint8[] int32_to_uint8_array (int32 input) {
            Variant val = new Variant.int32 (input);
            return val.get_data_as_bytes ().get_data ();
        }

        private uint8[] generate_request (I3_COMMAND cmd) {
            ByteArray np = new ByteArray ();

            np.append (magic_number);
            np.append (int32_to_uint8_array (0)); // payloadSize.get_data_as_bytes().get_data());
            np.append (int32_to_uint8_array (cmd)); // command.get_data_as_bytes().get_data());

            Bytes message = ByteArray.free_to_bytes (np);

            return message.get_data ();
        }

        private Json.Node ? i3_ipc (I3_COMMAND command) throws GLib.Error {
            ssize_t sent = socket.send (generate_request (command));

            debug ("Sent " + sent.to_string () + " bytes to i3.\n");

            // Reply: "i3-ipc", payload length, reply type, payload. A large
            // payload arrives in several chunks, so read until it is complete.
            for (int i = 0; i < magic_number.length; i++) {
                if (input.read_byte () != magic_number[i]) {
                    throw new I3_ERROR.RPC_ERROR ("Invalid reply header");
                }
            }
            uint32 payload_length = input.read_uint32 ();
            input.read_uint32 ();

            var payload = new ByteArray.sized (payload_length);
            while (payload.len < payload_length) {
                Bytes chunk = input.read_bytes (payload_length - payload.len);

                if (chunk.get_size () == 0) {
                    throw new I3_ERROR.RPC_ERROR ("Connection closed after %u of %u bytes".printf (payload.len, payload_length));
                }
                payload.append (chunk.get_data ());
            }

            debug ("Received " + payload.len.to_string () + " bytes from i3.\n");

            Json.Parser parser = new Json.Parser ();
            parser.load_from_data ((string) payload.data, payload.len);

            return parser.get_root ();
        }

        public VersionReply getVersion () throws I3_ERROR, GLib.Error {
            var response = i3_ipc (I3_COMMAND.GET_VERSION);

            if (response == null) {
                throw new I3_ERROR.RPC_ERROR ("No Response");
            }

            return new VersionReply (response);
        }

        public ConfigReply getConfig () throws I3_ERROR, GLib.Error {
            var response = i3_ipc (I3_COMMAND.GET_CONFIG);

            if (response == null) {
                throw new I3_ERROR.RPC_ERROR ("No Response");
            }

            var reply = response.get_object ();

            // i3 sends the main config and every file it includes, in the
            // order it read them.
            if (reply.has_member ("included_configs")) {
                var config = new StringBuilder ();
                var sent_files = new GenericSet<string>(str_hash, str_equal);
                string ? main_config = null;
                string ? main_path = null;
                foreach (unowned Json.Node node in reply.get_array_member ("included_configs").get_elements ()) {
                    var file = node.get_object ();
                    string contents = file.get_string_member ("raw_contents");
                    if (main_config == null) {
                        main_config = contents;
                        main_path = file.get_string_member ("path");
                    }
                    sent_files.add (file.get_string_member ("path"));
                    config.append (contents);
                    if (!contents.has_suffix ("\n")) {
                        config.append_c ('\n');
                    }
                }

                // Once one included file has a config error, such as a
                // duplicate binding, i3 leaves it and the files included
                // after it out of included_configs, although it still loads
                // their bindings. Read the files it left out.
                if (main_config != null) {
                    var read_files = new GenericSet<string>(str_hash, str_equal);
                    read_files.add (real_path (main_path));
                    append_config (config, main_config, Path.get_dirname (main_path), read_files, sent_files, false);
                }
                return new ConfigReply (config.str);
            }

            // sway sends only the main config: read the files it includes.
            // Relative include paths start from the main config's directory.
            string config_dir = Environment.get_current_dir ();
            var version = i3_ipc (I3_COMMAND.GET_VERSION);
            if (version != null && version.get_object ().has_member ("loaded_config_file_name")) {
                config_dir = Path.get_dirname (version.get_object ().get_string_member ("loaded_config_file_name"));
            }

            var read_files = new GenericSet<string>(str_hash, str_equal);
            return new ConfigReply (add_included_files (reply.get_string_member ("config"), config_dir, read_files));
        }

        /**
         * Return config with the contents of every file it includes inserted
         * after the include line, recursively, as sway reads them. Supports
         * ~, $VAR and ${VAR} and wildcards in the last path component.
         */
        internal static string add_included_files (string config, string config_dir, GenericSet<string> read_files) {
            var result = new StringBuilder ();
            append_config (result, config, config_dir, read_files, null, true);
            return result.str;
        }

        /**
         * Append config to result if show is true, and after each of its
         * include lines the files it includes, recursively. Files are
         * identified by their real path, as i3 and sway do, and read once.
         * The files in sent_files are already in result: only the files they
         * include are added.
         */
        private static void append_config (StringBuilder result, string config, string config_dir,
                                           GenericSet<string> read_files, GenericSet<string> ? sent_files, bool show) {
            int start = 0;

            while (start < config.length) {
                int end = config.index_of_char ('\n', start);
                if (end < 0) {
                    end = config.length;
                }
                string line = config.substring (start, end - start);
                start = end + 1;

                if (show) {
                    result.append (line);
                    result.append_c ('\n');
                }

                string stripped = line.strip ();
                if (!stripped.has_prefix ("include ") && !stripped.has_prefix ("include\t")) {
                    continue;
                }

                foreach (string found in find_files (expand_path (stripped.substring (8).strip (), config_dir))) {
                    string path = real_path (found);
                    if (read_files.contains (path)) {
                        continue;
                    }
                    read_files.add (path);

                    string contents;
                    try {
                        FileUtils.get_contents (path, out contents);
                    } catch (FileError e) {
                        continue;
                    }
                    bool sent = sent_files != null && sent_files.contains (path);
                    append_config (result, contents, Path.get_dirname (path), read_files, sent_files, !sent);
                }
            }
        }

        /* The absolute path of a file with symbolic links resolved, or path if it does not exist. */
        private static string real_path (string path) {
            return Posix.realpath (path) ?? path;
        }

        private static string expand_path (string path, string config_dir) {
            string expanded = path;

            if (expanded == "~" || expanded.has_prefix ("~/")) {
                expanded = Environment.get_home_dir () + expanded.substring (1);
            }

            // $VAR and ${VAR}
            var result = new StringBuilder ();
            int i = 0;
            while (i < expanded.length) {
                if (expanded[i] != '$') {
                    result.append_c (expanded[i++]);
                    continue;
                }
                bool braced = i + 1 < expanded.length && expanded[i + 1] == '{';
                int name_start = braced ? i + 2 : i + 1;
                int name_end = name_start;
                while (name_end < expanded.length && (expanded[name_end].isalnum () || expanded[name_end] == '_')) {
                    name_end++;
                }
                if (name_end == name_start || (braced && (name_end >= expanded.length || expanded[name_end] != '}'))) {
                    result.append_c (expanded[i++]);
                    continue;
                }
                result.append (Environment.get_variable (expanded.substring (name_start, name_end - name_start)) ?? "");
                i = braced ? name_end + 1 : name_end;
            }
            expanded = result.str;

            if (!Path.is_absolute (expanded)) {
                expanded = Path.build_filename (config_dir, expanded);
            }

            return expanded;
        }

        /**
         * Files matching path, sorted; path may have wildcards in its last component.
         */
        private static List<string> find_files (string path) {
            var files = new List<string> ();
            string name = Path.get_basename (path);

            if (!("*" in name || "?" in name)) {
                files.append (path);
                return files;
            }

            string dir_path = Path.get_dirname (path);
            try {
                var dir = Dir.open (dir_path);
                string ? entry;
                while ((entry = dir.read_name ()) != null) {
                    if (PatternSpec.match_simple (name, entry) && !entry.has_prefix (".")) {
                        files.insert_sorted (Path.build_filename (dir_path, entry), strcmp);
                    }
                }
            } catch (FileError e) {
                // No such directory: nothing is included.
            }

            return files;
        }
    }
}
