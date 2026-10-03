// GTK3 CSS, applied once at startup.
const string STYLE = """
window.Bar {
    background: rgba(30, 30, 46, 0.9);
    color: #cdd6f4;
    font-weight: bold;
}

.Bar > box {
    padding: 2px 8px;
}

.Workspaces button {
    all: unset;
    min-width: 20px;
    padding: 0 4px;
    color: #6c7086;
}

.Workspaces button.focused {
    color: #cba6f7;
}

.Battery {
    margin-left: 8px;
}
""";
