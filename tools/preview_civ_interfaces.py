"""Render labelled XML geometry/texture previews; this is NOT Civ V rendering.

Static labels and representative sample data use Windows fonts. Native icon
markup, animation and game layout remain subject to the in-game checklist.
"""
from pathlib import Path
from xml.etree import ElementTree as ET
import json, math, re
from PIL import Image, ImageDraw, ImageFont, ImageOps

WORKSPACE=Path(__file__).resolve().parents[2]
FONT='C:/Windows/Fonts/segoeui.ttf'

def number_pair(value,default=(0,0)):
 try:return tuple(map(int,value.replace('.',',').split(',')))
 except (ValueError,AttributeError):return default

def font(size):return ImageFont.truetype(FONT,size)
def plain(value):
 value=re.sub(r'\[COLOR_[^\]]+\]|\[ENDCOLOR\]','',value).replace('[NEWLINE]','\n')
 value=re.sub(r'\[ICON_([^\]]+)\]',lambda m:' '+m[1].lower()+' ',value)
 if value.startswith('TXT_KEY_'):value=value.rsplit('_',1)[-1].replace('_',' ').title()
 return value

def wrap(value,width,f):
 lines=[]
 for paragraph in value.split('\n'):
  current=''
  for word in paragraph.split():
   if current and f.getlength(current+' '+word)>width:lines.append(current);current=word
   else:current=(current+' '+word).strip()
  lines.append(current)
 return lines

def nine_slice(texture,size):
 tile=texture.crop((0,0,44,44));out=Image.new('RGBA',size);w,h=size
 for x0,x1,dx,dw in [(0,8,0,8),(8,36,8,max(1,w-16)),(36,44,w-8,8)]:
  for y0,y1,dy,dh in [(0,8,0,8),(8,36,8,max(1,h-16)),(36,44,h-8,8)]:
   out.alpha_composite(tile.crop((x0,y0,x1,y1)).resize((dw,dh)),(dx,dy))
 return out

def preview(repo,record):
 root=ET.parse(repo/record['xml'][0]).getroot()
 candidates=[e for e in root if e.tag in ('Grid','GridButton')]
 non_cinematic=[e for e in candidates if number_pair(e.get('Size'))[1]<750]
 if non_cinematic:candidates=non_cinematic
 panel=max(candidates,key=lambda e:math.prod(number_pair(e.get('Size'))))
 w,h=number_pair(panel.get('Size'));canvas=Image.new('RGBA',(w,h),(12,18,26,255))
 art=repo/record['civilization']/'Art';textures={p.name:p for p in art.glob('*.dds')}
 cache={}
 def texture(name):
  if name not in cache:
   if name not in textures:return None
   with Image.open(textures[name]) as im:cache[name]=im.convert('RGBA')
  return cache[name]
 buttons=texture(record['prefix']+'_Buttons.dds')
 icon=next((p.name for p in sorted(art.glob('*Icon64.dds'))),None)
 icon=icon or next((p.name for p in sorted(art.glob('*_Icon64.dds'))),None)
 sample={'Title':record['title'],'RealmTitle':record['title'],'HeaderLabel':record['title'],
  'ImperialTitle':record['title'],'ChapterTitle':'A LEGACY TAKES SHAPE','SectionTitle':'The realm at a glance',
  'SectionDetail':record['title'].title(),'HorseValue':'12 / 20','TributeValue':'3','VillagerValue':'6 / 10',
  'KarmaValue':'48 / 100','LandmarkValue':'2 / 3','Summary':'Your civilization at a glance. Select an entry to inspect its details.',
  'RealmSummary':'Four Houses   |   Three cities   |   The crown endures','ReserveLabel':'Anima: 4 / 7',
  'JoyLabel':'JOY OF FLIGHT  |  70 / 100','StateLabel':'BEYOND THE SKY APPROACHES',
  'BalanceLabel':'BALANCE PRESSURE  |  3 / 5 WARS','PressureReadout':'Faith: +12  |  Strength +18%  |  Production +18%',
  'Stockpile':'Strength Potions: 2','PotionArmy':'Army readiness: 8 melee units',
  'Status':'Ready for the next command','Message':'Hover an entry for its requirements. Select a target before confirming.',
  'InstructionLabel':'Choose an eligible unit. Inspect its status, then confirm your command.',
  'Feedback':'Choose an eligible destination to inspect the crossing.',
  'Population':'Population: 34','OwnedPlots':'Owned plots: 146','FrontierCulture':'Frontier Culture: 62',
  'FrontierCost':'Next claim: 84','LocalWorkers':'Local workers: 18','RemoteWorkers':'Remote workers: 10',
  'Specialists':'Specialists: 6','IdleLabourers':'Idle labourers: 0','AvailableCitizens':'Available citizens: 28',
  'NextLabel':'NEXT CHAPTER\nComplete the next milestone to unlock its story.',
  'LegacyLabel':'Legacy: 420 / 500','PointsLabel':'85 FP','StatusLabel':'Ready. Your next command awaits.',
  'Details':'Review your civilization, inspect its progress and choose your next action.'}
 def label(e):
  key=e.get('ID','')
  if key in sample:return sample[key]
  if e.get('String'):return plain(e.get('String'))
  if key in ['Text','RowText','Name','ServerName','TargetName']:return 'A new chapter in your civilization\nInspect this entry for details and requirements.'
  if key.endswith(('Value','Count')):return '12'
  return re.sub(r'(?<=[a-z])(?=[A-Z])',' ',key) if key else ''
 def draw(e,parent,x=0,y=0,flow=None):
  pw,ph=parent;ew,eh=number_pair(e.get('Size'),(0,0));ox,oy=number_pair(e.get('Offset'))
  size=int(re.sub(r'\D','',e.get('Font','TwCenMT16')) or 16);f=font(size)
  if e.tag=='Label':
   ew=ew or int(e.get('WrapWidth',max(30,pw-ox-12)));lines=wrap(label(e),max(24,ew),f);eh=eh or max(1,len(lines))*(size+3)
  if e.tag=='Stack':ew=ew or max(20,pw-ox);eh=eh or max(20,ph-oy)
  ew=ew or 1;eh=eh or 1
  anchor=e.get('Anchor','L,T').split(',');ax=anchor[0];ay=anchor[-1]
  px=x+ox if ax=='L' else x+pw-ox-ew if ax=='R' else x+(pw-ew)//2+ox
  py=y+oy if ay=='T' else y+ph-oy-eh if ay=='B' else y+(ph-eh)//2+oy
  if flow is not None:px,py=x+flow[0]+ox,y+flow[1]+oy
  if e.get('Hidden')=='1' and e is not panel:return ew,eh
  if e.get('ID','').startswith('Fill') and e.get('ID')[4:].isdigit() and int(e.get('ID')[4:])>7:return ew,eh
  if e.get('ID')=='PressureFill':ew=264
  d=ImageDraw.Draw(canvas)
  if e.tag=='Image':
   im=texture(e.get('Texture',''))
   if im is None and icon and ew>=24 and eh>=24 and ew<=128:im=texture(icon)
   if im is not None:canvas.alpha_composite(im.resize((max(1,ew),max(1,eh)),Image.Resampling.LANCZOS),(px,py))
  elif e.tag=='Box':
   color=tuple(map(int,e.get('Color','40,52,62,255').split(',')))
   d.rectangle((px,py,px+ew,py+eh),fill=color)
  elif e.tag=='GridButton':
   canvas.alpha_composite(nine_slice(buttons,(max(16,ew),max(16,eh))),(px,py))
   text=label(e);lines=wrap(text,max(20,ew-16),f);th=min(eh-6,len(lines)*(size+2));ty=py+(eh-th)//2
   for line in lines[:max(1,eh//(size+2))]:
    d.text((px+(ew-f.getlength(line))/2,ty),line,font=f,fill=(239,231,211));ty+=size+2
  elif e.tag=='Label':
   color=tuple(map(int,e.get('Color0','239,232,214,255').split(',')))
   for i,line in enumerate(lines[:max(1,eh//(size+2))]):d.text((px,py+i*(size+3)),line,font=f,fill=color)
  if e.tag in ('Grid','GridButton','Stack','ScrollPanel'):
   sx,sy=0,0;growth=e.get('StackGrowth');padding=int(e.get('Padding','0').split(',')[0])
   for child in e:
    if child.tag in ['GridData','ScrollBar']:continue
    cw,ch=draw(child,(ew,eh),px,py,(sx,sy) if growth else None)
    if growth=='Bottom':sy+=ch+padding
    if growth=='Right':sx+=cw+padding
   # The native InstanceManager supplies these rows. Use sample entries in
   # otherwise empty list stacks without pretending this is a game capture.
   if e.tag=='Stack' and not len(e) and ew>200 and e.get('ID','') not in ('Tabs','RealmTabs','ImperialTabs','CategoryStack'):
    row=texture(record['prefix']+'_Row.dds');rh=66
    for i in range(min(3,max(1,eh//rh))):
     if py+i*rh+rh>h-30:break
     canvas.alpha_composite(row.resize((ew-8,rh-6)),(px,py+i*rh))
     d=ImageDraw.Draw(canvas);d.text((px+14,py+i*rh+8),['Overview and progress','Available commands','Your civilization remembers'][i],font=font(16),fill=record['accent'])
     d.text((px+14,py+i*rh+32),'Select an entry to inspect its details.',font=font(14),fill=(205,210,212))
  return ew,eh
 panel.set('Anchor','L,T');panel.set('Offset','0,0')
 draw(panel,(w,h))
 # The top-level native anchor is relative to the screen, not to itself.
 output=Image.new('RGB',(1280,820),(6,11,17));output.paste(canvas,((1280-w)//2,54),canvas)
 d=ImageDraw.Draw(output);d.text((24,14),record['title'],font=font(20),fill=record['accent'])
 d.text((24,790),'XML / shipped-texture preview with sample data. Native game rendering is not shown.',font=font(13),fill=(151,163,174))
 return output

def main():
 all_images=[]
 for repo in [WORKSPACE/'CoolWackyCivs',WORKSPACE/'CoolWackyCivs2']:
  records=json.loads((repo/'docs/UIRefreshInventory.json').read_text(encoding='utf-8'))
  out=repo/'art-source/UIRefresh';out.mkdir(parents=True,exist_ok=True)
  for record in records:
   image=preview(repo,record);image.save(out/(record['civilization']+'.png'))
   all_images.append((record,image))
 board=Image.new('RGB',(1920,math.ceil(len(all_images)/4)*300+80),(7,12,19));d=ImageDraw.Draw(board)
 d.text((24,18),'CIVILIZATION INTERFACES / THEME & RECOVERY REFRESH',font=font(28),fill='#e7c889')
 for i,(record,im) in enumerate(all_images):
  x=i%4*480;y=i//4*300+76
  repo=WORKSPACE/record['repo'];r=ET.parse(repo/record['xml'][0]).getroot()
  choices=[e for e in r if e.tag in ('Grid','GridButton') and number_pair(e.get('Size'))[1]<750]
  largest=max(choices,key=lambda e:math.prod(number_pair(e.get('Size'))))
  w,h=number_pair(largest.get('Size'));left=(1280-w)//2
  crop=im.crop((left,54,left+w,54+h));tile=ImageOps.contain(crop,(456,252),Image.Resampling.LANCZOS)
  board.paste(tile,(x+(480-tile.width)//2,y+(258-tile.height)//2))
  d.text((x+12,y+268),record['civilization'],font=font(14),fill=record['accent'])
 board.save(WORKSPACE/'UIRefreshReview.png');print('Wrote',len(all_images),'full layout previews and UIRefreshReview.png')

if __name__=='__main__':main()
