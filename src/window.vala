using Gtk;
using Gdk;

namespace Remontoire {

    /**
     * Primary window to dispay keybindings.
     */
    public class Window : Gtk.Window {

        public Window (Gtk.Application app) {
            Object (application: app);

            style_window(this);

            var view = new TreeView ();
            setup_treeview (view);
            add (view);

            this.destroy.connect (Gtk.main_quit);
        }

        private void setup_treeview (TreeView view) {
            var store = new TreeStore (2, typeof (string), typeof (string));
            view.set_model (store);

            view.insert_column_with_attributes (-1, "Action", new CellRendererText (), "text", 0, null);
            view.insert_column_with_attributes (-1, "Keybinding", new CellRendererAccel (), "text", 1, null);

            TreeIter action_iter;
            TreeIter binding_iter;

            add_category(store, out action_iter, "Launch");

            add_item(store, action_iter, out binding_iter, "Terminal", "<Super> Return");
            add_item(store, action_iter, out binding_iter, "Browser", "<Super> <Shift> Enter");
            add_item(store, action_iter, out binding_iter, "Application", "<Super> Space");
            add_item(store, action_iter, out binding_iter, "Command", "<Super><Shift> Space");
            add_item(store, action_iter, out binding_iter, "Control Center", "<Super> c");
            add_item(store, action_iter, out binding_iter, "File Browser", "<Super><Shift> n");

            add_category(store, out action_iter, "Navigate");

            add_item(store, action_iter, out binding_iter, "Window by Name", "<Super><Ctrl> Space");
            add_item(store, action_iter, out binding_iter, "Relative Window", "<Super> ↑ ↓ ← →");
            add_item(store, action_iter, out binding_iter, "Relative Window", "<Super> k j h l");
            add_item(store, action_iter, out binding_iter, "Workspace 0 - 9", "<Super> 0…9");
            add_item(store, action_iter, out binding_iter, "Workspace 10 - 19", "<Super><Ctrl> 0…9");
            add_item(store, action_iter, out binding_iter, "Previous Workspace", "<Super><Shift> Tab");
            add_item(store, action_iter, out binding_iter, "Next Workspace", "<Super> Tab");

            add_category(store, out action_iter, "Modify");

            add_item(store, action_iter, out binding_iter, "Next Window Orientation", "<Super> Backspace");
            add_item(store, action_iter, out binding_iter, "Window Position", "<Super><Shift> ↑ ↓ ← →");
            add_item(store, action_iter, out binding_iter, "Window Position", "<Super><Shift> k j h l");
            add_item(store, action_iter, out binding_iter, "Workspace of Window", "<Super><Shift> 0…9");
            add_item(store, action_iter, out binding_iter, "Window Fullscreen Toggle", "<Super> f");
            add_item(store, action_iter, out binding_iter, "Window Floating Toggle", "<Super><Shift> f");
            add_item(store, action_iter, out binding_iter, "Bar Toggle", "<Super> i");

            add_category(store, out action_iter, "Resize");

            add_item(store, action_iter, out binding_iter, "Enter Resize Mode", "<Super> r");
            add_item(store, action_iter, out binding_iter, "Resize Window", "↑ ↓ ← →");
            add_item(store, action_iter, out binding_iter, "Resize Window", "k j h l");
            add_item(store, action_iter, out binding_iter, "Gaps Between Windows", "+ -");
            add_item(store, action_iter, out binding_iter, "Exit Resize Mode", "Escape");

            add_category(store, out action_iter, "Notifications");

            add_item(store, action_iter, out binding_iter, "View Notifications", "<Super> n");
            add_item(store, action_iter, out binding_iter, "Delete Notification", "Delete");
            add_item(store, action_iter, out binding_iter, "Delete All Notifications", "<Shift> Delete");
            add_item(store, action_iter, out binding_iter, "Exit Notifications", "Escape");

            add_category(store, out action_iter, "Other");

            add_item(store, action_iter, out binding_iter, "Kill Focused Window", "<Super><Shift> q");
            add_item(store, action_iter, out binding_iter, "Save Layout", "<Super> ,");
            add_item(store, action_iter, out binding_iter, "Load Layout", "<Super> .");
            add_item(store, action_iter, out binding_iter, "Lock Screen", "<Super> Escape");
            add_item(store, action_iter, out binding_iter, "Logout", "<Super><Shift> e");
            add_item(store, action_iter, out binding_iter, "Suspend Computer", "<Super><Shift> s");
            add_item(store, action_iter, out binding_iter, "Reboot Computer", "<Super><Shift> b");
            add_item(store, action_iter, out binding_iter, "Shutdown Computer", "<Super><Shift> p");
            add_item(store, action_iter, out binding_iter, "Toggle this Dialog", "<Super><Shift> ?");

            view.expand_all ();
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
            window.set_decorated(true);
            window.set_resizable(false);
            window.set_focus_on_map(false);
            window.set_deletable(false);
            window.set_accept_focus(false);
            window.set_type_hint(SPLASHSCREEN);
            window.stick();
        }
    }
}
