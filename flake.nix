{
  description = "Dofus launcher wrapper for Nix profile installs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      dofus = pkgs.writeShellApplication {
        name = "dofus";
        runtimeInputs = [
          pkgs.cabextract
          pkgs.winetricks
          pkgs.wineWowPackages.stable
        ];
        text = ''
          set -euo pipefail

          export WINEPREFIX="${XDG_STATE_HOME:-$HOME/.local/state}/dofus/prefix"
          export WINEARCH="win64"
          export WINEDEBUG="${WINEDEBUG:--all}"

          launcher_exe="${DOFUS_LAUNCHER_EXE:-$WINEPREFIX/drive_c/Program Files (x86)/Ankama/Launcher/AnkamaLauncher.exe}"

          mkdir -p "$WINEPREFIX"

          if [ ! -f "$WINEPREFIX/.initialized" ]; then
            echo "[dofus] initializing Wine prefix at $WINEPREFIX" >&2
            wineboot -u >/dev/null
            touch "$WINEPREFIX/.initialized"
          fi

          if [ -f "$launcher_exe" ]; then
            exec wine "$launcher_exe" "$@"
          fi

          printf '%s\n' \
            'Dofus launcher not found in this Wine prefix.' \
            '' \
            "Expected path: $launcher_exe" \
            '' \
            'To get started:' \
            '  1. install the Ankama launcher into the prefix above' \
            '  2. optionally set DOFUS_LAUNCHER_EXE if the executable lives elsewhere' \
            '  3. run: dofus' \
            '' \
            "You can inspect or reset the prefix at: $WINEPREFIX" >&2

          exit 1
        '';
      };
    in {
      packages.${system} = {
        inherit dofus;
        default = dofus;
      };

      apps.${system}.default = {
        type = "app";
        program = "${dofus}/bin/dofus";
      };

      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
