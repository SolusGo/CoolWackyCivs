"""Append Last City registration without reformatting the existing project."""
from pathlib import Path
import sys
import re
R=Path(__file__).resolve().parents[1]
COUNCIL_ENTRY='<Content><Type>InGameUIAddin</Type><Name>Sanctuary Council</Name><Description>Last City survival and management interface</Description><FileName>TheLastCity/UI/SanctuaryCouncil.xml</FileName></Content>'

def integrate(text):
    if 'TheLastCity/UI/SanctuaryCouncil.xml' in text:
        # ModBuddy reads these fields positionally: Type, Name, Description,
        # FileName. The old Type/FileName/Name/Description order made it export
        # the description as the entry-point filename and stop InGame loading.
        text=re.sub(r'<Content>(?:(?!</Content>).)*TheLastCity/UI/SanctuaryCouncil.xml(?:(?!</Content>).)*</Content>',COUNCIL_ENTRY,text,flags=re.S)
        for p in sorted((R/'TheLastCity/SQL').glob('*.sql')):
            relative=p.relative_to(R).as_posix()
            if f'<FileName>{relative}</FileName>' not in text:
                action=f'      <Action><Set>OnModActivated</Set><Type>UpdateDatabase</Type><FileName>{relative}</FileName></Action>\n'
                text=text.replace('    </ModActions>',action+'    </ModActions>')
            if f'Include="{relative}"' not in text:
                entry=f'  <ItemGroup>\n    <Content Include="{relative}"><SubType>SQL</SubType><ImportIntoVFS>False</ImportIntoVFS></Content>\n  </ItemGroup>\n'
                text=text.replace('</Project>',entry+'</Project>')
        pattern=re.compile(r'(?m)^[ \t]*<Action>\s*<Set>OnModActivated</Set>\s*<Type>UpdateDatabase</Type>\s*<FileName>(TheLastCity/SQL/[^<]+)</FileName>\s*</Action>[ \t]*(?:\r?\n)?')
        ordered=iter(m.group(0) for m in sorted(pattern.finditer(text),key=lambda m:m.group(1)))
        text=pattern.sub(lambda _:next(ordered),text)
        for p in sorted((R/'TheLastCity/Art').glob('*')):
            if p.suffix not in ('.dds','.xml'):continue
            relative=p.relative_to(R).as_posix()
            if relative not in text:
                entry=f'  <ItemGroup>\n    <Content Include="{relative}"><SubType>{p.suffix[1:].upper()}</SubType><ImportIntoVFS>True</ImportIntoVFS></Content>\n  </ItemGroup>\n'
                text=text.replace('</Project>',entry+'</Project>')
        return text
    text=text.replace('<ModVersion>20</ModVersion>','<ModVersion>21</ModVersion>')
    text=text.replace('Fifteen civilizations. Fifteen stranger ways to rule.','Sixteen civilizations. Sixteen stranger ways to rule.')
    text=text.replace('The Sol Intellect, and The Shattered Empire. Requires','The Sol Intellect, The Shattered Empire, and The Last City. Requires')
    actions=''
    for p in sorted((R/'TheLastCity/SQL').glob('*.sql')):
        actions+=f'      <Action><Set>OnModActivated</Set><Type>UpdateDatabase</Type><FileName>TheLastCity/SQL/{p.name}</FileName></Action>\n'
    text=text.replace('    </ModActions>',actions+'    </ModActions>')
    text=text.replace('    </ModContent>','      '+COUNCIL_ENTRY+'\n    </ModContent>')
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
