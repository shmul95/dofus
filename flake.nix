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
          pkgs.curl
          pkgs.findutils
          pkgs.winetricks
          pkgs.wineWowPackages.stable
        ];
        text = ''
          set -euo pipefail

          export WINEPREFIX="''${XDG_STATE_HOME:-$HOME/.local/state}/dofus/prefix"
          export WINEARCH="win64"
          export WINEDEBUG="''${WINEDEBUG:--all}"

          launcher_exe_hint="$WINEPREFIX/drive_c/Program Files (x86)/Ankama/Launcher/AnkamaLauncher.exe";
          install_url="''${DOFUS_INSTALLER_URL:-https://download.ankama.com/launcher/full/win}";
          install_path="''${DOFUS_INSTALLER_PATH:-}";

          find_launcher_exe() {
            if [ -n "''${DOFUS_LAUNCHER_EXE:-}" ] && [ -f "''${DOFUS_LAUNCHER_EXE}" ]; then
              printf '%s\n' "''${DOFUS_LAUNCHER_EXE}"
              return 0
            fi

            for candidate in \
              "$WINEPREFIX/drive_c/Program Files (x86)/Ankama/Launcher/AnkamaLauncher.exe" \
              "$WINEPREFIX/drive_c/Program Files/Ankama/Launcher/AnkamaLauncher.exe"; do
              if [ -f "$candidate" ]; then
                printf '%s\n' "$candidate"
                return 0
              fi
            done

            find "$WINEPREFIX/drive_c" \
              -type f \
              \( -iname 'AnkamaLauncher.exe' -o -iname 'Ankama Launcher.exe' \) \
              2>/dev/null | head -n 1
          }

          ensure_prefix() {
            mkdir -p "$WINEPREFIX"
            if [ ! -f "$WINEPREFIX/.initialized" ]; then
              echo "[dofus] initializing Wine prefix at $WINEPREFIX" >&2
              wineboot -u >/dev/null
              touch "$WINEPREFIX/.initialized"
            fi
          }

          run_launcher() {
            launcher_exe="$(find_launcher_exe || true)"
            if [ -n "$launcher_exe" ]; then
              exec wine "$launcher_exe" "$@"
            fi
          }

          install_launcher() {
            ensure_prefix

            launcher_exe="$(find_launcher_exe || true)"
            if [ -n "$launcher_exe" ]; then
              echo "[dofus] Ankama Launcher already exists at: $launcher_exe" >&2
              exec wine "$launcher_exe" "$@"
            fi

            if [ "$#" -gt 0 ] && [ -f "$1" ]; then
              echo "[dofus] running installer: $1" >&2
              wine "$1" "''${@:2}"
            elif [ -n "$install_path" ] && [ -f "$install_path" ]; then
              echo "[dofus] running installer from DOFUS_INSTALLER_PATH: $install_path" >&2
              wine "$install_path"
            elif [ -n "$install_url" ]; then
              tmpdir="$(mktemp -d)"
              trap 'rm -rf "$tmpdir"' EXIT
              installer="$tmpdir/ankama-installer.exe"
              echo "[dofus] downloading installer from $install_url" >&2
              curl -fL "$install_url" -o "$installer"
              echo "[dofus] running downloaded installer" >&2
              wine "$installer"
            else
              printf '%s\n' \
                'Ankama Launcher is not installed in this Wine prefix yet.' \
                '' \
                "Expected path: $launcher_exe_hint" \
                '' \
                'To install it, either:' \
                '  1. run: dofus install /path/to/AnkamaLauncherSetup.exe' \
                '  2. export DOFUS_INSTALLER_PATH=/path/to/AnkamaLauncherSetup.exe' \
                '  3. export DOFUS_INSTALLER_URL=https://download.ankama.com/launcher/full/win' \
                '' \
                'Once installed, run: dofus' >&2
              exit 1
            fi

            launcher_exe="$(find_launcher_exe || true)"
            if [ -n "$launcher_exe" ]; then
              echo "[dofus] launching Ankama Launcher from: $launcher_exe" >&2
              exec wine "$launcher_exe"
            fi

            printf '%s\n' \
              'The installer finished, but the Ankama Launcher was not found afterward.' \
              '' \
              "Expected path: $launcher_exe_hint" \
              '' \
              'You may need to re-run the launcher manually once it finishes installing, or check the prefix contents.' >&2
            exit 1
          }

          case "''${1:-}" in
            install)
              shift
              install_launcher "$@"
              ;;
            reset)
              rm -rf "$WINEPREFIX"
              echo "[dofus] removed Wine prefix: $WINEPREFIX" >&2
              ;;
            debug)
              shift || true
              export WINEDEBUG="+timestamp,+seh,''${WINEDEBUG:+,$WINEDEBUG}"
              ensure_prefix
              launcher_exe="$(find_launcher_exe || true)"
              if [ -n "$launcher_exe" ]; then
                run_launcher "$@"
                exit 0
              fi
              install_launcher "$@"
              ;;
            "")
              ensure_prefix
              launcher_exe="$(find_launcher_exe || true)"
              if [ -n "$launcher_exe" ]; then
                run_launcher "$@"
                exit 0
              fi
              install_launcher "$@"
              ;;
            *)
              ensure_prefix
              launcher_exe="$(find_launcher_exe || true)"
              if [ -n "$launcher_exe" ]; then
                run_launcher "$@"
                exit 0
              fi
              install_launcher "$@"
              ;;
          esac
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
