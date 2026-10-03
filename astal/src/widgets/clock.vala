class Clock : Gtk.Label {
    string format;
    uint timer;

    public Clock(string format = "%a %d %b  %H:%M") {
        this.format = format;
        timer = Timeout.add_seconds(1, () => {
            sync();
            return Source.CONTINUE;
        });
        destroy.connect(() => Source.remove(timer));
        sync();
    }

    void sync() {
        label = new DateTime.now_local().format(format);
    }
}
