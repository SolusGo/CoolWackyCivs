"""Build The Shattered Empire standalone, without ModBuddy."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib,sys,zipfile
R=Path(__file__).resolve().parents[1];V=R/'TheShatteredEmpire'
sys.path.insert(0,str(R/'.tools/python'))


def manifest():
    root=ET.Element('Mod',id='2d60f3f0-882e-44d2-bdb6-0ef17a31343b',version='1')
    props=ET.SubElement(root,'Properties')
    for name,value in {'Name':'The Shattered Empire','Teaser':'Conquering the world was never the difficult part. Keeping it was.','Description':'Governors, legions, succession and civil wars for BNW and Community Patch v151.','Authors':'SolusGo','AffectsSavedGames':'1','MinCompatibleSaveVersion':'1','SupportsSinglePlayer':'1','SupportsMultiplayer':'0','SupportsHotSeat':'0','SupportsMac':'0','ReloadAudioSystem':'0','ReloadLandmarkSystem':'0','ReloadStrategicViewSystem':'0','ReloadUnitSystem':'0'}.items(): ET.SubElement(props,name).text=value
    deps=ET.SubElement(root,'Dependencies')
    ET.SubElement(deps,'Dlc',id='6DA07636-4123-4018-B643-6575B4EC336B',minversion='0',maxversion='999',title='Expansion - Brave New World')
    ET.SubElement(deps,'Mod',id='d1b6328c-ff44-4b0d-aad7-c657f83610cd',minversion='151',maxversion='999',title='(1) Community Patch')
    ET.SubElement(root,'References');blocks=ET.SubElement(root,'Blocks')
    ET.SubElement(blocks,'Mod',id='4c02158d-ad52-4b73-bf2a-555ce58a1e60',minversion='20',maxversion='999',title='Cool Wacky Civs includes The Shattered Empire')
    files=ET.SubElement(root,'Files')
    for p in sorted(V.rglob('*')):
        if not p.is_file() or p.suffix not in ['.sql','.lua','.xml','.dds']: continue
        imported=p.suffix!='.sql' and p.name!='ImperialAdministration.xml'
        ET.SubElement(files,'File',md5=hashlib.md5(p.read_bytes()).hexdigest().upper(),**{'import':str(int(imported))}).text=p.relative_to(V).as_posix()
    actions=ET.SubElement(ET.SubElement(root,'Actions'),'OnModActivated')
    for p in sorted((V/'SQL').glob('*.sql')): ET.SubElement(actions,'UpdateDatabase').text=p.relative_to(V).as_posix()
    entry=ET.SubElement(ET.SubElement(root,'EntryPoints'),'EntryPoint',type='InGameUIAddin',file='UI/ImperialAdministration.xml')
    ET.SubElement(entry,'Name').text='Imperial Administration';ET.SubElement(entry,'Description').text='Gameplay owner, AI politics and event-driven administration screen.'
    ET.indent(root,'  ');return ET.ElementTree(root)


def main():
    path=V/'The Shattered Empire (v 1).modinfo';tree=manifest();tree.write(path,encoding='utf-8',xml_declaration=True)
    if '--manifest-only' in sys.argv: print(path);return
    out=R/'dist';out.mkdir(exist_ok=True);files=[V/e.text for e in tree.findall('Files/File')]+[path]
    for p in [V/'README.md',V/'CHANGELOG.md',V/'docs/Validation.md',V/'docs/Implementation.md']: files.append(p)
    archive=out/'The Shattered Empire (v 1).zip'
    with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED) as z:
        for p in files: z.write(p,'The Shattered Empire (v 1)/'+p.relative_to(V).as_posix())
    import py7zr
    native=out/'The Shattered Empire (v 1).civ5mod'
    with py7zr.SevenZipFile(native,'w',filters=[{'id':py7zr.FILTER_LZMA}]) as z:
        for p in files: z.write(p,p.relative_to(V).as_posix())
    with py7zr.SevenZipFile(native,'r') as z: assert z.testzip() is None
    print(archive);print(native)


if __name__=='__main__': main()
