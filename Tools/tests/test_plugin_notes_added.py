"""New plugin records must not rewrite the frozen historical catalog."""
from copy import deepcopy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from check_plugin_notes import validate_addon_sets


class AddedAddonTests(unittest.TestCase):
    def setUp(self):
        self.index = {
            'addons': [{'addon': 'Old', 'status': 'documented_history'}],
            'counts': {'documented_history': 1},
            'added_addons': [{'addon': 'New', 'status': 'documented_history',
                              'added_on': '2026-10-11', 'creation_base_commit': 'a'*40,
                              'tracked_files_at_reference': 0}],
            'added_counts': {'documented_history': 1},
        }

    def test_distinct_reference_and_new_counts(self):
        before = deepcopy(self.index)
        old, new = validate_addon_sets(self.index, {'Old'})
        self.assertEqual((len(old), len(new)), (1, 1))
        self.assertEqual(self.index, before)

    def test_legacy_schema_still_works(self):
        del self.index['added_addons']; del self.index['added_counts']
        self.assertEqual(validate_addon_sets(self.index, {'Old'})[1], [])

    def test_cannot_insert_new_into_historical_catalog(self):
        self.index['addons'].extend(self.index['added_addons'])
        with self.assertRaises(AssertionError): validate_addon_sets(self.index, {'Old'})

    def test_cannot_relabel_existing_as_new(self):
        self.index['added_addons'][0]['addon'] = 'Old'
        with self.assertRaises(AssertionError): validate_addon_sets(self.index, {'Old'})

    def test_duplicate_new_names_rejected(self):
        self.index['added_addons'] *= 2
        with self.assertRaises(AssertionError): validate_addon_sets(self.index, {'Old'})

    def test_new_count_mismatch_rejected(self):
        self.index['added_counts'] = {}
        with self.assertRaises(AssertionError): validate_addon_sets(self.index, {'Old'})

    def test_historical_count_mismatch_rejected(self):
        self.index['counts'] = {'documented_history': 2}
        with self.assertRaises(AssertionError): validate_addon_sets(self.index, {'Old'})

    def test_new_record_requires_zero_historical_files(self):
        self.index['added_addons'][0]['tracked_files_at_reference'] = 1
        with self.assertRaises(AssertionError): validate_addon_sets(self.index, {'Old'})

    def test_new_record_requires_date_and_base(self):
        for key in ['added_on', 'creation_base_commit']:
            bad = deepcopy(self.index); bad['added_addons'][0][key] = ''
            with self.assertRaises(AssertionError): validate_addon_sets(bad, {'Old'})

    def test_new_name_cannot_escape_addon_directory(self):
        for name in ['..', '../bad', 'bad/child', 'bad\\child']:
            bad = deepcopy(self.index); bad['added_addons'][0]['addon'] = name
            with self.assertRaises(AssertionError): validate_addon_sets(bad, {'Old'})


if __name__ == '__main__':
    unittest.main()
