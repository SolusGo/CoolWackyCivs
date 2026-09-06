"""Build the ModBuddy project's exact content without requiring Visual Studio.

The .civ5proj is the single source of truth for files, VFS flags, database
actions, dependencies and entry points. Output is confined to this repo's dist/.
"""
from __future__ import annotations

import argparse
import hashlib
import shutil
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

REPO = Path(__file__).resolve().parents[1]
ROOT = REPO / "TerraFramework"
PROJECT = ROOT / "TerraFramework.civ5proj"
NS = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}
sys.path.insert(0, str(REPO / ".tools" / "python"))


def read_project():
    tree = ET.parse(PROJECT)
    props = tree.find("m:PropertyGroup", NS)
    values = {e.tag.split("}")[-1]: (e.text or "").strip() for e in props}
    files = []
    for element in tree.findall("m:ItemGroup/m:Content", NS):
        relative = element.attrib["Include"].replace("\\", "/")
        path = (ROOT / relative).resolve()
        if not path.is_relative_to(ROOT.resolve()):
            raise ValueError(f"Project content escapes the mod directory: {relative}")
        imported = element.findtext("m:ImportIntoVFS", "False", NS).lower() == "true"
        files.append((relative, imported))
    return tree, props, values, files


def create_manifest() -> ET.ElementTree:
    _, props, values, files = read_project()
    root = ET.Element("Mod", id=values["Guid"], version=values["ModVersion"])
    properties = ET.SubElement(root, "Properties")
    names = ("Name", "Teaser", "Description", "Authors", "SpecialThanks", "Homepage",
             "AffectsSavedGames", "MinCompatibleSaveVersion", "SupportsSinglePlayer",
             "SupportsMultiplayer", "SupportsHotSeat", "SupportsMac", "ReloadAudioSystem",
             "ReloadLandmarkSystem", "ReloadStrategicViewSystem", "ReloadUnitSystem", "HideSetupGame")
    for name in names:
        value = values.get(name, "")
        if value in ("true", "false"):
            value = "1" if value == "true" else "0"
        ET.SubElement(properties, name).text = value
    for project_tag, output_tag in (("ModDependencies", "Dependencies"), ("ModReferences", "References"), ("ModBlockers", "Blocks")):
        group = ET.SubElement(root, output_tag)
        for association in props.findall(f"m:{project_tag}/m:Association", NS):
            fields = {e.tag.split("}")[-1]: e.text for e in association}
            attrs = {"id": fields["Id"], "minversion": fields.get("MinVersion", "0"), "maxversion": fields.get("MaxVersion", "999")}
            if fields.get("Name"):
                attrs["title"] = fields["Name"]
            ET.SubElement(group, fields["Type"], attrs)
    file_group = ET.SubElement(root, "Files")
    for relative, imported in files:
        source = ROOT / relative
        if not source.is_file():
            raise FileNotFoundError(f"Missing project content: {source}")
        attrs = {"md5": hashlib.md5(source.read_bytes()).hexdigest(), "import": str(int(imported))}
        ET.SubElement(file_group, "File", attrs).text = relative.replace("/", "\\")
    actions = ET.SubElement(root, "Actions")
    action_sets = {}
    for action in props.findall("m:ModActions/m:Action", NS):
        fields = {e.tag.split("}")[-1]: e.text for e in action}
        if fields["Set"] not in action_sets:
            action_sets[fields["Set"]] = ET.SubElement(actions, fields["Set"])
        ET.SubElement(action_sets[fields["Set"]], fields["Type"]).text = fields["FileName"].replace("/", "\\")
    entry_points = ET.SubElement(root, "EntryPoints")
    for content in props.findall("m:ModContent/m:Content", NS):
        fields = {e.tag.split("}")[-1]: e.text for e in content}
        entry = ET.SubElement(entry_points, "EntryPoint", type=fields["Type"], file=fields["FileName"].replace("/", "\\"))
        ET.SubElement(entry, "Name").text = fields["Name"]
        ET.SubElement(entry, "Description").text = fields["Description"]
    ET.indent(root, "  ")
    return ET.ElementTree(root)


def package_name() -> str:
    values = read_project()[2]
    return f"{values['SafeName']} (v {values['ModVersion']})"


def sync_manifest() -> Path:
    manifest = ROOT / f"{package_name()}.modinfo"
    create_manifest().write(manifest, encoding="utf-8", xml_declaration=True)
    return manifest


def build() -> tuple[Path, Path, Path]:
    manifest = sync_manifest()
    dist = (REPO / "dist").resolve()
    output = (dist / package_name()).resolve()
    # Recursive replacement is allowed only for this exact generated child.
    if output.parent != dist or dist.parent != REPO.resolve():
        raise ValueError("Unsafe package output directory")
    dist.mkdir(exist_ok=True)
    if output.exists():
        shutil.rmtree(output)
    output.mkdir()
    files = read_project()[3]
    for relative, _ in files:
        destination = output / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, destination)
    shutil.copy2(manifest, output / manifest.name)
    packaged_files = sorted(p for p in output.rglob("*") if p.is_file())
    archive = dist / f"{package_name()}.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as package:
        for path in packaged_files:
            package.write(path, f"{output.name}/{path.relative_to(output).as_posix()}")
    try:
        import py7zr
    except ImportError as error:
        raise RuntimeError("Install requirements-dev.txt for .civ5mod packaging; the ZIP/folder were built.") from error
    native = dist / f"{package_name()}.civ5mod"
    # Firaxis' original extractor supports LZMA; avoid newer LZMA2/BCJ filters.
    with py7zr.SevenZipFile(native, "w", filters=[{"id": py7zr.FILTER_LZMA}]) as package:
        for path in packaged_files:
            package.write(path, path.relative_to(output).as_posix())
    with py7zr.SevenZipFile(native, "r") as package:
        assert set(package.getnames()) == {p.relative_to(output).as_posix() for p in packaged_files}
        assert package.testzip() is None, "Native package integrity test failed"
    return output, archive, native


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest-only", action="store_true", help="Refresh the checked-in .modinfo only")
    args = parser.parse_args()
    if args.manifest_only:
        print(sync_manifest())
    else:
        for path in build():
            print(path)


if __name__ == "__main__":
    main()
