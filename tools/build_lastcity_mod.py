"""Build The Last City standalone (.modinfo, ZIP, Civ5Mod), no ModBuddy."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib,sys,zipfile
R=Path(__file__).resolve().parents[1];V=R/'TheLastCity'
sys.path.insert(0,str(R/'.tools/python'))

def manifest():
    root=ET.Element('Mod',id='991b478d-3f9d-4de2-a021-150fa63b800d',version='1')
    props=ET.SubElement(root,'Properties')
    values={'Name':'The Last City — Humanity\'s Final Refuge','Teaser':'When the world fell, one city refused to die.',
     'Description':'One-city survival, refugees, provisions, rationing, morale, invasions and the Sanctuary Council. Requires BNW and Community Patch v151.',
     'Authors':'SolusGo','AffectsSavedGames':'1','MinCompatibleSaveVersion':'1','SupportsSinglePlayer':'1',
     'SupportsMultiplayer':'0','SupportsHotSeat':'0','SupportsMac':'0','ReloadAudioSystem':'0',
     'ReloadLandmarkSystem':'0','ReloadStrategicViewSystem':'0','ReloadUnitSystem':'0'}
    for key,value in values.items():ET.SubElement(props,key).text=value
    deps=ET.SubElement(root,'Dependencies')
    ET.SubElement(deps,'Dlc',id='6DA07636-4123-4018-B643-6575B4EC336B',minversion='0',maxversion='999',title='Expansion - Brave New World')
    ET.SubElement(deps,'Mod',id='d1b6328c-ff44-4b0d-aad7-c657f83610cd',minversion='151',maxversion='999',title='(1) Community Patch')
    ET.SubElement(root,'References');blocks=ET.SubElement(root,'Blocks')
    ET.SubElement(blocks,'Mod',id='4c02158d-ad52-4b73-bf2a-555ce58a1e60',minversion='21',maxversion='999',title='Cool Wacky Civs includes The Last City')
    files=ET.SubElement(root,'Files')
    for path in sorted(V.rglob('*')):
        if path.is_file() and path.suffix in ['.sql','.lua','.xml','.dds']:
            imported=path.suffix!='.sql' and path.name!='SanctuaryCouncil.xml'
            ET.SubElement(files,'File',md5=hashlib.md5(path.read_bytes()).hexdigest().upper(),**{'import':str(int(imported))}).text=path.relative_to(V).as_posix()
    actions=ET.SubElement(ET.SubElement(root,'Actions'),'OnModActivated')
    for path in sorted((V/'SQL').glob('*.sql')):ET.SubElement(actions,'UpdateDatabase').text=path.relative_to(V).as_posix()
    entry=ET.SubElement(ET.SubElement(root,'EntryPoints'),'EntryPoint',type='InGameUIAddin',file='UI/SanctuaryCouncil.xml')
    ET.SubElement(entry,'Name').text='Sanctuary Council';ET.SubElement(entry,'Description').text='Single gameplay owner, AI survival and event-driven management interface.'
    ET.indent(root,'  ');return ET.ElementTree(root)

def main():
    path=V/'The Last City (v 1).modinfo';tree=manifest();tree.write(path,encoding='utf-8',xml_declaration=True)
    if '--manifest-only' in sys.argv:print(path);return
    out=R/'dist';out.mkdir(exist_ok=True)
    files=[V/e.text for e in tree.findall('Files/File')]+[path,V/'README.md']+sorted((V/'docs').glob('*.md'))
    archive=out/'The Last City (v 1).zip'
    with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED) as z:
        for p in files:z.write(p,'The Last City (v 1)/'+p.relative_to(V).as_posix())
    import py7zr
    native=out/'The Last City (v 1).civ5mod'
    with py7zr.SevenZipFile(native,'w',filters=[{'id':py7zr.FILTER_LZMA}]) as z:
        for p in files:z.write(p,p.relative_to(V).as_posix())
    with py7zr.SevenZipFile(native,'r') as z:assert z.testzip() is None
    print(archive);print(native)

if __name__=='__main__':main()
