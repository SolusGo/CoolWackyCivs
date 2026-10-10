"""Build an independent Ronaldo package; collection registration is separate."""
import hashlib
from pathlib import Path
import shutil
import sys
import zipfile
from xml.etree import ElementTree as ET
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'.tools/python'))
NAME='Cristiano Ronaldo - The Relentless Seven (v 1)'
def manifest():
    root=ET.Element('Mod',id='7ccdb315-1a25-4b24-ae17-777c071d7127',version='1')
    props=ET.SubElement(root,'Properties')
    for k,v in dict(Name='Cristiano Ronaldo - The Relentless Seven',Teaser='Greatness is earned, refined and pursued again.',Description='Player-playable only. Seven Career Chapters, Ambition and veteran reinvention. Requires Brave New World and Community Patch v151.',Authors='SolusGo',AffectsSavedGames='1',MinCompatibleSaveVersion='1',SupportsSinglePlayer='1',SupportsMultiplayer='0',SupportsHotSeat='0',SupportsMac='0',ReloadUnitSystem='0').items():ET.SubElement(props,k).text=v
    deps=ET.SubElement(root,'Dependencies');ET.SubElement(deps,'Mod',id='d1b6328c-ff44-4b0d-aad7-c657f83610cd',minversion='151',maxversion='999',title='Community Patch')
    ET.SubElement(root,'References')
    blocks=ET.SubElement(root,'Blocks');ET.SubElement(blocks,'Mod',id='4c02158d-ad52-4b73-bf2a-555ce58a1e60',minversion='22',maxversion='999',title='Cool Wacky Civs (already includes Ronaldo)')
    files=ET.SubElement(root,'Files')
    for p in sorted((R/'CristianoRonaldo').rglob('*')):
        if p.is_file() and p.suffix in ('.sql','.xml','.lua','.dds'):
            ET.SubElement(files,'File',md5=hashlib.md5(p.read_bytes()).hexdigest().upper(),**{'import':str(int(p.suffix!='.sql' and p.name!='CR7Career.xml'))}).text=p.relative_to(R/'CristianoRonaldo').as_posix()
    actions=ET.SubElement(ET.SubElement(root,'Actions'),'OnModActivated')
    for p in sorted((R/'CristianoRonaldo/SQL').glob('*.sql')):ET.SubElement(actions,'UpdateDatabase').text='SQL/'+p.name
    entries=ET.SubElement(root,'EntryPoints')
    for file,title in [('Lua/CR7Runtime.lua','CR7 Gameplay'),('UI/CR7Career.xml','CR7 Career')]:
        e=ET.SubElement(entries,'EntryPoint',type='InGameUIAddin',file=file);ET.SubElement(e,'Name').text=title;ET.SubElement(e,'Description').text=title
    ET.indent(root,'  ')
    path=R/'CristianoRonaldo'/f'{NAME}.modinfo'
    path.write_bytes(ET.tostring(root,encoding='utf-8',xml_declaration=True).replace(b'\r\n',b'\n'))
    return path
def build():
    m=manifest();out=R/'dist'/NAME
    resolved=out.resolve();dist=(R/'dist').resolve()
    if resolved.parent!=dist or dist.parent!=R.resolve():raise ValueError('Unsafe standalone output path')
    if out.exists():shutil.rmtree(out)
    out.mkdir(parents=True,exist_ok=True)
    for node in ET.parse(m).findall('Files/File'):
        dest=out/node.text;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(m.parent/node.text,dest)
    shutil.copy2(m,out/m.name);shutil.copy2(m.parent/'README.md',out/'README.md')
    for doc in (m.parent/'docs').glob('*.md'):
        dest=out/'docs'/doc.name;dest.parent.mkdir(exist_ok=True);shutil.copy2(doc,dest)
    paths=sorted(p for p in out.rglob('*') if p.is_file())
    with zipfile.ZipFile(R/'dist'/f'{NAME}.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in paths:z.write(p,f'{NAME}/{p.relative_to(out).as_posix()}')
    import py7zr
    native=R/'dist'/f'{NAME}.civ5mod'
    with py7zr.SevenZipFile(native,'w',filters=[{'id':py7zr.FILTER_LZMA}]) as z:
        for p in paths:z.write(p,p.relative_to(out).as_posix())
    with py7zr.SevenZipFile(native,'r') as z:assert z.testzip() is None
    print(out);print(native)
if __name__=='__main__':build()
