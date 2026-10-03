class Bar : Astal.Window {
    public Bar(Gdk.Monitor monitor) {
        Object(
            anchor: Astal.WindowAnchor.TOP
                | Astal.WindowAnchor.LEFT
                | Astal.WindowAnchor.RIGHT,
            exclusivity: Astal.Exclusivity.EXCLUSIVE,
            gdkmonitor: monitor
        );

        Astal.widget_set_class_names(this, { "Bar" });

        var right = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        right.add(new Battery());

        add(new Astal.CenterBox() {
            start_widget = new Workspaces(),
            center_widget = new Clock(),
            end_widget = right,
        });

        show_all();
    }
}
