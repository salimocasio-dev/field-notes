#!/usr/bin/env python3
"""Unit and integration tests for tools/lanes.py, tools/board.py, check_lanes.py, and pr_guardrails.sh."""

from __future__ import annotations

import copy
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[2]
TOOLS_DIR = REPO_ROOT / "tools"
SCRIPTS_DIR = REPO_ROOT / ".github" / "scripts"

if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import board  # noqa: E402
import lanes  # noqa: E402


def _make_issue(number: int, title: str, label_names: list[str]) -> dict:
    return {
        "number": number,
        "title": title,
        "labels": [{"name": name} for name in label_names],
    }


class TempGitRepo:
    def __init__(self, root: Path, lane_map_data: dict | None = None) -> None:
        self.root = root
        self._git(["init", "-q", "-b", "main"])
        data = lane_map_data if lane_map_data is not None else json.loads(
            (TOOLS_DIR / "lanes.json").read_text(encoding="utf-8")
        )
        self.write("tools/lanes.json", json.dumps(data, indent=2) + "\n")
        self.write("README.md", "# temp repo\n")
        self.commit("initial")

    def _git(self, args: list[str]) -> subprocess.CompletedProcess[str]:
        res = subprocess.run(
            [
                "git",
                "-c",
                "user.name=test",
                "-c",
                "user.email=test@example.com",
                "-c",
                "commit.gpgsign=false",
                *args,
            ],
            cwd=str(self.root),
            capture_output=True,
            text=True,
            check=False,
        )
        if res.returncode != 0:
            raise RuntimeError(f"git {' '.join(args)} failed: {res.stderr}")
        return res

    def write(self, rel_path: str, content: str) -> None:
        target = self.root / rel_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def branch(self, name: str) -> None:
        self._git(["checkout", "-q", "-b", name])

    def commit(self, msg: str) -> None:
        self._git(["add", "-A"])
        self._git(["commit", "-q", "--allow-empty", "-m", msg])


class LaneMapCoreTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.lane_map = lanes.load_lane_map(TOOLS_DIR / "lanes.json", validate=True)

    def test_real_lane_map_loads_with_zero_overlaps_and_expected_counts(self) -> None:
        self.assertEqual(lanes.validate_lane_map(self.lane_map), [])
        pkgs = [l for l in self.lane_map.lanes.values() if l.kind == "package"]
        scenes = [l for l in self.lane_map.lanes.values() if l.kind == "scene"]
        self.assertEqual(len(pkgs), 17)
        self.assertEqual(len(scenes), 40)
        self.assertIn("scene.sala", self.lane_map.lanes)
        self.assertIn("scene.sala_dia", self.lane_map.lanes)
        self.assertFalse(lanes.lanes_conflict(self.lane_map, "scene.sala", "scene.sala_dia"))

        # Every scene in coqui/tool/scene_places.json exists in tools/lanes.json.
        places_path = REPO_ROOT / "coqui" / "tool" / "scene_places.json"
        places_data = json.loads(places_path.read_text(encoding="utf-8"))
        for place in places_data["places"]:
            for scene_id in place["scenes"]:
                self.assertIn(f"scene.{scene_id}", self.lane_map.lanes)

    def test_pattern_validation_rejects_malformed_patterns(self) -> None:
        bad_patterns = [
            "",
            "/leading/slash.dart",
            "trailing/slash/",
            "has/../dotdot.dart",
            "has/./dot.dart",
            r"windows\path.dart",
            "empty//segment.dart",
            "**",
            "a/**/b.dart",
            "a/foo**/b.dart",
            "a/**bar",
        ]
        for pat in bad_patterns:
            with self.subTest(pattern=pat):
                self.assertIsNotNone(lanes.validate_pattern(pat))

        good_patterns = [
            "AGENTS.md",
            "docs/**",
            "coqui/packages/features/feature_library/lib/src/reader_*.dart",
            "coqui/packages/features/feature_library/test/screenshots/library_*.png",
        ]
        for pat in good_patterns:
            with self.subTest(pattern=pat):
                self.assertIsNone(lanes.validate_pattern(pat))

    def test_exact_pattern_overlap_and_witness_verification(self) -> None:
        overlapping = [
            ("a/b.dart", "a/b.dart"),
            ("a/**", "a/b/c.dart"),
            ("a/b/c.dart", "a/**"),
            ("a/**", "a/b/**"),
            ("coqui/test/sala_*_test.dart", "coqui/test/sala_dia_*_test.dart"),
            ("dir/a*b*", "dir/*c*"),
            ("dir/.*", "dir/*."),
        ]
        for p1, p2 in overlapping:
            with self.subTest(p1=p1, p2=p2):
                witness = lanes.patterns_overlap(p1, p2)
                self.assertIsNotNone(witness)
                assert witness is not None
                self.assertTrue(lanes.match_pattern(p1, witness), f"{p1} should match {witness}")
                self.assertTrue(lanes.match_pattern(p2, witness), f"{p2} should match {witness}")

        disjoint = [
            ("coqui/ref/pp/**", "coqui/ref/pp_extra/**"),
            ("coqui/test/sala_acts_test.dart", "coqui/test/sala_dia_acts_test.dart"),
            ("dir/a*b", "dir/*c"),
            ("a/b", "a/b/**"),  # '/**' matches strictly inside directory
            ("coqui/packages/features/feature_library/lib/src/reader_*.dart",
             "coqui/packages/features/feature_library/lib/src/reading_home.dart"),
        ]
        for p1, p2 in disjoint:
            with self.subTest(p1=p1, p2=p2):
                self.assertIsNone(lanes.patterns_overlap(p1, p2))

    def test_validate_lane_map_detects_concurrent_overlap_and_reports_witness(self) -> None:
        raw = json.loads((TOOLS_DIR / "lanes.json").read_text(encoding="utf-8"))
        raw["lanes"]["alpha"] = {"kind": "non_package", "paths": ["sandbox/sala_*_test.dart"]}
        raw["lanes"]["beta"] = {"kind": "non_package", "paths": ["sandbox/sala_dia_*_test.dart"]}
        lm, parse_errs = lanes.parse_lane_map(raw)
        self.assertEqual(parse_errs, [])
        assert lm is not None
        errs = lanes.validate_lane_map(lm)
        self.assertEqual(len(errs), 1)
        self.assertIn("alpha", errs[0])
        self.assertIn("beta", errs[0])
        self.assertIn("sandbox/sala_*_test.dart", errs[0])
        self.assertIn("sandbox/sala_dia_*_test.dart", errs[0])
        self.assertIn("sandbox/sala_dia_", errs[0])

    def test_validate_lane_map_detects_parent_cycle(self) -> None:
        raw = json.loads((TOOLS_DIR / "lanes.json").read_text(encoding="utf-8"))
        raw["lanes"]["cyc_a"] = {"kind": "non_package", "parents": ["cyc_b"], "paths": ["cyc/a/**"]}
        raw["lanes"]["cyc_b"] = {"kind": "non_package", "parents": ["cyc_a"], "paths": ["cyc/b/**"]}
        lm, parse_errs = lanes.parse_lane_map(raw)
        self.assertEqual(parse_errs, [])
        assert lm is not None
        errs = lanes.validate_lane_map(lm)
        self.assertTrue(any("cycle" in e for e in errs), errs)

    def test_mutual_exclusion_and_concurrency_matrix(self) -> None:
        lm = self.lane_map
        # Concurrent sub-lanes
        self.assertFalse(lanes.lanes_conflict(lm, "scene.entrada", "scene.pedido"))
        self.assertFalse(lanes.lanes_conflict(lm, "scene.entrada", "feature_story"))
        self.assertFalse(lanes.lanes_conflict(lm, "feature_library.reader", "feature_library.shelf"))
        self.assertFalse(lanes.lanes_conflict(lm, "content.lines.es", "content.lines.fr"))
        self.assertFalse(lanes.lanes_conflict(lm, "content.lines.es", "content.games"))

        # Mutually exclusive parent/child and spans
        self.assertTrue(lanes.lanes_conflict(lm, "scene.entrada", "coqui_scenes"))
        self.assertTrue(lanes.lanes_conflict(lm, "scene.entrada", "coqui_story_checks"))
        self.assertTrue(lanes.lanes_conflict(lm, "scene.entrada", "scene_port"))
        self.assertTrue(lanes.lanes_conflict(lm, "feature_story", "scene_port"))
        self.assertTrue(lanes.lanes_conflict(lm, "feature_library.reader", "feature_library"))
        self.assertTrue(lanes.lanes_conflict(lm, "feature_library.shelf", "feature_library"))
        self.assertTrue(lanes.lanes_conflict(lm, "content.lines.ar", "content"))
        self.assertTrue(lanes.lanes_conflict(lm, "design", "coqui_ui"))
        self.assertTrue(lanes.lanes_conflict(lm, "design", "docs"))

    def test_touched_packages_and_branch_for_lanes(self) -> None:
        lm = self.lane_map
        self.assertEqual(lanes.touched_packages(lm, "scene.entrada"), {"coqui_scenes", "coqui_story_checks"})
        self.assertEqual(lanes.touched_packages(lm, "feature_library.reader"), {"feature_library"})
        self.assertEqual(lanes.touched_packages(lm, "design"), {"coqui_ui"})
        self.assertEqual(lanes.touched_packages(lm, "tool"), set())

        self.assertEqual(lanes.branch_for_lanes(lm, 99, ["feature_words"]), "lane/feature_words/99")
        self.assertEqual(lanes.branch_for_lanes(lm, 42, ["coqui_scenes", "feature_story"]), "story/42")
        self.assertEqual(lanes.branch_for_lanes(lm, 72, ["coqui_platform", "app"]), "lane/app+coqui_platform/72")
        self.assertEqual(lanes.branch_for_lanes(lm, 263, ["tool", "github"]), "lane/github+tool/263")


class BoardTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.lane_map = lanes.load_lane_map(TOOLS_DIR / "lanes.json", validate=True)

    def test_cmd_ready_filters_conflicting_sublanes_and_parents(self) -> None:
        held_claimed = [
            _make_issue(10, "Entrada scene", ["type:story", "status:claimed", "agent:codex", "lane:scene.entrada"]),
            _make_issue(11, "Design pass", ["type:story", "status:claimed", "agent:claude", "lane:design"]),
        ]
        held_review = [
            _make_issue(12, "Whole library", ["type:story", "status:in-review", "agent:codex", "lane:feature_library"]),
        ]
        ready_pool = [
            _make_issue(20, "Pedido scene", ["type:story", "status:ready", "agent:gemini", "lane:scene.pedido"]),
            _make_issue(21, "Whole scenes", ["type:story", "status:ready", "agent:gemini", "lane:coqui_scenes"]),
            _make_issue(22, "Scene port", ["type:story", "status:ready", "agent:any", "lane:scene_port"]),
            _make_issue(23, "Reader polish", ["type:story", "status:ready", "agent:gemini", "lane:feature_library.reader"]),
            _make_issue(24, "UI tokens", ["type:story", "status:ready", "agent:gemini", "lane:coqui_ui"]),
            _make_issue(25, "Docs update", ["type:story", "status:ready", "agent:any", "lane:docs"]),
            _make_issue(26, "Words screen", ["type:story", "status:ready", "agent:any", "lane:feature_words"]),
        ]

        def fake_open_issues(label: str) -> list[dict]:
            if label == "status:claimed":
                return held_claimed
            if label == "status:in-review":
                return held_review
            if label == "type:story,status:ready":
                return ready_pool
            raise AssertionError(f"unexpected open_issues({label!r})")

        buf = io.StringIO()
        with mock.patch.object(board, "open_issues", side_effect=fake_open_issues):
            with redirect_stdout(buf):
                board.cmd_ready("gemini")
        out = buf.getvalue()
        self.assertIn("#20", out)
        self.assertIn("#26", out)
        for blocked_id in ("#21", "#22", "#23", "#24", "#25"):
            self.assertNotIn(blocked_id, out)

    def test_cmd_claim_blocks_conflict_unknown_lane_and_missing_multi_package_label(self) -> None:
        held = [_make_issue(10, "Entrada", ["type:story", "status:claimed", "agent:codex", "lane:scene.entrada"])]

        # Parent blocked by sub-lane
        parent_issue = _make_issue(21, "Whole scenes", ["type:story", "status:ready", "agent:gemini", "lane:coqui_scenes"])
        branch, err = board.evaluate_claim(self.lane_map, parent_issue, "gemini", held)
        self.assertIsNone(branch)
        assert err is not None
        self.assertIn("conflicts with lane:scene.entrada", err)

        # Unknown lane rejected
        unknown_issue = _make_issue(22, "Fake", ["type:story", "status:ready", "agent:gemini", "lane:madeup_lane"])
        branch, err = board.evaluate_claim(self.lane_map, unknown_issue, "gemini", [])
        self.assertIsNone(branch)
        assert err is not None
        self.assertIn("unknown lane", err)

        # Multi-package requires multi-package-ok label
        mp_no_label = _make_issue(
            72, "Platform+App", ["type:story", "status:ready", "agent:gemini", "lane:app", "lane:coqui_platform"]
        )
        branch, err = board.evaluate_claim(self.lane_map, mp_no_label, "gemini", [])
        self.assertIsNone(branch)
        assert err is not None
        self.assertIn("multi-package-ok", err)

        # With multi-package-ok label, succeeds
        mp_with_label = _make_issue(
            72,
            "Platform+App",
            ["type:story", "status:ready", "agent:gemini", "lane:app", "lane:coqui_platform", "multi-package-ok"],
        )
        branch, err = board.evaluate_claim(self.lane_map, mp_with_label, "gemini", [])
        self.assertIsNone(err)
        self.assertEqual(branch, "lane/app+coqui_platform/72")

        # scene_port combination works without multi-package-ok -> story/<n>
        sp_issue = _make_issue(
            42, "Scene port", ["type:story", "status:ready", "agent:gemini", "lane:coqui_scenes", "lane:feature_story"]
        )
        branch, err = board.evaluate_claim(self.lane_map, sp_issue, "gemini", [])
        self.assertIsNone(err)
        self.assertEqual(branch, "story/42")

    def test_cmd_claim_cross_sublane_race_resolution(self) -> None:
        # #102 (scene.entrada) is claimed by gemini while #101 (coqui_scenes) wins the race simultaneously.
        issue_102 = _make_issue(102, "Entrada", ["type:story", "status:ready", "agent:gemini", "lane:scene.entrada"])
        claimed_101 = _make_issue(101, "Whole scenes", ["type:story", "status:claimed", "agent:claude", "lane:coqui_scenes"])
        claimed_102 = _make_issue(102, "Entrada", ["type:story", "status:claimed", "agent:gemini", "lane:scene.entrada"])

        calls: list[tuple[str, str]] = []
        claimed_state = {"after_claim": False}

        def fake_gh(method: str, path: str, fields=None):
            calls.append((method, path))
            if method == "GET" and path == "issues/102":
                return issue_102
            if method == "GET" and path.startswith("issues?state=open&labels=status:claimed"):
                return [claimed_101, claimed_102] if claimed_state["after_claim"] else []
            if method == "GET" and path.startswith("issues?state=open&labels=status:in-review"):
                return []
            if method == "PUT" and path == "issues/102/labels":
                if "status:claimed" in fields["labels"]:
                    claimed_state["after_claim"] = True
                return {}
            if method == "POST" and path == "issues/102/comments":
                return {}
            if method == "GET" and path == "issues/101/comments?per_page=100":
                return [{"created_at": "2026-11-27T10:00:00Z", "id": 1, "body": "CLAIM claude\nBranch: `lane/coqui_scenes/101`"}]
            if method == "GET" and path == "issues/102/comments?per_page=100":
                return [{"created_at": "2026-11-27T10:00:01Z", "id": 2, "body": "CLAIM gemini\nBranch: `lane/scene.entrada/102`"}]
            raise AssertionError(f"unexpected gh({method!r}, {path!r})")

        with mock.patch.object(board, "gh", side_effect=fake_gh):
            with self.assertRaises(SystemExit) as ctx:
                board.cmd_claim(102, "gemini")
        self.assertIn("Lost the race to #101", str(ctx.exception))
        # Verify #102 was released back to status:ready
        put_calls = [c for c in calls if c[0] == "PUT" and c[1] == "issues/102/labels"]
        self.assertEqual(len(put_calls), 2)

    def test_board_dry_run_cli(self) -> None:
        res = subprocess.run(
            [sys.executable, str(TOOLS_DIR / "board.py"), "dry-run"],
            cwd=str(REPO_ROOT),
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(res.returncode, 0, res.stderr + res.stdout)
        self.assertIn("dry-run: ok", res.stdout)
        self.assertIn("lane/scene.entrada/301", res.stdout)
        self.assertIn("lane/feature_library.reader/401", res.stdout)
        self.assertIn("lane/feature_library.shelf/402", res.stdout)


class CheckLanesAndGuardrailsIntegrationTests(unittest.TestCase):
    def _run_check_lanes(self, repo: TempGitRepo, head_ref: str, base: str = "main") -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPTS_DIR / "check_lanes.py"), "--base", base, "--head-ref", head_ref],
            cwd=str(repo.root),
            capture_output=True,
            text=True,
            check=False,
        )

    def _run_pr_guardrails(self, repo: TempGitRepo, head_ref: str, base: str = "main") -> subprocess.CompletedProcess[str]:
        env = dict(os.environ)
        env["COQUI_SKIP_LANES_SELF_TEST"] = "1"
        return subprocess.run(
            ["bash", str(SCRIPTS_DIR / "pr_guardrails.sh"), "--base", base, "--head-ref", head_ref],
            cwd=str(repo.root),
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_valid_and_straying_lane_branches(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            repo.branch("lane/scene.entrada/301")
            repo.write("coqui/packages/core/coqui_scenes/lib/src/entrada/scene.dart", "// entrada\n")
            repo.write("coqui/packages/core/coqui_scenes/tool/dev_main.dart", "// generated manifest\n")
            repo.write("coqui/ref/pp/index.json", "{}\n")
            repo.write("coqui/requests/301-note.md", "# req\n")
            repo.commit("valid entrada work")
            res = self._run_check_lanes(repo, "lane/scene.entrada/301")
            self.assertEqual(res.returncode, 0, res.stdout + res.stderr)

            # Straying into another scene fails
            repo.write("coqui/packages/core/coqui_scenes/lib/src/pedido/scene.dart", "// stray\n")
            repo.commit("stray into pedido")
            res = self._run_check_lanes(repo, "lane/scene.entrada/301")
            self.assertNotEqual(res.returncode, 0)
            self.assertIn("::error file=coqui/packages/core/coqui_scenes/lib/src/pedido/scene.dart::", res.stdout)

    def test_madeup_lane_branch_rejected_by_pr_guardrails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            repo.branch("lane/madeup_lane/999")
            repo.write("docs/note.md", "hi\n")
            repo.commit("madeup")
            res = self._run_pr_guardrails(repo, "lane/madeup_lane/999")
            self.assertNotEqual(res.returncode, 0)
            self.assertIn("unknown lane 'madeup_lane'", res.stdout)

    def test_story_branch_allowed_and_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            repo.branch("story/42")
            repo.write("coqui/packages/core/coqui_scenes/lib/src/plaza/a.dart", "// a\n")
            repo.write("coqui/packages/features/feature_story/lib/src/b.dart", "// b\n")
            repo.write("coqui/packages/coqui_story_checks/test/plaza_stories_test.dart", "// c\n")
            repo.write("coqui/ref/pp/plaza/sheet.json", "{}\n")
            repo.write("coqui/requests/42.md", "req\n")
            repo.commit("valid story")
            res = self._run_check_lanes(repo, "story/42")
            self.assertEqual(res.returncode, 0, res.stdout + res.stderr)

            repo.write("coqui/packages/core/coqui_contracts/lib/x.dart", "// disallowed\n")
            repo.commit("stray into contracts")
            res = self._run_check_lanes(repo, "story/42")
            self.assertNotEqual(res.returncode, 0)
            self.assertIn("coqui/packages/core/coqui_contracts/lib/x.dart", res.stdout)

    def test_multi_lane_combinations(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            repo.branch("lane/github+tool/263")
            repo.write(".github/scripts/helper.py", "# ok\n")
            repo.write("tools/helper.py", "# ok\n")
            repo.write("coqui/tool/helper.dart", "// ok\n")
            repo.commit("github+tool")
            res = self._run_check_lanes(repo, "lane/github+tool/263")
            self.assertEqual(res.returncode, 0, res.stdout + res.stderr)

            # Unsanctioned multi-package rejected
            res_bad = self._run_check_lanes(repo, "lane/feature_words+feature_map/99")
            self.assertNotEqual(res_bad.returncode, 0)
            self.assertIn("unsanctioned", res_bad.stdout)

        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            repo.branch("lane/app+coqui_platform/72")
            repo.write("coqui/app/lib/main.dart", "// app\n")
            repo.write("coqui/packages/core/coqui_platform/lib/p.dart", "// plat\n")
            repo.commit("sanctioned platform_app")
            res = self._run_check_lanes(repo, "lane/app+coqui_platform/72")
            self.assertEqual(res.returncode, 0, res.stdout + res.stderr)

    def test_unrestricted_branch_allows_non_packages_and_blocks_packages(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            repo.branch("tool/263")
            repo.write("tools/helper.py", "# ok\n")
            repo.commit("tool only")
            res = self._run_pr_guardrails(repo, "tool/263")
            self.assertEqual(res.returncode, 0, res.stdout + res.stderr)

            repo.write("coqui/packages/features/feature_words/lib/x.dart", "// blocked\n")
            repo.commit("touch package on tool branch")
            res = self._run_pr_guardrails(repo, "tool/263")
            self.assertNotEqual(res.returncode, 0)
            self.assertIn("coqui/packages/", res.stdout)

    def test_adding_brand_new_lane_to_json_only_works_without_code_changes(self) -> None:
        raw = copy.deepcopy(json.loads((TOOLS_DIR / "lanes.json").read_text(encoding="utf-8")))
        raw["lanes"]["experimental_lab"] = {
            "kind": "non_package",
            "paths": ["lab/**"],
        }
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp), lane_map_data=raw)
            repo.branch("lane/experimental_lab/777")
            repo.write("lab/experiment.txt", "hello\n")
            repo.commit("owned lab path")

            # Works in check_lanes.py
            res_ok = self._run_check_lanes(repo, "lane/experimental_lab/777")
            self.assertEqual(res_ok.returncode, 0, res_ok.stdout + res_ok.stderr)

            # Works in pr_guardrails.sh
            res_guard = self._run_pr_guardrails(repo, "lane/experimental_lab/777")
            self.assertEqual(res_guard.returncode, 0, res_guard.stdout + res_guard.stderr)

            # Works in board.py claim evaluation
            temp_lm = lanes.load_lane_map(repo.root / "tools" / "lanes.json", validate=True)
            issue = _make_issue(777, "Lab test", ["type:story", "status:ready", "agent:gemini", "lane:experimental_lab"])
            branch, err = board.evaluate_claim(temp_lm, issue, "gemini", [])
            self.assertIsNone(err)
            self.assertEqual(branch, "lane/experimental_lab/777")

            # Straying out of lab/** fails immediately
            repo.write("docs/stray.md", "oops\n")
            repo.commit("stray")
            res_fail = self._run_check_lanes(repo, "lane/experimental_lab/777")
            self.assertNotEqual(res_fail.returncode, 0)
            self.assertIn("docs/stray.md", res_fail.stdout)

    def test_invalid_lanes_json_fails_even_on_unrestricted_branch(self) -> None:
        raw = copy.deepcopy(json.loads((TOOLS_DIR / "lanes.json").read_text(encoding="utf-8")))
        raw["lanes"]["clash_a"] = {"kind": "non_package", "paths": ["clash/**"]}
        raw["lanes"]["clash_b"] = {"kind": "non_package", "paths": ["clash/sub/**"]}
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp), lane_map_data=raw)
            repo.branch("tool/263")
            repo.write("tools/ok.py", "# ok\n")
            repo.commit("work")
            res = self._run_check_lanes(repo, "tool/263")
            self.assertNotEqual(res.returncode, 0)
            self.assertIn("::error file=tools/lanes.json::", res.stdout)
            self.assertIn("clash_a", res.stdout)
            self.assertIn("clash_b", res.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
