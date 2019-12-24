using Gtk;

class MyCellRenderer : CellRenderer {

    /* icon property set by the tree column */
    public Gdk.Pixbuf icon { get; set; }

    public MyCellRenderer () {
        GLib.Object ();
    }

    /* get_size method, always request a 50x50 area */
    public override void get_size (Widget widget, Gdk.Rectangle? cell_area,
                                   out int x_offset, out int y_offset,
                                   out int width, out int height)
    {
        x_offset = 0;
        y_offset = 0;
        width = 50;
        height = 50;
    }

    /* render method */
    public override void render (Cairo.Context ctx, Widget widget,
                                 Gdk.Rectangle background_area,
                                 Gdk.Rectangle cell_area,
                                 CellRendererState flags)
    {
        Gdk.cairo_rectangle (ctx, background_area);
        if (icon != null) {
            /* draw a pixbuf on a cairo context */
            Gdk.cairo_set_source_pixbuf (ctx, icon,
                                         background_area.x,
                                         background_area.y);
            ctx.fill ();
        }
    }
}

Gdk.Pixbuf open_image () {
    try {
        return new Gdk.Pixbuf.from_file ("/usr/share/pixmaps/debian-logo.png");
    } catch (Error e) {
        error ("%s", e.message);
    }
}

int main (string[] args) {
    Gtk.init (ref args);

    var tv = new TreeView ();
    var tm = new Gtk.ListStore (2, typeof (Gdk.Pixbuf), typeof (string));
    tv.set_model (tm);

    var renderer = new MyCellRenderer ();
    var col = new TreeViewColumn ();
    col.pack_start (renderer, true);
    col.set_title ("1st column");
    col.add_attribute (renderer, "icon", 0);

    TreeIter ti;
    tm.append (out ti);
    tv.append_column (col);

    var pixbuf = open_image ();
    tm.set (ti, 0, pixbuf, 1, "asd", -1); 
    col.add_attribute (renderer, "icon", 0);

    var win = new Window ();
    win.set_default_size (400, 100);
    win.destroy.connect (Gtk.main_quit);
    win.add (tv);
    win.show_all ();
    Gtk.main ();

    return 0;
}