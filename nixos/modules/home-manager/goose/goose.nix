{ pkgs, lib, ... }:
let
    # Not in nixpkgs. Upstream ships prebuilt binaries only (no source build
    # instructions suitable for a Nix derivation), so we grab the static musl
    # release asset directly - no dynamic linking/patchelf needed.
    goose-cli = pkgs.stdenvNoCC.mkDerivation rec {
        pname = "goose-cli";
        version = "1.52.0";

        src = pkgs.fetchurl {
            url = "https://github.com/aaif-goose/goose/releases/download/v${version}/goose-x86_64-unknown-linux-musl.tar.gz";
            hash = "sha256-/chmUyhaiffcrW52c2rxaIqyzeRGYbCJMosvxAu3n58=";
        };

        dontUnpack = true;

        installPhase = ''
            mkdir -p $out/bin
            tar -xzf $src -O ./goose > $out/bin/goose
            chmod +x $out/bin/goose
        '';

        meta = {
            description = "Local, extensible AI agent for automating engineering tasks";
            homepage = "https://github.com/aaif-goose/goose";
            license = lib.licenses.asl20;
            platforms = [ "x86_64-linux" ];
            mainProgram = "goose";
        };
    };
in {
    home.packages = [ goose-cli ];

    # Points Goose at llama.cpp over Tailscale on the desktop (RX 7800 XT,
    # hostname "azathoth") via Goose's generic OpenAI-compatible provider.
    # No local inference on this machine anymore - the framework's iGPU/CPU
    # llama.cpp setup was removed once the desktop proved faster and more
    # reliable. OPENAI_API_KEY is required by Goose's client but ignored by
    # llama-server (no auth). GOOSE_MODEL is a label only - llama-server
    # always answers with whatever model is actually loaded regardless of
    # what's requested here.
    #
    # Requires: `sudo tailscale up` on this machine, AND llama-server.exe
    # actually running on the desktop with --host 0.0.0.0.
    #
    # Set as env vars rather than ~/.config/goose/config.yaml: Goose's config
    # loader can't resolve home-manager's two-hop Nix-store symlink for that
    # path ("Too many symlink levels (or a cycle)") even though the chain
    # itself resolves fine with readlink/namei - a Goose-side quirk, not an
    # actual cycle. Env vars sidestep its config-file resolution entirely.
    home.sessionVariables = {
        GOOSE_PROVIDER = "openai";
        GOOSE_MODEL = "local";
        OPENAI_HOST = "http://azathoth.tail753c1.ts.net:8080";
        OPENAI_BASE_PATH = "v1/chat/completions";
        OPENAI_API_KEY = "not-needed";
    };
}
