#!/usr/bin/env python3
"""Unit and git integration tests for .github/scripts/check_noche_motion.py."""

from __future__ import annotations

import contextlib
import io
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import check_noche_motion as mod  # noqa: E402


class PathClassificationTests(unittest.TestCase):
    def test_raw_motion_checked_paths(self) -> None:
        self.assertTrue(
            mod.is_raw_motion_checked_path(
                "coqui/packages/features/feature_map/lib/src/map_screen.dart"
            )
        )
        self.assertTrue(
            mod.is_raw_motion_checked_path(
                "coqui/packages/features/feature_map/lib/feature_map.dart"
            )
        )
        self.assertTrue(
            mod.is_raw_motion_checked_path(
                "coqui/packages/features/feature_map/lib/src/sub/motion.dart"
            )
        )
        self.assertTrue(mod.is_raw_motion_checked_path("coqui/app/lib/main.dart"))
        self.assertTrue(
            mod.is_raw_motion_checked_path("coqui/app/lib/src/shell.dart")
        )

        # Exempt: package's own lib/src/motion.dart, coqui_ui, core packages, tests, tool, docs
        self.assertFalse(
            mod.is_raw_motion_checked_path(
                "coqui/packages/features/feature_map/lib/src/motion.dart"
            )
        )
        self.assertFalse(
            mod.is_raw_motion_checked_path("coqui/app/lib/src/motion.dart")
        )
        self.assertFalse(
            mod.is_raw_motion_checked_path(
                "coqui/packages/core/coqui_ui/lib/src/noche_motion.dart"
            )
        )
        self.assertFalse(
            mod.is_raw_motion_checked_path(
                "coqui/packages/core/coqui_platform/lib/src/io/phone_speech.dart"
            )
        )
        self.assertFalse(
            mod.is_raw_motion_checked_path(
                "coqui/packages/features/feature_map/test/map_screen_test.dart"
            )
        )
        self.assertFalse(
            mod.is_raw_motion_checked_path(
                "coqui/packages/features/feature_map/tool/dev_main.dart"
            )
        )
        self.assertFalse(
            mod.is_raw_motion_checked_path("docs/proyecto/24-noche-motion.md")
        )

    def test_ms_checked_paths(self) -> None:
        self.assertTrue(
            mod.is_ms_checked_path(
                "coqui/packages/features/feature_map/lib/src/map_screen.dart"
            )
        )
        self.assertTrue(
            mod.is_ms_checked_path(
                "coqui/packages/features/feature_map/lib/src/sub/motion.dart"
            )
        )
        self.assertTrue(
            mod.is_ms_checked_path(
                "coqui/packages/features/feature_map/test/map_screen_test.dart"
            )
        )
        self.assertTrue(mod.is_ms_checked_path("coqui/app/lib/src/shell.dart"))
        self.assertTrue(
            mod.is_ms_checked_path(
                "coqui/packages/core/coqui_scenes/lib/src/scene.dart"
            )
        )

        # Exempt: coqui_ui and any package's lib/src/motion.dart, plus non-Dart/outside coqui
        self.assertFalse(
            mod.is_ms_checked_path(
                "coqui/packages/features/feature_map/lib/src/motion.dart"
            )
        )
        self.assertFalse(mod.is_ms_checked_path("coqui/app/lib/src/motion.dart"))
        self.assertFalse(
            mod.is_ms_checked_path(
                "coqui/packages/core/coqui_scenes/lib/src/motion.dart"
            )
        )
        self.assertFalse(
            mod.is_ms_checked_path(
                "coqui/packages/coqui_story_checks/lib/src/motion.dart"
            )
        )
        self.assertFalse(
            mod.is_ms_checked_path(
                "coqui/packages/core/coqui_ui/lib/src/noche_motion.dart"
            )
        )
        self.assertFalse(
            mod.is_ms_checked_path(
                "coqui/packages/core/coqui_ui/test/noche_motion_test.dart"
            )
        )
        self.assertFalse(
            mod.is_ms_checked_path("docs/proyecto/24-noche-motion.md")
        )


class SourceScanningTests(unittest.TestCase):
    FEATURE_FILE = "coqui/packages/features/feature_map/lib/src/map_screen.dart"
    MOTION_FILE = "coqui/packages/features/feature_map/lib/src/motion.dart"
    APP_FILE = "coqui/app/lib/src/shell.dart"
    UI_FILE = "coqui/packages/core/coqui_ui/lib/src/noche_controls.dart"

    def test_raw_curves_cubic_duration_fail_in_feature_lib(self) -> None:
        src = "\n".join(
            [
                "final a = Curves.easeIn;",
                "final b = const Cubic(0.2, 0, 0, 1);",
                "final c = const Duration(milliseconds: 220);",
                "final d = Cubic (0.4, 0, 1, 1);",
                "final e = Duration (seconds: 1);",
            ]
        )
        violations = mod.scan_dart_source(self.FEATURE_FILE, src, {1, 2, 3, 4, 5})
        self.assertEqual(
            [(v.line, v.token) for v in violations],
            [
                (1, "Curves."),
                (2, "Cubic("),
                (3, "Duration("),
                (4, "Cubic("),
                (5, "Duration("),
            ],
        )

    def test_raw_tokens_pass_in_coqui_ui_and_package_motion_file(self) -> None:
        src = "\n".join(
            [
                "final a = Curves.easeIn;",
                "final b = const Cubic(0.2, 0, 0, 1);",
                "final c = const Duration(milliseconds: 220);",
                "final d = NocheMotion.ms(300);",
            ]
        )
        self.assertEqual(
            mod.scan_dart_source(self.UI_FILE, src, {1, 2, 3, 4}), []
        )
        self.assertEqual(
            mod.scan_dart_source(self.MOTION_FILE, src, {1, 2, 3, 4}), []
        )

    def test_non_motion_marker_exempts_only_duration_on_same_line(self) -> None:
        src = "\n".join(
            [
                "final t1 = const Duration(seconds: 6); // non-motion",
                "final t2 = const Duration(seconds: 6); // non-motion: clip timeout",
                "final t3 = const Duration(seconds: 6); /* non-motion: audio length */",
                "final t4 = const Duration(seconds: 6); // NON-MOTION (back guard)",
                "// non-motion",
                "final t5 = const Duration(seconds: 6);",
                "final t6 = const Duration(seconds: 6); // not non-motion",
                "final t7 = const Duration(seconds: 6); final s = '// non-motion';",
                "final c1 = Curves.easeIn; // non-motion",
                "final c2 = const Cubic(0.2, 0, 0, 1); // non-motion",
                "final m1 = NocheMotion.ms(300); // non-motion",
                "final combo = (const Duration(seconds: 3), Curves.linear); // non-motion",
            ]
        )
        violations = mod.scan_dart_source(
            self.FEATURE_FILE, src, set(range(1, 13))
        )
        self.assertEqual(
            [(v.line, v.token) for v in violations],
            [
                (6, "Duration("),
                (7, "Duration("),
                (8, "Duration("),
                (9, "Curves."),
                (10, "Cubic("),
                (11, "NocheMotion.ms("),
                (12, "Curves."),
            ],
        )

    def test_noche_motion_ms_fails_outside_motion_dart(self) -> None:
        src = "final wait = NocheMotion.ms(300);\n"
        for path in (
            self.FEATURE_FILE,
            self.APP_FILE,
            "coqui/packages/features/feature_map/lib/src/sub/motion.dart",
            "coqui/packages/features/feature_map/test/map_test.dart",
            "coqui/packages/core/coqui_scenes/lib/src/scene.dart",
        ):
            with self.subTest(path=path):
                violations = mod.scan_dart_source(path, src, {1})
                self.assertEqual(
                    [(v.line, v.token) for v in violations],
                    [(1, "NocheMotion.ms(")],
                )

    def test_safe_identifiers_and_duration_zero_pass(self) -> None:
        src = "\n".join(
            [
                "final Duration? timeout = null;",
                "final z = Duration.zero;",
                "final x = myDuration(10);",
                "final y = AppCurves.enter;",
                "final k = MyCubic(0.1, 0.2, 0.3, 0.4);",
                "final m = fakeNocheMotion.ms(100);",
            ]
        )
        self.assertEqual(
            mod.scan_dart_source(self.FEATURE_FILE, src, set(range(1, 7))), []
        )

    def test_comments_and_strings_do_not_false_positive_but_interpolation_caught(
        self,
    ) -> None:
        src = "\n".join(
            [
                "// Avoid Curves.easeIn and Duration(milliseconds: 200)",
                "/// Never call NocheMotion.ms(300) here.",
                "/* nested /* Cubic(0.2, 0, 0, 1) */ Duration(seconds: 1) */",
                "const s1 = 'Curves.easeIn Duration(seconds: 1) NocheMotion.ms(10)';",
                "const s2 = r'Curves.linear \\' + 'Cubic(0, 0, 1, 1)';",
                "const s3 = '''",
                "Curves.easeOut",
                "Duration(milliseconds: 50)",
                "''';",
                "final s4 = 'curve is ${Curves.easeIn}';",
                "final s5 = r'raw' + '${NocheMotion.ms(40)}';",
                r"final s6 = '\${Curves.easeIn}';",
            ]
        )
        violations = mod.scan_dart_source(
            self.FEATURE_FILE, src, set(range(1, 13))
        )
        self.assertEqual(
            [(v.line, v.token) for v in violations],
            [
                (10, "Curves."),
                (11, "NocheMotion.ms("),
            ],
        )

    def test_only_added_lines_are_checked(self) -> None:
        src = "\n".join(
            [
                "final legacyCurve = Curves.easeIn;",
                "final legacyDur = const Duration(milliseconds: 200);",
                "final newLine = NocheMotion.move;",
            ]
        )
        self.assertEqual(mod.scan_dart_source(self.FEATURE_FILE, src, {3}), [])
        self.assertEqual(
            [(v.line, v.token) for v in mod.scan_dart_source(self.FEATURE_FILE, src, {1})],
            [(1, "Curves.")],
        )


class GitIntegrationTests(unittest.TestCase):
    def _run_git(self, repo: Path, *args: str) -> str:
        res = subprocess.run(
            ["git", "-C", str(repo), *args],
            capture_output=True,
            text=True,
            check=False,
        )
        if res.returncode != 0:
            raise AssertionError(
                f"git {' '.join(args)} failed ({res.returncode}): {res.stderr}"
            )
        return res.stdout

    def _init_repo(self, tmp: Path) -> Path:
        self._run_git(tmp, "init", "-q", "-b", "main")
        self._run_git(tmp, "config", "user.name", "Test")
        self._run_git(tmp, "config", "user.email", "test@example.com")
        # Seed baseline files including legacy raw durations/curves on main
        self._write_file(
            tmp,
            "coqui/packages/features/feature_speaking/lib/src/call_mic.dart",
            "final legacy = Curves.easeInOut;\nfinal d = const Duration(milliseconds: 120);\n",
        )
        self._write_file(
            tmp,
            "coqui/packages/core/coqui_ui/lib/src/noche_motion.dart",
            "const enter = Cubic(0.2, 0, 0, 1);\n",
        )
        self._write_file(
            tmp,
            "coqui/app/lib/src/navigator.dart",
            "void nav() {}\n",
        )
        self._run_git(tmp, "add", ".")
        self._run_git(tmp, "commit", "-q", "-m", "base")
        return tmp

    def _write_file(self, repo: Path, rel: str, content: str) -> None:
        p = repo / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8")

    def _commit(self, repo: Path, msg: str) -> None:
        self._run_git(repo, "add", "-A")
        self._run_git(repo, "commit", "-q", "-m", msg)

    def test_feature_curves_fails_and_coqui_ui_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo = self._init_repo(Path(tmpdir))

            # Branch 1: adding Curves.easeIn to a feature file fails
            self._run_git(repo, "checkout", "-q", "-b", "branch-fail", "main")
            self._write_file(
                repo,
                "coqui/packages/features/feature_map/lib/src/map_screen.dart",
                "final c = Curves.easeIn;\n",
            )
            self._commit(repo, "add raw curve in feature")
            violations, _, _ = mod.check_repo(repo, base_arg="main")
            self.assertEqual(len(violations), 1)
            self.assertEqual(violations[0].token, "Curves.")
            self.assertEqual(violations[0].line, 1)
            stdout_buf, stderr_buf = io.StringIO(), io.StringIO()
            with (
                contextlib.redirect_stdout(stdout_buf),
                contextlib.redirect_stderr(stderr_buf),
            ):
                rc = mod.main(["--repo", str(repo), "--base", "main"])
            self.assertEqual(rc, 1)
            self.assertIn("::error file=coqui/packages/features/feature_map/lib/src/map_screen.dart,line=1::", stdout_buf.getvalue())
            self.assertIn("Noche motion guard failed", stderr_buf.getvalue())

            # Branch 2: same line in coqui_ui passes
            self._run_git(repo, "checkout", "-q", "-b", "branch-ui", "main")
            self._write_file(
                repo,
                "coqui/packages/core/coqui_ui/lib/src/piece.dart",
                "final c = Curves.easeIn;\nfinal w = NocheMotion.ms(300);\n",
            )
            self._commit(repo, "add curve in coqui_ui")
            violations, _, _ = mod.check_repo(repo, base_arg="main")
            self.assertEqual(violations, [])
            stdout_buf, stderr_buf = io.StringIO(), io.StringIO()
            with (
                contextlib.redirect_stdout(stdout_buf),
                contextlib.redirect_stderr(stderr_buf),
            ):
                rc = mod.main(["--repo", str(repo), "--base", "main"])
            self.assertEqual(rc, 0)
            self.assertIn("Noche motion guard passed", stdout_buf.getvalue())

    def test_existing_legacy_lines_ignored_and_non_motion_marker_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo = self._init_repo(Path(tmpdir))
            self._run_git(repo, "checkout", "-q", "-b", "branch-ok", "main")

            # Edit unrelated line in file with existing raw Curves/Duration
            self._write_file(
                repo,
                "coqui/packages/features/feature_speaking/lib/src/call_mic.dart",
                "final legacy = Curves.easeInOut;\n"
                "final d = const Duration(milliseconds: 120);\n"
                "final ok = NocheMotion.move;\n",
            )
            # Add non-motion Duration with marker in app/lib
            self._write_file(
                repo,
                "coqui/app/lib/src/navigator.dart",
                "void nav() {\n"
                "  const backGuard = Duration(milliseconds: 800); // non-motion: debounce\n"
                "}\n",
            )
            # Add NocheMotion.ms in package's lib/src/motion.dart
            self._write_file(
                repo,
                "coqui/packages/features/feature_speaking/lib/src/motion.dart",
                "final loadingWait = NocheMotion.ms(300);\n",
            )
            self._commit(repo, "valid changes")
            violations, _, _ = mod.check_repo(repo, base_arg="main")
            self.assertEqual(violations, [])

    def test_app_unmarked_duration_and_misplaced_ms_fail(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo = self._init_repo(Path(tmpdir))
            self._run_git(repo, "checkout", "-q", "-b", "branch-bad", "main")

            self._write_file(
                repo,
                "coqui/app/lib/src/navigator.dart",
                "void nav() {\n"
                "  const d = Duration(milliseconds: 800);\n"
                "  final w = NocheMotion.ms(300);\n"
                "}\n",
            )
            self._commit(repo, "bad app changes")
            violations, _, _ = mod.check_repo(repo, base_arg="main")
            self.assertEqual(
                [(v.line, v.token) for v in violations],
                [(2, "Duration("), (3, "NocheMotion.ms(")],
            )

    def test_rename_from_exempt_into_checked_scope_fails_while_intra_scope_rename_passes(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo = self._init_repo(Path(tmpdir))

            # Moving a file with Cubic( from coqui_ui into feature_map/lib/ must fail
            self._run_git(repo, "checkout", "-q", "-b", "branch-move-in", "main")
            (repo / "coqui/packages/features/feature_map/lib/src").mkdir(
                parents=True, exist_ok=True
            )
            self._run_git(
                repo,
                "mv",
                "coqui/packages/core/coqui_ui/lib/src/noche_motion.dart",
                "coqui/packages/features/feature_map/lib/src/copied_motion.dart",
            )
            self._commit(repo, "move exempt file into feature lib")
            violations, _, _ = mod.check_repo(repo, base_arg="main")
            self.assertEqual(
                [(v.line, v.token) for v in violations],
                [(1, "Cubic(")],
            )

            # Pure rename within feature_speaking/lib/ without adding new lines passes
            self._run_git(repo, "checkout", "-q", "-b", "branch-move-within", "main")
            self._run_git(
                repo,
                "mv",
                "coqui/packages/features/feature_speaking/lib/src/call_mic.dart",
                "coqui/packages/features/feature_speaking/lib/src/call_mic_v2.dart",
            )
            self._commit(repo, "rename within feature lib")
            violations, _, _ = mod.check_repo(repo, base_arg="main")
            self.assertEqual(violations, [])


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromModule(
        sys.modules[__name__]
    )
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
