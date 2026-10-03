class Battery : Gtk.Box {
    public Battery() {
        Object(spacing: 4);
        Astal.widget_set_class_names(this, { "Battery" });

        var bat = AstalBattery.get_default();
        // Visibility follows is-present (hidden on the desktop), so keep the
        // bar's show_all() from overriding it.
        no_show_all = true;
        var icon = new Gtk.Image() { visible = true };
        var label = new Gtk.Label(null) { visible = true };
        add(icon);
        add(label);

        bat.bind_property("is-present", this, "visible", BindingFlags.SYNC_CREATE);
        bat.bind_property("battery-icon-name", icon, "icon-name", BindingFlags.SYNC_CREATE);
        bat.bind_property(
            "percentage", label, "label", BindingFlags.SYNC_CREATE,
            (binding, from, ref to) => {
                to.set_string(@"$((int) (from.get_double() * 100))%");
                return true;
            }
        );
    }
}
