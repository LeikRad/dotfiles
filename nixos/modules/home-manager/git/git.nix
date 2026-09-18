{
    pkgs,
    lib,
    ...
}: let
    name = "LeikRad";
in {
    programs.git = {
        enable = true;
        settings.user = {
            email = "bernardo.figueiredo17.102@gmail.com";
            name = name;
        };
    };
    programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*" = {
            ForwardAgent = false;
            AddKeysToAgent = "yes";
            Compression = false;
            ServerAliveInterval = 0;
            ServerAliveCountMax = 3;
            HashKnownHosts = false;
            UserKnownHostsFile = "~/.ssh/known_hosts";
            ControlMaster = "no";
            ControlPath = "~/.ssh/master-%r@%n:%p";
            ControlPersist = "no";
        };
    };
    services.ssh-agent = {
        enable = lib.modules.mkIf pkgs.stdenv.hostPlatform.isLinux true;
    };
}