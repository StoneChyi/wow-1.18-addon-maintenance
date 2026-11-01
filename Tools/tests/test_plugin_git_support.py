"""Scoped checkpoint support files cannot include user settings or directories."""
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tools'))
import plugin_git


class ScopedSupport(unittest.TestCase):
    def test_exact_policy(self):
        self.assertEqual(plugin_git.support_path('AGENTS.md'), 'AGENTS.md')

    def test_exact_tool(self):
        path = 'Tools/tests/test_plugin_git_support.py'
        self.assertEqual(plugin_git.support_path(path), path)

    def test_excluded_scopes(self):
        for path in ('WTF/Account/secret.lua', 'dlls.txt', 'Tools', 'Tools/tests',
                     '../AGENTS.md', 'Tools/../../AGENTS.md', '/AGENTS.md',
                     'Tools/.git/config', 'Tools/missing.py', 'Tools\\plugin_git.py',
                     'E:/1.18/AGENTS.md', 'PluginHistory/README.md'):
            with self.subTest(path=path), self.assertRaises(RuntimeError):
                plugin_git.support_path(path)

    def test_checks_run_before_commit_without_changing_existing_staging_guard(self):
        commands = []
        def git(*args, **kwargs):
            commands.append(args)
            if args[:4] == ('diff', '--cached', '--name-only', '-z'):
                return b'' if len(commands) == 1 else b'AGENTS.md\0'
            if args[0] == 'ls-files':
                return b'AGENTS.md\0'
            return b'test commit\n'
        class Result:
            returncode = 0
        with patch.object(plugin_git, 'git', side_effect=git), \
                patch.object(plugin_git, 'stage_paths'), \
                patch.object(plugin_git.subprocess, 'run', return_value=Result()) as run:
            plugin_git.checkpoint([], [], 'scoped test', support=['AGENTS.md'], check_notes=True)
        self.assertEqual(run.call_count, 2)
        self.assertIn('plugin_history.py', run.call_args_list[0].args[0][1])
        self.assertIn('check_plugin_notes.py', run.call_args_list[1].args[0][1])
        self.assertTrue(any('commit' in command for command in commands))

    def test_failed_check_stops_commit_and_preserves_staged_review(self):
        commands = []
        def git(*args, **kwargs):
            commands.append(args)
            if args[0] == 'diff':
                return b'' if len(commands) == 1 else b'AGENTS.md\0'
            return b'AGENTS.md\0'
        class Result:
            returncode = 1
        with patch.object(plugin_git, 'git', side_effect=git), \
                patch.object(plugin_git, 'stage_paths'), \
                patch.object(plugin_git.subprocess, 'run', return_value=Result()), \
                self.assertRaises(RuntimeError):
            plugin_git.checkpoint([], [], 'must not commit', support=['AGENTS.md'], check_notes=True)
        self.assertFalse(any('commit' in command for command in commands))


if __name__ == '__main__':
    unittest.main()
