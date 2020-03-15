using Gtk;
using Gdk;
using Gee;

namespace Remontoire {

    /**
     * Primary window to dispay keybindings.
     */
    public class SliderWindow : Gtk.Window {

        public SliderWindow (Gtk.Application app, ConfigParser configParser) throws PARSE_ERROR, GLib.Error, Grelier.I3_ERROR {
            Object (application: app);

            style_window(this);

            var config = configParser.parse();
            var settings = new GLib.Settings("org.regolith-linux.remontoire");
            stdout.printf ("loading paths %s\n", settings.get_string("expanded-category-path-ids"));
            var expandedCategories = parsePaths(settings.get_string("expanded-category-path-ids"));
        
            var flowbox = new FlowBox();
            flowbox.max_children_per_line = 1;
            flowbox.min_children_per_line = 1;
            flowbox.set_orientation(Orientation.HORIZONTAL);
            this.add(flowbox);

            setup_treeview (flowbox, config, settings, expandedCategories);

            this.destroy.connect (Gtk.main_quit);
        }

        private void setup_treeview (Gtk.Container parent, Map<string, ArrayList<Keybinding>> keybindings, GLib.Settings settings, Set<string> expandedCategories) {       

            foreach (var categoryEntry in keybindings.entries) {
                Gtk.Expander expander;
                add_category(parent, out expander, categoryEntry.key);

                expander.expanded = expandedCategories.contains(categoryEntry.key);
                expander.activate.connect((expander) => {
                    if (expander.expanded == false) {
                        expandedCategories.add(expander.label);
                    } else {                        
                        expandedCategories.remove(expander.label);
                    }
                    savePaths(expandedCategories, settings);
                });

                var vbox = new Box(Gtk.Orientation.VERTICAL, 0);
                vbox.set_spacing(0);
                expander.add(vbox);

                foreach (var keybinding in categoryEntry.value) {
                    Gtk.Label binding_iter;
                    add_item(vbox, out binding_iter, keybinding.label, keybinding.spec);
                }
            }
        }

        private static void add_category(Gtk.Container window, out Gtk.Expander iter, string label) {
            iter = new Gtk.Expander (label);
            window.add (iter);
        }

        private static void add_item(Gtk.Container parent_iter, out Gtk.Label iter, string action, string keybinding) {
            iter = new Gtk.Label (action + ": " + keybinding);
            parent_iter.add (iter);
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
            stdout.printf ("saved paths %s\n", pathSetStr);
        }
    }
}
