using Gtk;
using Gdk;

public class RemontoireWindow : Gtk.Window {

    public RemontoireWindow () {
    	this.set_skip_taskbar_hint(true);
		this.set_skip_pager_hint(true);
    	this.set_decorated(false);
    	this.set_resizable(false);
    	this.set_default_size(200, 400);
    	//this.set_gravity(NORTH_EAST);
    	this.set_type_hint(DIALOG);
    	this.stick();

        var view = new TreeView ();
        setup_treeview (view);
        add (view);
        this.destroy.connect (Gtk.main_quit);
    }

    private void setup_treeview (TreeView view) {

        var store = new TreeStore (2, typeof (string), typeof (string));
        view.set_model (store);

        view.insert_column_with_attributes (-1, "Product", new CellRendererText (), "text", 0, null);
        view.insert_column_with_attributes (-1, "Price", new CellRendererText (), "text", 1, null);

        //TreeIter root;
        TreeIter category_iter;
        TreeIter product_iter;

        //store.append (out root, null);
        //store.set (root, 0, "All Products", -1);

        store.append (out category_iter, null);
        store.set (category_iter, 0, "Books", -1);

        store.append (out product_iter, category_iter);
        store.set (product_iter, 0, "Moby Dick", 1, "$10.36", -1);
        store.append (out product_iter, category_iter);
        store.set (product_iter, 0, "Heart of Darkness", 1, "$4.99", -1);
        store.append (out product_iter, category_iter);
        store.set (product_iter, 0, "Ulysses", 1, "$26.09", -1);
        store.append (out product_iter, category_iter);
        store.set (product_iter, 0, "Effective Vala", 1, "$38.99", -1);

        store.append (out category_iter, null);
        store.set (category_iter, 0, "Films", -1);

        store.append (out product_iter, category_iter);
        store.set (product_iter, 0, "Amores Perros", 1, "$7.99", -1);
        store.append (out product_iter, category_iter);
        store.set (product_iter, 0, "Twin Peaks", 1, "$14.99", -1);
        store.append (out product_iter, category_iter);
        store.set (product_iter, 0, "Vertigo", 1, "$20.49", -1);

        view.expand_all ();
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        var window = new RemontoireWindow ();

        window.show_all ();

        var gdkWindow = window.get_window();
        var display = Display.get_default();
        var monitor = display.get_monitor_at_window(gdkWindow);
        var geometry = monitor.get_geometry();

        window.move(geometry.width - 230, 10);
        Gtk.main ();

        return 0;
    }
}