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

The first run initializes the Wine prefix. You still need to install the Ankama launcher / Dofus game into that prefix, because the game itself is proprietary and cannot be bundled into the Nix package.

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
