"""Add CR7 registration while preserving existing ModBuddy formatting."""
from pathlib import Path
import sys
R=Path(__file__).resolve().parents[1]
def integrate(text):
    if 'CristianoRonaldo/UI/CR7Career.xml' in text:return text
    text=text.replace('<ModVersion>21</ModVersion>','<ModVersion>22</ModVersion>')
    text=text.replace('Sixteen civilizations. Sixteen stranger ways to rule.','Seventeen civilizations. Seventeen stranger ways to rule.')
    text=text.replace('The Shattered Empire, and The Last City. Requires','The Shattered Empire, The Last City, and The Relentless Seven. Requires')
    actions=''.join(f'      <Action><Set>OnModActivated</Set><Type>UpdateDatabase</Type><FileName>{p.relative_to(R).as_posix()}</FileName></Action>\n' for p in sorted((R/'CristianoRonaldo/SQL').glob('*.sql')))
    text=text.replace('    </ModActions>',actions+'    </ModActions>')
    entries=''
    for filename,name in [('Lua/CR7Runtime.lua','Relentless Seven Gameplay'),('UI/CR7Career.xml','CR7 Ambition and Career')]:
        entries+=f'      <Content><Type>InGameUIAddin</Type><Name>{name}</Name><Description>{name}</Description><FileName>CristianoRonaldo/{filename}</FileName></Content>\n'
    text=text.replace('    </ModContent>',entries+'    </ModContent>')
    content='  <ItemGroup>\n'
    for p in sorted((R/'CristianoRonaldo').rglob('*')):
        if not p.is_file() or p.suffix not in ('.sql','.lua','.xml','.dds'):continue
        relative=p.relative_to(R).as_posix()
        imported=p.suffix!='.sql' and p.name!='CR7Career.xml'
        content+=f'    <Content Include="{relative}"><ImportIntoVFS>{str(imported)}</ImportIntoVFS></Content>\n'
    return text.replace('</Project>',content+'  </ItemGroup>\n</Project>')
if __name__=='__main__':
    path=Path(sys.argv[1]) if len(sys.argv)>1 else R/'CoolWackyCivs.civ5proj'
    with path.open('r',encoding='utf-8',newline='') as f:source=f.read()
    with path.open('w',encoding='utf-8',newline='') as f:f.write(integrate(source))
