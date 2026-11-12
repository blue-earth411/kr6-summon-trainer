"""Build the optional Vengeance assets from a local Steam installation."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory
import winreg


def steam_libraries():
    roots = []
    for hive, key, value in ((winreg.HKEY_CURRENT_USER, r"Software\Valve\Steam", "SteamPath"),
                             (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath")):
        try:
            with winreg.OpenKey(hive, key) as entry:
                roots.append(Path(winreg.QueryValueEx(entry, value)[0]))
        except OSError:
            continue
    for root in roots:
        yield root
        library_file = root / "steamapps/libraryfolders.vdf"
        if library_file.is_file():
            data = library_file.read_text(encoding="utf-8-sig")
            for path in re.findall(r'"path"\s+"([^"\n]+)"', data):
                yield Path(path.replace("\\\\", "\\"))


def locate_vengeance():
    for library in steam_libraries():
        game = library / "steamapps/common/Kingdom Rush Vengeance"
        if (game / "KR4/Settings/units_settings.plist").is_file():
            return game
    raise ValueError('Vengeance was not found. Pass --game "path to Kingdom Rush Vengeance".')


def install(game, save_dir):
    root = save_dir.resolve() / "kr6_summon_public"
    if not (root / "trainer_public_panel.lua").is_file():
        raise ValueError("Install Summon Trainer first.")
    if not (game / "KR4/Settings/units_settings.plist").is_file():
        raise ValueError(f"Vengeance assets were not found in {game}")
    tools = Path(__file__).resolve().parent / "tools"
    with TemporaryDirectory(prefix=".import-vengeance-", dir=root) as workspace:
        staging = Path(workspace)
        generated = staging / "vengeance"
        for worker, folder in (("extract_vengeance.py", "kr4_import"), ("extract_vengeance_audio.py", "kr4_audio")):
            destination = generated / folder
            destination.mkdir(parents=True)
            subprocess.run([sys.executable, str(tools / worker), str(game), str(destination)], check=True)
        for filename in ("atlas_sizes.json", "source_units.json"):
            (generated / "kr4_import" / filename).unlink(missing_ok=True)
        (generated / "ready.lua").write_text("return true\n", encoding="ascii")
        target = root / "vengeance"
        previous = staging / "previous"
        if target.exists():
            if target.resolve().parent != root.resolve() or not (target / "ready.lua").is_file():
                raise ValueError(f"Unexpected folder at {target}")
            target.rename(previous)
        try:
            generated.rename(target)
        except OSError:
            if previous.exists():
                previous.rename(target)
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game", type=Path)
    parser.add_argument("--save-dir", type=Path, default=Path(os.environ["APPDATA"]) / "kingdom_rush_genesis")
    args = parser.parse_args()
    try:
        import PIL  # noqa: F401
    except ImportError:
        parser.exit(1, "Pillow is required. Run: py -3 -m pip install Pillow\n")
    try:
        install(args.game or locate_vengeance(), args.save_dir)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Import failed: {error}\n")
    print("Vengeance units are ready. Start Genesis from Steam.")


if __name__ == "__main__":
    main()
