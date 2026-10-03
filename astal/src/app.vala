class App : Astal.Application {
    public static App instance;

    // Handles `astal -i astal-shell <msg>`.
    public override void request(string msg, SocketConnection conn) {
        AstalIO.write_sock.begin(conn, @"unknown request: $msg");
    }

    public override void activate() {
        apply_css(STYLE, false);
        foreach (var mon in this.monitors)
            add_window(new Bar(mon));
    }

    construct {
        instance_name = "astal-shell";
        try {
            acquire_socket();
        } catch (Error e) {
            printerr("%s\n", e.message);
        }
        instance = this;
    }

    public static int main(string[] args) {
        return new App().run(null);
    }
}
