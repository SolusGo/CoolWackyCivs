"""Check entry points with the real Firaxis manifest task, when SDK is installed."""
from pathlib import Path
from xml.etree import ElementTree as ET
import os
import subprocess

R = Path(__file__).resolve().parents[1]
NS = 'http://schemas.microsoft.com/developer/msbuild/2003'
ET.register_namespace('', NS)


def check():
    msbuild = Path(os.environ.get('WINDIR', 'C:/Windows')) / 'Microsoft.NET/Framework/v4.0.30319/MSBuild.exe'
    sdk = Path(os.environ.get('ProgramFiles(x86)', 'C:/Program Files (x86)')) / 'MSBuild/Firaxis/ModBuddy'
    task = sdk / 'ModBuddy.Civ5ModBuildTasks.dll'
    if not msbuild.is_file() or not task.is_file():
        print('SKIP real ModBuddy entry-point check: Firaxis SDK/MSBuild unavailable')
        return
    target = R / '.tools/modbuddy-entrypoints'
    target.mkdir(parents=True, exist_ok=True)
    source = ET.parse(R / 'CoolWackyCivs.civ5proj').getroot()
    props = source.find(f'{{{NS}}}PropertyGroup')
    current = ET.Element(f'{{{NS}}}Project', ToolsVersion='4.0', DefaultTargets='Manifest')
    ET.SubElement(current, f'{{{NS}}}UsingTask',
        TaskName='Firaxis.ModBuddy.Civ5ModBuildTasks.GenerateModInfo', AssemblyFile=str(task))
    current.append(props)
    group = ET.SubElement(current, f'{{{NS}}}ItemGroup')
    for content in source.findall(f'{{{NS}}}ItemGroup/{{{NS}}}Content'):
        item = ET.SubElement(group, f'{{{NS}}}ModFiles', Include=content.get('Include'))
        ET.SubElement(item, f'{{{NS}}}TargetPath').text = str(R / content.get('Include'))
        ET.SubElement(item, f'{{{NS}}}ImportIntoVFS').text = content.findtext(f'{{{NS}}}ImportIntoVFS', 'False')
    output = target / 'native.modinfo'
    command = ET.SubElement(ET.SubElement(current, f'{{{NS}}}Target', Name='Manifest'), f'{{{NS}}}GenerateModInfo',
        ID='$(Guid)', Version='$(ModVersion)', Content='$(ModContent)', Actions='$(ModActions)',
        Dependencies='$(ModDependencies)', References='$(ModReferences)', Blocks='$(ModBlockers)',
        CustomProperties='$(ModProperties)', ProjectFiles='@(ModFiles)', Files='@(ModFiles)',
        TargetPath=str(output))
    for name in ('Name', 'Teaser', 'Description', 'Authors', 'SpecialThanks', 'Homepage',
                 'AffectsSavedGames', 'MinCompatibleSaveVersion', 'ReloadAudioSystem',
                 'ReloadLandmarkSystem', 'ReloadUnitSystem', 'ReloadStrategicViewSystem',
                 'SupportsSinglePlayer', 'SupportsMultiplayer', 'SupportsHotSeat',
                 'SupportsMac', 'HideSetupGame'):
        command.set(name, f'$({name})')
    driver = target / 'manifest.proj'
    ET.ElementTree(current).write(driver, encoding='utf-8', xml_declaration=True)
    result = subprocess.run([str(msbuild), str(driver), '/t:Manifest', '/nologo', '/verbosity:minimal'],
                            cwd=R, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError('Native ModBuddy manifest generation failed:\n' + result.stdout + result.stderr)
    from build_mod import package_name
    expected = ET.parse(R / f'{package_name()}.modinfo').getroot()
    native = ET.parse(output).getroot()
    signature = lambda root: [(e.get('type'), e.findtext('Name'), e.findtext('Description'),
                               e.get('file', '').replace('\\', '/')) for e in root.findall('EntryPoints/EntryPoint')]
    assert signature(native) == signature(expected), 'Firaxis/Python entry-point manifests disagree'
    for entry in native.findall('EntryPoints/EntryPoint'):
        filename = entry.get('file', '').replace('\\', '/')
        assert (R / filename).is_file(), f'Native loader would fail to resolve {filename}'
    print(f'PASS real Firaxis ModBuddy manifest task: all {len(signature(native))} entry points resolve and match the Python package')


if __name__ == '__main__':
    check()
