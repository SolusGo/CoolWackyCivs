"""Register Paradise in the collection; preserve pre-existing project edits.

The optional --commit-project also prepares a HEAD-based file for staging only
this task's project changes, leaving the user's existing formatting/folders local.
"""
from pathlib import Path
import argparse
import subprocess
R=Path(__file__).resolve().parents[1]

def update(content):
    if 'TheBoyWhoTouchedParadise/Lua/ParadiseRuntime.lua' in content:return content
    content=content.replace('<ModVersion>23</ModVersion>','<ModVersion>24</ModVersion>')
    content=content.replace('Seventeen civilizations. Seventeen stranger ways to rule.','Eighteen civilizations. Eighteen stranger ways to rule.')
    content=content.replace('and The Relentless Seven. Requires','The Relentless Seven, and The Boy Who Touched Paradise. Requires')
    sql=sorted((R/'TheBoyWhoTouchedParadise/SQL').glob('*.sql'))
    actions=''
    for path in sql:
        actions+='      <Action>\n        <Set>OnModActivated</Set>\n        <Type>UpdateDatabase</Type>\n        <FileName>'+path.relative_to(R).as_posix()+'</FileName>\n      </Action>\n'
    content=content.replace('    </ModActions>',actions+'    </ModActions>')
    entries=''
    for file,name,desc in [('Lua/ParadiseRuntime.lua','Paradise Gameplay','The Boy Who Touched Paradise independent gameplay runtime'),
                           ('UI/ParadiseJourney.xml','The Journey','Paradise event-driven Journey and illustrated finale')]:
        entries+='      <Content>\n        <Type>InGameUIAddin</Type>\n        <Name>'+name+'</Name>\n        <Description>'+desc+'</Description>\n        <FileName>TheBoyWhoTouchedParadise/'+file+'</FileName>\n      </Content>\n'
    content=content.replace('    </ModContent>',entries+'    </ModContent>')
    group='  <ItemGroup>\n'
    for path in sorted((R/'TheBoyWhoTouchedParadise').rglob('*')):
        if not path.is_file() or path.suffix.lower() not in ('.sql','.lua','.xml','.dds'):continue
        name=path.relative_to(R).as_posix()
        imported=path.suffix.lower()!='.sql' and name!='TheBoyWhoTouchedParadise/UI/ParadiseJourney.xml'
        group+='    <Content Include="'+name+'"><ImportIntoVFS>'+str(imported)+'</ImportIntoVFS></Content>\n'
    for folder in ('','Art/','Lua/','SQL/','UI/'):
        group+='    <Folder Include="TheBoyWhoTouchedParadise/'+folder+'" />\n'
    group+='  </ItemGroup>\n'
    return content.replace('</Project>',group+'</Project>')

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--commit-project',action='store_true');args=parser.parse_args()
    path=R/'CoolWackyCivs.civ5proj'
    path.write_text(update(path.read_text(encoding='utf-8-sig')),encoding='utf-8')
    if args.commit_project:
        original=subprocess.run(['git','show','HEAD:CoolWackyCivs.civ5proj'],cwd=R,capture_output=True,check=True).stdout.decode('utf-8-sig')
        (R/'.tools/paradise-commit.civ5proj').write_text(update(original),encoding='utf-8')
    print('Registered Paradise SQL, gameplay/UI add-ins, finished DDS and collection v24.')

if __name__=='__main__':main()
