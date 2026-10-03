class Workspaces : Gtk.Box {
    AstalHyprland.Hyprland hypr = AstalHyprland.get_default();

    public Workspaces() {
        Astal.widget_set_class_names(this, { "Workspaces" });
        hypr.notify["workspaces"].connect(sync);
        hypr.notify["focused-workspace"].connect(sync);
        sync();
    }

    void sync() {
        foreach (var child in get_children())
            child.destroy();

        var workspaces = hypr.workspaces.copy();
        workspaces.sort((a, b) => a.id - b.id);

        foreach (var ws in workspaces) {
            // Skip special (scratchpad) workspaces, which have negative ids.
            if (ws.id < 1)
                continue;
            add(button(ws));
        }
    }

    Gtk.Button button(AstalHyprland.Workspace ws) {
        var btn = new Gtk.Button.with_label(ws.id.to_string()) { visible = true };
        if (hypr.focused_workspace == ws)
            btn.get_style_context().add_class("focused");
        btn.clicked.connect(() => ws.focus());
        return btn;
    }
}
