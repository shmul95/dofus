# dofus

A tiny Nix flake that installs a `dofus` command which runs the Ankama launcher through Wine in an isolated prefix.

## What it does

- adds a `dofus` command to your PATH when installed as a Nix profile package
- uses `wineWowPackages.stable` + `winetricks`
- stores the Wine prefix in `~/.local/state/dofus/prefix`
- launches `AnkamaLauncher.exe` if it exists in the prefix

## Install

```bash
nix profile install github:shmul95/dofus
# or, depending on your nix version:
# nix profile add github:shmul95/dofus
```

## Run

```bash
dofus
```

## First run

The first run initializes the Wine prefix. If the Ankama Launcher is not already installed, the wrapper now downloads the official Windows installer from Ankama and runs it automatically.

It also registers the `ankama-launcher://` URI handler locally so the browser-to-launcher login handoff can return to the Wine launcher.

You can override the installer source if needed:

```bash
export DOFUS_INSTALLER_URL=https://download.ankama.com/launcher/full/win
# or point at a local .exe:
export DOFUS_INSTALLER_PATH="$HOME/Downloads/AnkamaLauncherSetup.exe"
```

If your launcher ends up somewhere else, point the wrapper at it:

```bash
export DOFUS_LAUNCHER_EXE="$HOME/.local/state/dofus/prefix/drive_c/Program Files (x86)/Ankama/Launcher/AnkamaLauncher.exe"
dofus
```

## Notes

This repo is intentionally minimal. If you want, the next step is to add helper commands like:

- `dofus reset` — recreate the prefix
- `dofus install` — open the launcher download page
- `dofus debug` — launch with verbose Wine logging
