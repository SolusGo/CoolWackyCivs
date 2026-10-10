"""Append Last City registration without reformatting the existing project."""
from pathlib import Path
import sys
R=Path(__file__).resolve().parents[1]

def integrate(text):
    if 'TheLastCity/UI/SanctuaryCouncil.xml' in text:return text
    text=text.replace('<ModVersion>20</ModVersion>','<ModVersion>21</ModVersion>')
    text=text.replace('Fifteen civilizations. Fifteen stranger ways to rule.','Sixteen civilizations. Sixteen stranger ways to rule.')
    text=text.replace('The Sol Intellect, and The Shattered Empire. Requires','The Sol Intellect, The Shattered Empire, and The Last City. Requires')
    actions=''
    for p in sorted((R/'TheLastCity/SQL').glob('*.sql')):
        actions+=f'      <Action><Set>OnModActivated</Set><Type>UpdateDatabase</Type><FileName>TheLastCity/SQL/{p.name}</FileName></Action>\n'
    text=text.replace('    </ModActions>',actions+'    </ModActions>')
    text=text.replace('    </ModContent>','      <Content><Type>InGameUIAddin</Type><FileName>TheLastCity/UI/SanctuaryCouncil.xml</FileName><Name>Sanctuary Council</Name><Description>Last City survival and management interface</Description></Content>\n    </ModContent>')
    content='  <ItemGroup>\n'
    for p in sorted((R/'TheLastCity').rglob('*')):
        if not p.is_file() or p.suffix not in ['.sql','.lua','.xml','.dds']:continue
        relative=p.relative_to(R).as_posix();imported=p.suffix!='.sql' and p.name!='SanctuaryCouncil.xml'
        content+=f'    <Content Include="{relative}"><SubType>{p.suffix[1:].upper() if p.suffix!=".lua" else "Lua"}</SubType><ImportIntoVFS>{str(imported)}</ImportIntoVFS></Content>\n'
    content+='  </ItemGroup>\n'
    text=text.replace('</Project>',content+'</Project>')
    return text

if __name__=='__main__':
    path=Path(sys.argv[1]) if len(sys.argv)>1 else R/'CoolWackyCivs.civ5proj'
    # Retain existing BOM and whitespace; registration is appended surgically.
    with path.open('r',encoding='utf-8',newline='') as f:text=f.read()
    with path.open('w',encoding='utf-8',newline='') as f:f.write(integrate(text))
