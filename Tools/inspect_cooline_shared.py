"""Read extracted 1.12 client DBCs; list per-class shared-CD candidates.

Usage: python Tools/inspect_cooline_shared.py --dbc-dir <extracted-directory>
Read-only, no server access. A category match is a candidate, not proof of live
server behavior. Do not commit extracted game data or this tool's raw output.
"""
import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import struct


SKILLS = {
    'Warrior': (26, 256, 257), 'Paladin': (594, 184, 267),
    'Hunter': (50, 51, 163), 'Rogue': (253, 38, 39, 40),
    'Priest': (56, 613, 78), 'Shaman': (373, 374, 375),
    'Mage': (6, 8, 237), 'Warlock': (354, 355, 593),
    'Druid': (134, 573, 574),
}


def read_dbc(path, expected_fields):
    raw = path.read_bytes()
    magic, count, fields, size, string_size = struct.unpack_from('<4s4I', raw)
    if (magic != b'WDBC' or fields != expected_fields or size != fields * 4
            or len(raw) != 20 + count * size + string_size):
        raise ValueError('Unexpected 1.12 DBC layout: ' + str(path))
    end = 20 + count * size
    strings = raw[end:]

    def text(offset):
        if offset >= len(strings):
            raise ValueError('Invalid DBC string offset')
        return strings[offset:strings.index(0, offset)].decode('utf-8')

    rows = {row[0]: row for row in struct.iter_unpack('<%dI' % fields, raw[20:end])}
    if len(rows) != count:
        raise ValueError('Duplicate DBC record IDs')
    return rows, text, {'file': path.name, 'rows': count, 'fields': fields,
                        'sha256': hashlib.sha256(raw).hexdigest()}


def inspect(directory):
    spells, text, spell_meta = read_dbc(directory / 'Spell.dbc', 173)
    abilities, _, ability_meta = read_dbc(directory / 'SkillLineAbility.dbc', 15)
    skills, _, skill_meta = read_dbc(directory / 'SkillLine.dbc', 22)
    for class_skills in SKILLS.values():
        if not all(skill in skills for skill in class_skills):
            raise ValueError('Missing expected class skill lines')
    skill_class = {skill: name for name, ids in SKILLS.items() for skill in ids}
    categories = defaultdict(lambda: defaultdict(list))
    covered = {name: set() for name in SKILLS}
    for ability in abilities.values():
        name = skill_class.get(ability[1])
        spell = spells.get(ability[2])
        if name is None or spell is None:
            continue
        covered[name].add(spell[0])
        if spell[6] & 64 or not spell[2]:  # passive / no category
            continue
        categories[name, spell[2]][text(spell[120])].append({
            'id': spell[0], 'zhCN': text(spell[124]),
            'own_ms': spell[19], 'category_ms': spell[20],
        })
    candidates = []
    for (name, category), members in sorted(categories.items()):
        if len(members) < 2:
            continue
        if not any(max(row['own_ms'], row['category_ms']) > 2500
                   for ranks in members.values() for row in ranks):
            continue
        candidates.append({'class': name, 'category': category, 'members': dict(members)})
    return {'client_files': [spell_meta, ability_meta, skill_meta],
            'class_spell_ids_checked': {name: len(ids) for name, ids in covered.items()},
            'candidate_count': len(candidates), 'candidates': candidates}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dbc-dir', type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(inspect(args.dbc_dir), ensure_ascii=True, indent=2))
