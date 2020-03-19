using Gtk;
using Gdk;
using Gee;

namespace Remontoire {

    /**
     * Primary window to dispay keybindings.
     */
    public class SliderWindow : Gtk.Window {

        public SliderWindow (Gtk.Application app, ConfigParser configParser, GLib.Settings settings) throws PARSE_ERROR, GLib.Error, Grelier.I3_ERROR {
            Object (application: app);

            style_window(this);

            var config = configParser.parse();
            
            var expandedCategories = parsePaths(settings.get_string("expanded-category-path-ids"));
        
            var flowbox = new FlowBox();
            flowbox.max_children_per_line = 1;
            flowbox.min_children_per_line = 1;
            flowbox.set_orientation(Orientation.HORIZONTAL);
            flowbox.get_style_context().add_class("window");
            this.add(flowbox);

            build_widgets (flowbox, config, settings, expandedCategories);

            this.destroy.connect (Gtk.main_quit);
        }

        private void build_widgets (Gtk.Container container, Map<string, ArrayList<Keybinding>> keybindings, GLib.Settings settings, Set<string> expandedCategories) {       

            foreach (var categoryEntry in keybindings.entries) {
                Gtk.Expander expander;
                add_category(container, out expander, categoryEntry.key);

                expander.expanded = expandedCategories.contains(categoryEntry.key);
                expander.activate.connect((expander) => {
                    if (expander.expanded == false) {
                        expandedCategories.add(expander.label);
                    } else {                        
                        expandedCategories.remove(expander.label);
                    }
                    savePaths(expandedCategories, settings);
                });

                var keybinding_container = new Box(Gtk.Orientation.VERTICAL, 0);
                keybinding_container.set_spacing(0);
                expander.add(keybinding_container);

                foreach (var keybinding in categoryEntry.value) {
                    add_item(keybinding_container, keybinding.label, keybinding.spec);
                }
            }
        }

        private static void add_category(Gtk.Container container, out Gtk.Expander expander, string label) {
            expander = new Gtk.Expander (label);
            expander.get_style_context().add_class("category");
            container.add (expander);
        }

        private static void add_item(Gtk.Container container, string action, string keybinding) {
            var keybinding_root = new Box(Gtk.Orientation.HORIZONTAL, 0);
            keybinding_root.get_style_context().add_class("detail");

            render_keybinding(keybinding_root, action, keybinding);
            container.add (keybinding_root);
        }

        /** 
         * Generate the keybinding composite label.
        */
        private static void render_keybinding(Gtk.Box parent, string action, string keybinding) {
            var action_label = new Gtk.Label(action);
            action_label.get_style_context().add_class("action");
            action_label.halign = START;
            parent.pack_start(action_label);

            var keys = parse_keybinding(keybinding);
            keys.reverse();

            Gtk.Label keybinding_label;
            foreach(var key in keys) {
                if (key.has_prefix("<") && key.has_suffix(">")) {
                    keybinding_label = new Gtk.Label(key.substring(1, key.length - 2));
                    keybinding_label.get_style_context().add_class("metakey");
                } else if (key.contains("..")) {
                    keybinding_label = new Gtk.Label(key);
                    keybinding_label.get_style_context().add_class("rangekey");
                } else {
                    keybinding_label = new Gtk.Label(key);
                    keybinding_label.get_style_context().add_class("key");
                }
                keybinding_label.halign = END;
                parent.pack_end(keybinding_label, false, false, 0);
            }
        }

        /** 
         * Ths method takes in a string and produces a list of strings. Ex:
         * <super><shift>a b c -> <super>, <shift>, a, b, c
        */
        private static GLib.List<string> parse_keybinding(string raw_keybinding) {
            var tokens = new GLib.List<string>();
            var str_builder = new StringBuilder();

            unichar c;
            for (int i = 0; raw_keybinding.get_next_char (ref i, out c);) {
                switch(c) {
                    case '<':
                        if (str_builder.len > 0) {
                            string token = str_builder.str;
                            tokens.append(token);
                            str_builder.erase(0);
                        }
                        str_builder.append(c.to_string ());
                        break;
                    case '>':
                        str_builder.append(c.to_string ());
                        string token = str_builder.str;
                        tokens.append(token);
                        str_builder.erase(0);
                        break;
                    case ' ': 
                        if (str_builder.len > 0) {
                            string token = str_builder.str;
                            tokens.append(token);
                            str_builder.erase(0);
                        }
                        break;
                    default:
                        str_builder.append(c.to_string ());
                        break;
                }
            }

            if (str_builder.len > 0) {
                string token = str_builder.str;
                tokens.append(token);
                str_builder.erase(0);
            }

            return tokens;
        }

        private static void style_window(Gtk.Window window) {
            window.set_skip_taskbar_hint(true);
            window.set_skip_pager_hint(true);
            window.set_decorated(false);
            window.set_resizable(false);
            window.set_focus_on_map(false);
            window.set_deletable(false);
            window.set_accept_focus(false);
            window.set_type_hint(SPLASHSCREEN);
            window.stick();
        }

        private Set<string> parsePaths(string pathList) {
            var pathSet = new HashSet<string>();
            if (pathList.length == 0) return pathSet;
            
            pathSet.add_all_array(pathList.split(","));
            
            return pathSet;
        }

        private void savePaths(Set<string> pathSet, GLib.Settings settings) {
            string pathSetStr = "";
            foreach (var pathstr in pathSet) {
                pathSetStr += pathstr;
                pathSetStr += ",";
            }
            settings.set_string("expanded-category-path-ids", pathSetStr);
        }
    }
}
