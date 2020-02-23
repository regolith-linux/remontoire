using Gtk;
using Gdk;
using Gee;

namespace Remontoire {

    /**
     * Primary window to dispay keybindings.
     */
    public class Window : Gtk.Window {

        public Window (Gtk.Application app, ConfigParser configParser) throws PARSE_ERROR, GLib.Error, Grelier.I3_ERROR {
            Object (application: app);

            style_window(this);

            var config = configParser.parse();
            var settings = new GLib.Settings("org.regolith-linux.remontoire");
            var collapsedPathIds = parsePaths(settings.get_string("collapsed-category-path-ids"));

            var view = new TreeView ();
            setup_treeview (view, config, settings, collapsedPathIds);
            add (view);
            view.get_selection().unselect_all();

            this.destroy.connect (Gtk.main_quit);
        }

        private void setup_treeview (TreeView view, Map<string, ArrayList<Keybinding>> keybindings, GLib.Settings settings, Set<string> collapsedPathIds) {       
            var store = new TreeStore (2, typeof (string), typeof (string));
            view.set_model (store);

            view.insert_column_with_attributes (-1, "Action", new CellRendererText (), "text", 0, null);
            view.insert_column_with_attributes (-1, "Keybinding", new CellRendererAccel (), "text", 1, null);

            foreach (var categoryEntry in keybindings.entries) {
                TreeIter action_iter;
                add_category(store, out action_iter, categoryEntry.key);

                foreach (var keybinding in categoryEntry.value) {
                    TreeIter binding_iter;
                    add_item(store, action_iter, out binding_iter, keybinding.label, keybinding.spec);
                }
            }

            view.expand_all ();
            foreach (var pathStr in collapsedPathIds) {
                if (pathStr.strip().length > 0) {
                    view.collapse_row(new TreePath.from_string(pathStr));
                }
            }

            view.row_collapsed.connect((iter, path) => { 
                collapsedPathIds.add(path.to_string());
                savePaths(collapsedPathIds, settings);
            });

            view.row_expanded.connect((iter, path) => { 
                collapsedPathIds.remove(path.to_string());
                savePaths(collapsedPathIds, settings);
            });
        }

        private static void add_category(TreeStore store, out TreeIter iter, string label) {
            store.append (out iter, null);
            store.set (iter, 0, label, -1);
        }

        private static void add_item(TreeStore store, TreeIter parent_iter, out TreeIter iter, string action, string keybinding) {
            store.append (out iter, parent_iter);
            store.set (iter, 0, action, 1, keybinding, -1);
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
            settings.set_string("collapsed-category-path-ids", pathSetStr);
        }
    }
}
