"""Keep standalone civs and the collection on the same presentation helper."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib

ROOT=Path(__file__).resolve().parents[1]
SHARED='Shared/UI/CWC_Screen.lua'

def add_shared_ui(root):
 path=ROOT/SHARED
 ET.SubElement(root.find('Files'),'File',md5=hashlib.md5(path.read_bytes()).hexdigest().upper(),
               **{'import':'1'}).text=SHARED

def source_file(civ,relative):
 path=(ROOT/relative if relative==SHARED else civ/relative).resolve()
 assert path.is_relative_to(ROOT.resolve()),'Standalone source escapes the repository'
 return path

def archive_name(path,civ):
 return path.relative_to(civ).as_posix() if path.is_relative_to(civ) else path.relative_to(ROOT).as_posix()
