"""Reproducible native Civ V UI skins from retained artwork and geometric motifs.

Run from this workspace containing both collections. Gameplay/save code is not
generated here. XML keeps its existing control IDs and panel geometry.
"""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib, json, math, re, shutil, subprocess, tempfile
from PIL import Image, ImageDraw, ImageFilter, ImageOps
from dds_mips import raw_mips

WORKSPACE = Path(__file__).resolve().parents[2]
# folder, colour, motif, presentation title, short in-world guidance
THEMES = [
 ('CoolWackyCivs','RoulsAscendancy','#7ae2d0','orbits','THE SECOND-SKIN CHOIR','Anima remembers. Choose vessels, then confirm their exchange.'),
 ('CoolWackyCivs','FilthyRealm','#df719e','glitch','THE FILTHY REALM','Choose an ability, inspect its cost, then select a target.'),
 ('CoolWackyCivs','DualOrder','#d7b77a','cross','THE DUAL ORDER','Faith sustains the order. Active wars build Balance Pressure.'),
 ('CoolWackyCivs','RomanGladiusNetwork','#dbad62','grid','SERVER ADMINISTRATION','Protect your community, appoint staff and grow its reputation.'),
 ('CoolWackyCivs','EternalNumberTen','#76cde6','stadium','THE ETERNAL NUMBER TEN','A career becomes a legacy. Select a chapter to read its rewards.'),
 ('CoolWackyCivs','MasayaBeyondSky','#81d7ff','flight','JOY OF FLIGHT','Build Joy through flight; a full reserve opens Beyond the Sky.'),
 ('CoolWackyCivs','ViltrumEmpire','#e36660','chevron','IMPERIAL COMMAND','Momentum wins worlds. The bloodline must survive what follows.'),
 ('CoolWackyCivs','TokenizedIntelligence','#6de7bc','grid','CONTEXT / PROMPT CONSOLE','Inspect token cost, choose a target and confirm execution.'),
 ('CoolWackyCivs','TheKingdoms','#d9bb78','heraldry','THE ROYAL COUNCIL','Houses, heirs and sworn guards hold the realm together.'),
 ('CoolWackyCivs','TheShatteredEmpire','#d7aa66','heraldry','IMPERIAL ADMINISTRATION','Govern the provinces. Honour oaths. Restore the empire.'),
 ('CoolWackyCivs','TheLastCity','#c9ab68','industrial','THE SANCTUARY COUNCIL','Every citizen, provision and promise matters to Last Light.'),
 ('CoolWackyCivs','CristianoRonaldo','#e1ba67','stadium','THE RELENTLESS SEVEN','Ambition writes the next chapter. Earned progress is permanent.'),
 ('CoolWackyCivs','TheBoyWhoTouchedParadise','#86d8ed','stadium','THE JOURNEY TO PARADISE','Dreams, memories and moments of magic shape the journey.'),
 ('CoolWackyCivs2','TheBoundlessCity','#d4b873','blueprint','THE BOUNDLESS WORKFORCE','One charter. Countless districts. Every worker has a place.'),
 ('CoolWackyCivs2','TrainerRed','#eb8075','circuit','CHAMPION TEAM','Train partners, build bonds and prepare the road to Mt. Silver.'),
 ('CoolWackyCivs2','McPvP','#b2db6b','pixel','MCPVP / SERVER BROWSER','Select a veteran, choose a kit and queue the next match.'),
 ('CoolWackyCivs2','TheChildrenOfTheKingdom','#dfc997','arches','THE BOOK OF PRAYER','Seven petitions. Lasting Grace. A faithful kingdom.'),
 ('CoolWackyCivs2','The11Cats','#e2b16e','paws','THE HOUSEHOLD','Eleven companions, warm homes and a family worth protecting.'),
 ('CoolWackyCivs2','TheSubstituteClassroom','#ddca86','ruled','MR. GARVEY / ROLL CALL','Take attendance. Correct the record. Keep the class in order.'),
 ('CoolWackyCivs2','TheUrgal','#c396e9','orbits','THE URGAL / BREWING STAND','Save rare potions for the moment your whole army can strike.'),
 ('CoolWackyCivs2','JinDynasty','#d3ad68','heraldry','THE JIN DYNASTY','Grasslands, horses and tribute sustain the Jurchen legacy.'),
 ('CoolWackyCivs2','TheThresholdCourt','#b49ee5','arches','THE THRESHOLD COURT','Choose a doorway, inspect the destination and confirm a crossing.'),
]

def rgb(value): return tuple(bytes.fromhex(value.lstrip('#')))
def tint(a,b,t): return tuple(round(x*(1-t)+y*t) for x,y in zip(a,b))
def material(size,accent,motif,base_color=None):
 w,h=size;im=Image.new('RGBA',size);d=ImageDraw.Draw(im)
 base=base_color or tint(accent,(10,15,24),.91)
 for y in range(h):
  c=tint(base,(5,9,15),.60*y/max(1,h-1));d.line((0,y,w,y),fill=c+(255,))
 faint=tint(base,accent,.15)+(255,)
 if motif in ('grid','blueprint','pixel','circuit'):
  step=32 if motif!='pixel' else 24
  for x in range(0,w,step):d.line((x,0,x,h),fill=faint)
  for y in range(0,h,step):d.line((0,y,w,y),fill=faint)
  if motif=='circuit':
   for x in range(20,w,83):d.ellipse((x,h//2-3,x+6,h//2+3),outline=accent+(100,))
 elif motif in ('orbits','arches','stadium','paws'):
  for radius in range(90,w,76):
   cx=w*.84;cy=h*.70
   d.ellipse((cx-radius,cy-radius,cx+radius,cy+radius),outline=faint,width=1)
  if motif=='paws':
   for x in range(55,w,140):
    d.ellipse((x,h-45,x+20,h-27),fill=faint)
    for dx,dy in [(-3,-11),(6,-17),(16,-15),(24,-6)]:d.ellipse((x+dx,h-45+dy,x+dx+7,h-38+dy),fill=faint)
 elif motif=='ruled':
  for y in range(18,h,25):d.line((16,y,w-16,y),fill=faint)
  d.line((48,8,48,h-8),fill=tint(base,accent,.3)+(255,))
 elif motif=='heraldry':
  for x in range(45,w,96):
   for y in range(45,h,96):d.polygon([(x,y-30),(x+23,y),(x,y+30),(x-23,y)],outline=faint)
 elif motif=='cross':
  d.rectangle((w//2-1,10,w//2+1,h-10),fill=faint)
  d.rectangle((12,h//2-1,w-12,h//2+1),fill=faint)
 elif motif=='industrial':
  for x in range(16,w-16,42):d.line((x,h-18,x+12,h-6),fill=faint,width=4)
  for x,y in [(12,12),(w-13,12),(12,h-13),(w-13,h-13)]:d.ellipse((x-3,y-3,x+3,y+3),outline=accent+(180,))
 elif motif=='flight':
  for y in range(28,h,64):d.arc((w//2-80,y-42,w+180,y+70),175,330,fill=faint,width=2)
 elif motif=='glitch':
  for y in range(18,h,37):
   x=(y*17)%max(1,w-90);d.line((x,y,min(w-14,x+72),y),fill=faint,width=2)
   d.line((max(14,x-20),y+4,min(w-14,x+26),y+4),fill=tint(base,accent,.24)+(255,))
 else:
  for x in range(-h,w,110):d.line((x,0,x+h,h),fill=faint)
 d.rectangle((0,0,w-1,h-1),outline=(3,5,9,255),width=2)
 d.rectangle((2,2,w-3,h-3),outline=accent+(190,),width=1)
 d.rectangle((6,6,w-7,h-7),outline=accent+(45,),width=1)
 for x,y,sx,sy in [(10,10,1,1),(w-11,10,-1,1),(10,h-11,1,-1),(w-11,h-11,-1,-1)]:
  d.line((x,y,x+sx*28,y),fill=accent+(240,),width=2)
  d.line((x,y,x,y+sy*19),fill=accent+(240,),width=2)
 return im

def assets(civ,accent,motif):
 art=civ/'Art';source=next(iter(sorted(art.glob('*Leader.dds'))),None)
 base={
  'RoulsAscendancy':(18,12,35),'FilthyRealm':(25,8,30),'DualOrder':(25,23,22),
  'RomanGladiusNetwork':(28,12,19),'EternalNumberTen':(12,25,39),'MasayaBeyondSky':(7,24,45),
  'ViltrumEmpire':(27,10,13),'TokenizedIntelligence':(5,27,24),'TheKingdoms':(10,20,47),
  'TheShatteredEmpire':(38,9,15),'TheLastCity':(18,25,30),'CristianoRonaldo':(22,15,16),
  'TheBoyWhoTouchedParadise':(10,26,42),'TheBoundlessCity':(8,26,34),'TrainerRed':(13,19,34),
  'McPvP':(11,23,15),'TheChildrenOfTheKingdom':(8,27,22),'The11Cats':(35,24,17),
  'TheSubstituteClassroom':(8,31,24),'TheUrgal':(24,9,37),'JinDynasty':(34,12,17),
  'TheThresholdCourt':(21,15,41)}[civ.name]
 panel=material((1024,768),accent,motif,base)
 if source:
  with Image.open(source) as s: hero=ImageOps.fit(s.convert('RGBA'),(1008,118),Image.Resampling.LANCZOS,centering=(.5,.32))
  shade=Image.new('RGBA',hero.size);d=ImageDraw.Draw(shade)
  for x in range(hero.width):
   alpha=round(236-110*x/hero.width);d.line((x,0,x,hero.height),fill=(7,12,20,alpha))
  hero.alpha_composite(shade);panel.alpha_composite(hero,(8,8))
 d=ImageDraw.Draw(panel);d.line((16,127,1008,127),fill=accent+(210,),width=2)
 d.line((18,131,1006,131),fill=accent+(45,));d.line((18,736,1006,736),fill=accent+(60,))
 # Four 44px nine-slice states, separated by one pixel, matching Grid9FrameButtons.
 buttons=Image.new('RGBA',(44,180))
 for state,level in enumerate((.10,.30,.19,.04)):
  tile=material((44,44),tint(accent,(100,106,115),.65) if state==3 else accent,'plain',base)
  td=ImageDraw.Draw(tile);td.rectangle((5,5,38,38),fill=tint((10,17,25),accent,level)+(255,))
  td.line((5,5,38,5),fill=accent+(255 if state==1 else 110,))
  buttons.alpha_composite(tile,(0,state*45))
 return {'Panel':panel,'Launcher':material((576,128),accent,motif,base),
         'Row':material((1024,96),accent,motif,base),'Buttons':buttons}

def compile_textures(items):
 texconv=shutil.which('texconv') or shutil.which('texconv.exe')
 if not texconv:raise RuntimeError('DirectXTex texconv is required')
 with tempfile.TemporaryDirectory(prefix='civ-ui-',dir=WORKSPACE) as directory:
  stage=Path(directory).resolve();assert stage.parent==WORKSPACE.resolve()
  names=[]
  for path,im in items:
   if im.width%4 or im.height%4:
    path.write_bytes(raw_mips(im));continue
   im.save(stage/(path.stem+'.png'));names.append(str(stage/(path.stem+'.png')))
  listing=stage/'textures.txt';listing.write_text('\n'.join(names),encoding='utf-8')
  r=subprocess.run([texconv,'-nologo','-y','-dx9','-f','DXT5','-m','0','-o',str(stage),'-flist',str(listing)],capture_output=True,text=True)
  if r.returncode:raise RuntimeError(r.stdout+r.stderr)
  for path,im in items:
   if im.width%4==0 and im.height%4==0:path.write_bytes((stage/path.name).read_bytes())

def skin_xml(path,prefix,title,guidance,accent):
 root=ET.parse(path).getroot()
 code=path.with_suffix('.lua').read_text(encoding='utf-8-sig')
 for item in list(root):
  if item.tag not in ('Grid','GridButton'):continue
  if item.get('Hidden') not in ('1','true','True'):continue
  w,h=map(int,item.get('Size','0,0').replace('.',',').split(','))
  if h>=750:continue # Illustrated narrative cinematics retain their composition.
  for e in list(item):
   if e.tag in ('Image','Box') and e.get('Size')==item.get('Size') and not e.get('ID','').startswith('CWC_'):
    if not e.get('ID') or 'Controls.'+e.get('ID') not in code:item.remove(e)
  if any(e.get('ID','').startswith('CWC_ThemeBackground_') for e in item):continue
  background=ET.Element('Image',ID='CWC_ThemeBackground_'+item.get('ID','Root'),Anchor='L,T',Size=f'{w},{h}',
                        Texture=prefix+('_Panel.dds' if h>200 else '_Launcher.dds'),ConsumeMouse='0')
  # Remove prior material images, preserving painted headers, emblems and data.
  for e in list(item):
   if e.tag=='Image' and e.get('Texture','').endswith(('_UI_Panel.dds','_UI_Launcher.dds')):item.remove(e)
  item.insert(0,background)
  if item.tag=='Grid':item.set('Style','GridBlackIndent8')
  if h>200:
   # Existing close buttons stay at the right edge; a compact help control
   # provides an in-world reminder without consuming the content viewport.
   help_button=ET.SubElement(item,'GridButton',ID='CWC_Guide_'+item.get('ID','Root'),Anchor='R,T',Offset='76,18',Size='30,30',
                            Font='TwCenMT18',String='?',ToolTip=title+'[NEWLINE][NEWLINE]'+guidance)
   ET.SubElement(help_button,'GridData',Style='Grid9FrameButtons',Texture=prefix+'_Buttons.dds')
  for e in item.iter('Label'):
   e.set('Color0','239,232,214,255');e.set('Color1','0,0,0,230');e.set('FontStyle','Shadow')
   if e.get('Font') in ('TwCenMT24','TwCenMT20'):e.set('Color0',','.join(map(str,tint(accent,(255,243,218),.5)))+',255')
 for e in root.iter('GridButton'):
  if e.get('Style') in ('BaseButton','Grid9FrameButtons'):e.attrib.pop('Style',None)
  gd=e.find('GridData')
  if gd is None:gd=ET.Element('GridData');e.insert(0,gd)
  gd.set('Style','Grid9FrameButtons');gd.set('Texture',prefix+'_Buttons.dds')
  e.set('Font',e.get('Font','TwCenMT16'));e.set('ColorSet','Beige_Black_Alpha')
 for instance in root.findall('Instance'):
  for e in list(instance):
   if e.tag=='Grid' and e.get('Size') and not any(c.get('ID','').startswith('CWC_RowSurface_') for c in e):
    e.insert(0,ET.Element('Image',ID='CWC_RowSurface_'+instance.get('Name','Row'),Anchor='L,T',Size=e.get('Size'),Texture=prefix+'_Row.dds',ConsumeMouse='0'))
 for e in root.iter('ScrollPanel'):
  e.set('AutoScrollBar','1')
  if e.find('ScrollBar') is None:
   ET.SubElement(e,'ScrollBar',Style='VertSlider',Anchor='R,T',AnchorSide='I,I',Offset='0,4',Length=str(max(30,int(e.get('Size','0,100').split(',')[-1])-8)))
 ET.indent(root,' ');path.write_bytes(ET.tostring(root,encoding='utf-8',xml_declaration=True))

def upgrade_hud(path,folder):
 root=ET.parse(path).getroot();ids={e.get('ID'):e for e in root.iter() if e.get('ID')}
 if folder=='DualOrder' and 'PressureReadout' not in ids:
  hud=ids['BalanceFrame'];hud.set('Size','480,126')
  ids['CWC_ThemeBackground_BalanceFrame'].set('Size','480,126')
  ids['CivIcon'].set('Anchor','L,T');ids['CivIcon'].set('Offset','18,16')
  ids['BalanceLabel'].attrib.update(Anchor='L,T',Offset='66,44',Size='394,28',Font='TwCenMT18')
  ET.SubElement(hud,'Label',Anchor='L,T',Offset='66,15',Font='TwCenMT20',Color0='237,214,166,255',String='THE DUAL ORDER')
  ET.SubElement(hud,'Label',ID='PressureReadout',Anchor='L,T',Offset='20,78',Size='440,22',Font='TwCenMT14',Color0='223,215,195,255')
  ET.SubElement(hud,'Box',Anchor='L,T',Offset='20,107',Size='440,6',Color='45,39,33,255')
  ET.SubElement(hud,'Box',ID='PressureFill',Anchor='L,T',Offset='20,107',Size='1,6',Color='215,183,122,255')
 elif folder=='MasayaBeyondSky' and 'FlightMilestones' not in ids:
  hud=ids['JoyFrame'];hud.set('Size','480,132');ids['CWC_ThemeBackground_JoyFrame'].set('Size','480,132')
  ids['JoyIcon'].set('Offset','18,18');ids['JoyLabel'].set('Offset','64,16');ids['JoyLabel'].set('Size','396,28')
  ids['StateLabel'].attrib.update(Anchor='L,T',Offset='64,46',Size='396,22',Font='TwCenMT16')
  for e in hud:
   if e.tag=='Box':
    x,y=map(int,e.get('Offset','0,0').split(','))
    if y in (32,33):e.set('Offset',str(x+9)+','+str(y+44))
  ET.SubElement(hud,'Label',ID='FlightMilestones',Anchor='L,T',Offset='64,101',Font='TwCenMT14',Color0='160,210,237,255',String="50: CAN'T STOP FLYING     100: BEYOND THE SKY")
 elif folder=='TheUrgal' and 'PotionArmy' not in ids:
  hud=ids['Inventory'];hud.set('Size','340,180');ids['CWC_ThemeBackground_Inventory'].set('Size','340,180')
  ids['PotionIcon'].set('Offset','18,18');ids['Stockpile'].set('Offset','62,49')
  ids['Status'].attrib.update(Anchor='L,T',Offset='18,82',Size='304,22')
  ids['Drink'].set('Size','304,36');ids['Drink'].set('Offset','0,14')
  ET.SubElement(hud,'Label',Anchor='L,T',Offset='62,18',Font='TwCenMT18',Color0='223,191,249,255',String='STRENGTH POTION')
  ET.SubElement(hud,'Label',ID='PotionArmy',Anchor='L,T',Offset='18,109',Font='TwCenMT14',Color0='196,178,212,255',Size='304,20')
 ET.indent(root,' ');path.write_bytes(ET.tostring(root,encoding='utf-8',xml_declaration=True))

def main():
 pending=[];inventory=[]
 for repo,folder,color,motif,title,guidance in THEMES:
  civ=WORKSPACE/repo/folder;prefix=('CWC2_' if repo.endswith('2') else 'CWC_')+folder
  xmls=[p for p in (civ/'UI').glob('*.xml') if len(ET.parse(p).getroot())]
  if not xmls:raise RuntimeError('No visible UI: '+folder)
  for xml in xmls:
   skin_xml(xml,prefix,title,guidance,rgb(color));upgrade_hud(xml,folder)
  materials=assets(civ,rgb(color),motif)
  compiled={prefix+'_'+key+'.dds':im for key,im in materials.items()}
  for xml in xmls:
   tree=ET.parse(xml)
   # Keep the cat panel's responsive Background control and Garvey's board
   # geometry, while replacing the old opaque material with the new theme.
   for e in tree.iter('Image'):
    if folder=='The11Cats' and e.get('ID')=='Background':
     e.set('Texture',prefix+'_Panel.dds');e.set('ConsumeMouse','0')
    if folder=='TheSubstituteClassroom' and e.get('Texture')=='GARVEY_Board.dds':
     e.set('Texture',prefix+'_Panel.dds');e.set('ConsumeMouse','0')
   for e in tree.iter('Image'):
    filename=e.get('Texture','')
    if not filename.startswith(prefix+'_'):continue
    kind=next((key for key in ['Panel','Launcher','Row'] if filename.startswith(prefix+'_'+key)),None)
    if not kind:continue
    size=tuple(map(int,e.get('Size').split(',')))
    filename=prefix+'_'+kind+'_'+str(size[0])+'x'+str(size[1])+'.dds'
    e.set('Texture',filename);compiled[filename]=materials[kind].resize(size,Image.Resampling.LANCZOS)
   ET.indent(tree,' ');xml.write_bytes(ET.tostring(tree.getroot(),encoding='utf-8',xml_declaration=True))
  for filename,im in compiled.items():pending.append((civ/'Art'/filename,im))
  inventory.append({'repo':repo,'civilization':folder,'title':title,'accent':color,'motif':motif,'prefix':prefix,'xml':[str(p.relative_to(WORKSPACE/repo)).replace('\\','/') for p in xmls],
                    'textures':{filename:list(im.size) for filename,im in compiled.items()}})
 compile_textures(pending)
 for repo in ('CoolWackyCivs','CoolWackyCivs2'):
  out=WORKSPACE/repo/'docs/UIRefreshInventory.json';out.write_text(json.dumps([r for r in inventory if r['repo']==repo],indent=2)+'\n',encoding='utf-8')
 print('Refreshed',len(inventory),'native interfaces with',len(pending),'theme textures')

if __name__=='__main__':main()
