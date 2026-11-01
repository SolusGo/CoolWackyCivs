"""Optional sibling-repository check: both collections' actual SQL and native search."""
from pathlib import Path
from xml.etree import ElementTree as ET
import json
from validate_strategy_guides import database_and_paths, translations
from civilopedia_index import replay_index, support_source


def run(reverse=False):
    root = Path(__file__).resolve().parents[1]
    other = root.parent / 'CoolWackyCivs2'
    manifests = list(other.glob('*.modinfo'))
    assert len(manifests) == 1, 'Expected one current sibling collection manifest'
    db, paths = database_and_paths()
    second = [other / entry.text for entry in ET.parse(manifests[0]).findall('Actions/OnModActivated/UpdateDatabase')]
    first_paths, later_paths = (second, paths) if reverse else (paths, second)
    first_prefix = 'TXT_KEY_CWC2_GUIDE_' if reverse else 'TXT_KEY_CWC_GUIDE_'
    for path in first_paths:
        db.executescript(path.read_text(encoding='utf-8-sig'))
    original = {k: v for k, v in translations(db).items() if k.startswith(first_prefix)}
    for path in later_paths:
        db.executescript(path.read_text(encoding='utf-8-sig'))
    text = translations(db)
    assert all(text.get(k) == v for k, v in original.items()), 'Original guide text was overwritten'
    records = [c for repo in [root, other] for c in json.loads((repo / 'docs/StrategyGuides.json').read_text(encoding='utf-8'))['civilizations']]
    terms = []
    for c in records:
        row = db.execute('SELECT * FROM Civilizations WHERE Type=?', (c['civ'],)).fetchone()
        assert (row['Playable'], row['AIPlayable']) == (1, 0)
        assert c['name'] in text[row['CivilopediaTag'] + '_TEXT_1']
        terms.append(text[row['ShortDescription']].lower())
    # Same archived-baseline repair as the isolated native-index check.
    if not db.execute("SELECT 1 FROM Civilization_Leaders WHERE CivilizationType='CIVILIZATION_ARABIA'").fetchone():
        native = support_source().parent.parent / 'Gameplay/XML/Civilizations/CIV5Civilizations.xml'
        row = next(r for r in ET.parse(native).findall('Civilization_Leaders/Row') if r.findtext('CivilizationType') == 'CIVILIZATION_ARABIA')
        db.execute('INSERT INTO Civilization_Leaders(CivilizationType,LeaderheadType) VALUES (?,?)', (row.findtext('CivilizationType'), row.findtext('LeaderheadType')))
    result = replay_index(db, text, tuple(terms))
    assert result['completed_categories'] == list(range(1, 17)), result
    for c, term in zip(records, terms):
        expected = db.execute('SELECT ID FROM Civilizations WHERE Type=?', (c['civ'],)).fetchone()[0]
        assert result['search'][term]['entryID'] == expected, (c['folder'], term, result['search'][term], expected)
    db.close()
    print(f'PASS both collections ({"second then original" if reverse else "original then second"}): {len(records)} independent guides/names, preserved guide text, human-only flags and exact native civilization search IDs')


if __name__ == '__main__':
    run()
    run(reverse=True)
