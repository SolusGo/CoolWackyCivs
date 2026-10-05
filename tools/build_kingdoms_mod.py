"""Build The Kingdoms as a standalone pure-file Civ V mod, without ModBuddy."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib,sys,zipfile
R=Path(__file__).resolve().parents[1];V=R/'TheKingdoms'
sys.path.insert(0,str(R/'.tools/python'))

def manifest():
    root=ET.Element('Mod',id='3df27f59-2b32-43e6-81dc-76e681913a5f',version='1')
    props=ET.SubElement(root,'Properties')
    for name,value in {'Name':'The Kingdoms','Teaser':'Many Houses. One Crown.','Description':'A persistent feudal political civilization for Brave New World and Community Patch.','Authors':'SolusGo','AffectsSavedGames':'1','MinCompatibleSaveVersion':'1','SupportsSinglePlayer':'1','SupportsMultiplayer':'0','SupportsHotSeat':'0','SupportsMac':'0','ReloadAudioSystem':'0','ReloadLandmarkSystem':'0','ReloadStrategicViewSystem':'0','ReloadUnitSystem':'0'}.items():ET.SubElement(props,name).text=value
    deps=ET.SubElement(root,'Dependencies')
    ET.SubElement(deps,'Dlc',id='6DA07636-4123-4018-B643-6575B4EC336B',minversion='0',maxversion='999',title='Expansion - Brave New World')
    ET.SubElement(deps,'Mod',id='d1b6328c-ff44-4b0d-aad7-c657f83610cd',minversion='151',maxversion='999',title='(1) Community Patch')
    ET.SubElement(root,'References');blocks=ET.SubElement(root,'Blocks')
    ET.SubElement(blocks,'Mod',id='4c02158d-ad52-4b73-bf2a-555ce58a1e60',minversion='18',maxversion='999',title='Cool Wacky Civs includes The Kingdoms')
    group=ET.SubElement(root,'Files')
    for p in sorted(V.rglob('*')):
        if not p.is_file() or p.suffix.lower() not in ['.sql','.lua','.xml','.dds']:continue
        imported=p.suffix!='.sql' and p.name!='KingdomsOverview.xml'
        ET.SubElement(group,'File',md5=hashlib.md5(p.read_bytes()).hexdigest().upper(),**{'import':str(int(imported))}).text=p.relative_to(V).as_posix()
    actions=ET.SubElement(ET.SubElement(root,'Actions'),'OnModActivated')
    for p in sorted((V/'SQL').glob('*.sql')):ET.SubElement(actions,'UpdateDatabase').text=p.relative_to(V).as_posix()
    entry=ET.SubElement(ET.SubElement(root,'EntryPoints'),'EntryPoint',type='InGameUIAddin',file='UI/KingdomsOverview.xml')
    ET.SubElement(entry,'Name').text='The Kingdoms Overview';ET.SubElement(entry,'Description').text='Persistent politics, AI simulation and event-driven realm panels.'
    ET.indent(root,'  ');return ET.ElementTree(root)

def main():
    path=V/'The Kingdoms (v 1).modinfo';tree=manifest();tree.write(path,encoding='utf-8',xml_declaration=True)
    if '--manifest-only' in sys.argv:print(path);return
    out=R/'dist';out.mkdir(exist_ok=True)
    files=[V/e.text for e in tree.findall('Files/File')]+[path]
    with zipfile.ZipFile(out/'The Kingdoms (v 1).zip','w',compression=zipfile.ZIP_DEFLATED) as z:
        for p in files:z.write(p,'The Kingdoms (v 1)/'+p.relative_to(V).as_posix())
    import py7zr
    native=out/'The Kingdoms (v 1).civ5mod'
    with py7zr.SevenZipFile(native,'w',filters=[{'id':py7zr.FILTER_LZMA}]) as z:
        for p in files:z.write(p,p.relative_to(V).as_posix())
    with py7zr.SevenZipFile(native,'r') as z:assert z.testzip() is None
    print(native)

if __name__=='__main__':main()
