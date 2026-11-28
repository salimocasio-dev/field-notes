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

    def test_validate_lane_map_rejects_invalid_contracts_branch_rules(self) -> None:
        base_raw = json.loads((TOOLS_DIR / "lanes.json").read_text(encoding="utf-8"))

        # Bad contracts_prefix (missing trailing slash)
        bad_prefix = copy.deepcopy(base_raw)
        bad_prefix["branch_rules"]["contracts_prefix"] = "contracts"
        _, parse_errs = lanes.parse_lane_map(bad_prefix)
        self.assertTrue(any("contracts_prefix" in e for e in parse_errs), parse_errs)

        # Empty contracts_owner_lane
        empty_owner = copy.deepcopy(base_raw)
        empty_owner["branch_rules"]["contracts_owner_lane"] = ""
        _, parse_errs = lanes.parse_lane_map(empty_owner)
        self.assertTrue(any("contracts_owner_lane" in e for e in parse_errs), parse_errs)

        # Unknown contracts_owner_lane
        unknown_owner = copy.deepcopy(base_raw)
        unknown_owner["branch_rules"]["contracts_owner_lane"] = "no_such_lane"
        lm, parse_errs = lanes.parse_lane_map(unknown_owner)
        self.assertEqual(parse_errs, [])
        assert lm is not None
        val_errs = lanes.validate_lane_map(lm)
        self.assertTrue(any("contracts_owner_lane" in e and "no_such_lane" in e for e in val_errs), val_errs)

        # Invalid contracts_required_lib_paths (empty, non-list, bad glob)
        empty_lib = copy.deepcopy(base_raw)
        empty_lib["branch_rules"]["contracts_required_lib_paths"] = []
        _, parse_errs = lanes.parse_lane_map(empty_lib)
        self.assertTrue(any("contracts_required_lib_paths" in e for e in parse_errs), parse_errs)

        nonlist_lib = copy.deepcopy(base_raw)
        nonlist_lib["branch_rules"]["contracts_required_lib_paths"] = "coqui/packages/core/coqui_contracts/lib/**"
        _, parse_errs = lanes.parse_lane_map(nonlist_lib)
        self.assertTrue(any("contracts_required_lib_paths" in e for e in parse_errs), parse_errs)

        bad_lib_glob = copy.deepcopy(base_raw)
        bad_lib_glob["branch_rules"]["contracts_required_lib_paths"] = ["coqui/**/platform.dart"]
        lm, parse_errs = lanes.parse_lane_map(bad_lib_glob)
        self.assertEqual(parse_errs, [])
        assert lm is not None
        val_errs = lanes.validate_lane_map(lm)
        self.assertTrue(any("contracts_required_lib_paths" in e for e in val_errs), val_errs)

        # Empty contracts_conformance_paths
        empty_paths = copy.deepcopy(base_raw)
        empty_paths["branch_rules"]["contracts_conformance_paths"] = []
        _, parse_errs = lanes.parse_lane_map(empty_paths)
        self.assertTrue(any("contracts_conformance_paths" in e for e in parse_errs), parse_errs)

        # Non-list contracts_conformance_paths
        nonlist_paths = copy.deepcopy(base_raw)
        nonlist_paths["branch_rules"]["contracts_conformance_paths"] = "coqui/packages/**"
        _, parse_errs = lanes.parse_lane_map(nonlist_paths)
        self.assertTrue(any("contracts_conformance_paths" in e for e in parse_errs), parse_errs)

        # Malformed glob pattern in contracts_conformance_paths
        bad_glob = copy.deepcopy(base_raw)
        bad_glob["branch_rules"]["contracts_conformance_paths"] = ["coqui/**/lib.dart"]
        lm, parse_errs = lanes.parse_lane_map(bad_glob)
        self.assertEqual(parse_errs, [])
        assert lm is not None
        val_errs = lanes.validate_lane_map(lm)
        self.assertTrue(any("contracts_conformance_paths" in e for e in val_errs), val_errs)

        # Invalid contracts_denied_paths (non-list and bad glob; empty list is allowed)
        empty_denied = copy.deepcopy(base_raw)
        empty_denied["branch_rules"]["contracts_denied_paths"] = []
        lm, parse_errs = lanes.parse_lane_map(empty_denied)
        self.assertEqual(parse_errs, [])
        assert lm is not None
        self.assertEqual(lanes.validate_lane_map(lm), [])

        nonlist_denied = copy.deepcopy(base_raw)
        nonlist_denied["branch_rules"]["contracts_denied_paths"] = "historia/cuentos/**"
        _, parse_errs = lanes.parse_lane_map(nonlist_denied)
        self.assertTrue(any("contracts_denied_paths" in e for e in parse_errs), parse_errs)

        bad_denied_glob = copy.deepcopy(base_raw)
        bad_denied_glob["branch_rules"]["contracts_denied_paths"] = ["coqui/**/call.dart"]
        lm, parse_errs = lanes.parse_lane_map(bad_denied_glob)
        self.assertEqual(parse_errs, [])
        assert lm is not None
        val_errs = lanes.validate_lane_map(lm)
        self.assertTrue(any("contracts_denied_paths" in e for e in val_errs), val_errs)

        # Invalid contracts_max_conformance_changed_lines (0, -1, "6", True)
        for bad_max in (0, -1, "6", True):
            with self.subTest(bad_max=bad_max):
                raw = copy.deepcopy(base_raw)
                raw["branch_rules"]["contracts_max_conformance_changed_lines"] = bad_max
                _, parse_errs = lanes.parse_lane_map(raw)
                self.assertTrue(
                    any("contracts_max_conformance_changed_lines" in e for e in parse_errs),
                    parse_errs,
                )

    def test_resolve_contracts_branch_and_malformed_names(self) -> None:
        lm = self.lane_map
        res = lanes.resolve_branch(lm, "contracts/260")
        self.assertTrue(res.restricted)
        self.assertIsNone(res.error)
        self.assertEqual(res.lane_ids, ("coqui_contracts",))
        self.assertEqual(res.owner_paths, ("coqui/packages/core/coqui_contracts/**",))
        self.assertEqual(res.required_lib_paths, ("coqui/packages/core/coqui_contracts/lib/**",))
        self.assertEqual(res.conformance_max_changed_lines, 6)
        self.assertEqual(res.conformance_extensions, (".dart",))
        self.assertIn("coqui/packages/**", res.allowed_paths)
        self.assertIn("coqui/app/**", res.allowed_paths)
        self.assertIn("coqui/packages/core/coqui_platform/lib/src/call/**", res.denied_paths)

        for bad in ("contracts/", "contracts/abc", "contracts/260/extra", "contracts/260-fix"):
            with self.subTest(branch=bad):
                bad_res = lanes.resolve_branch(lm, bad)
                self.assertTrue(bad_res.restricted)
                self.assertIsNotNone(bad_res.error)
                assert bad_res.error is not None
                self.assertIn("contracts/<number>", bad_res.error)

    def test_resolve_branch_safe_error_on_unvalidated_missing_lanes(self) -> None:
        base_raw = json.loads((TOOLS_DIR / "lanes.json").read_text(encoding="utf-8"))

        missing_story = copy.deepcopy(base_raw)
        missing_story["branch_rules"]["story_default_lane"] = "missing_scene_port"
        lm_story, _ = lanes.parse_lane_map(missing_story)
        assert lm_story is not None
        res_story = lanes.resolve_branch(lm_story, "story/42")
        self.assertTrue(res_story.restricted)
        self.assertIsNotNone(res_story.error)
        assert res_story.error is not None
        self.assertIn("story_default_lane", res_story.error)
        self.assertIn("missing_scene_port", res_story.error)

        missing_owner = copy.deepcopy(base_raw)
        missing_owner["branch_rules"]["contracts_owner_lane"] = "missing_contracts"
        lm_owner, _ = lanes.parse_lane_map(missing_owner)
        assert lm_owner is not None
        res_owner = lanes.resolve_branch(lm_owner, "contracts/260")
        self.assertTrue(res_owner.restricted)
        self.assertIsNotNone(res_owner.error)
        assert res_owner.error is not None
        self.assertIn("contracts_owner_lane", res_owner.error)
        self.assertIn("missing_contracts", res_owner.error)


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

    def test_contracts_branch_valid_conformance_owner_only_and_requests_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            # Pre-create existing files on main so conformance edits are status M.
            repo.write("coqui/packages/core/coqui_contracts/lib/src/platform.dart", "// old contracts\n")
            repo.write("coqui/packages/core/coqui_contracts/AGENTS.md", "# coqui_contracts\n")
            repo.write("coqui/packages/core/coqui_platform/lib/src/store.dart", "// old store\n")
            repo.write("coqui/packages/core/coqui_testing/lib/src/fakes.dart", "// old fakes\n")
            repo.write("coqui/packages/features/feature_library/lib/src/reader.dart", "// old reader\n")
            repo.write("coqui/app/lib/src/main.dart", "// old app\n")
            repo.commit("seed existing files on main")

            # (a) Contracts lib + small in-place (<= 6 changed lines) .dart conformance edits + requests/
            repo.branch("contracts/260")
            repo.write("coqui/packages/core/coqui_contracts/lib/src/platform.dart", "// new contracts\n")
            repo.write("coqui/packages/core/coqui_platform/lib/src/store.dart", "// conform store\n")
            repo.write("coqui/packages/core/coqui_testing/lib/src/fakes.dart", "// conform fakes\n")
            repo.write("coqui/packages/features/feature_library/lib/src/reader.dart", "// conform reader\n")
            repo.write("coqui/app/lib/src/main.dart", "// conform app\n")
            repo.write("coqui/requests/260-note.md", "# req\n")
            repo.commit("contracts lib plus small conformance edits")

            res_cl = self._run_check_lanes(repo, "contracts/260")
            self.assertEqual(res_cl.returncode, 0, res_cl.stdout + res_cl.stderr)
            res_pg = self._run_pr_guardrails(repo, "contracts/260")
            self.assertEqual(res_pg.returncode, 0, res_pg.stdout + res_pg.stderr)

            # (b) Owner-only AGENTS.md edit (no other packages)
            repo._git(["checkout", "-q", "main"])
            repo.branch("contracts/261")
            repo.write("coqui/packages/core/coqui_contracts/AGENTS.md", "# coqui_contracts\n- Standing rule.\n")
            repo.commit("owner-only AGENTS.md")

            res_cl2 = self._run_check_lanes(repo, "contracts/261")
            self.assertEqual(res_cl2.returncode, 0, res_cl2.stdout + res_cl2.stderr)
            res_pg2 = self._run_pr_guardrails(repo, "contracts/261")
            self.assertEqual(res_pg2.returncode, 0, res_pg2.stdout + res_pg2.stderr)

            # Requests-only on contracts/<n>
            repo._git(["checkout", "-q", "main"])
            repo.branch("contracts/262")
            repo.write("coqui/requests/262-note.md", "# req only\n")
            repo.commit("requests only")

            res_cl3 = self._run_check_lanes(repo, "contracts/262")
            self.assertEqual(res_cl3.returncode, 0, res_cl3.stdout + res_cl3.stderr)
            res_pg3 = self._run_pr_guardrails(repo, "contracts/262")
            self.assertEqual(res_pg3.returncode, 0, res_pg3.stdout + res_pg3.stderr)

    def test_contracts_branch_rejects_conformance_without_contracts_lib_change(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            repo.write("coqui/packages/core/coqui_contracts/AGENTS.md", "# coqui_contracts\n")
            repo.write("coqui/packages/core/coqui_platform/lib/src/store.dart", "// old store\n")
            repo.write("coqui/app/lib/src/main.dart", "// old app\n")
            repo.commit("seed files on main")

            # (c) Only coqui_contracts/AGENTS.md changed + 1-line conformance edit in coqui_platform -> FAIL
            repo.branch("contracts/260")
            repo.write("coqui/packages/core/coqui_contracts/AGENTS.md", "# coqui_contracts\n- Standing rule.\n")
            repo.write("coqui/packages/core/coqui_platform/lib/src/store.dart", "// conform store\n")
            repo.write("coqui/app/lib/src/main.dart", "// conform app\n")
            repo.write("coqui/requests/260-note.md", "# req\n")
            repo.commit("agents-only plus conformance")

            for runner in (self._run_check_lanes, self._run_pr_guardrails):
                res = runner(repo, "contracts/260")
                self.assertNotEqual(res.returncode, 0)
                self.assertIn("::error file=coqui/packages/core/coqui_platform/lib/src/store.dart::", res.stdout)
                self.assertIn("::error file=coqui/app/lib/src/main.dart::", res.stdout)
                self.assertIn(
                    "for conformance only alongside changes in coqui/packages/core/coqui_contracts/lib/**",
                    res.stdout,
                )
                self.assertNotIn("coqui/requests/260-note.md", res.stdout)

    def test_contracts_branch_rejects_oversized_added_deleted_and_non_dart_conformance_edits(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            repo.write("coqui/packages/core/coqui_contracts/lib/src/platform.dart", "// old\n")
            repo.write("coqui/packages/core/coqui_platform/lib/src/big.dart", "l1\nl2\nl3\nl4\n")
            repo.write("coqui/packages/core/coqui_platform/lib/src/old.dart", "// delete me\n")
            repo.write("coqui/packages/core/coqui_platform/pubspec.yaml", "name: coqui_platform\n")
            repo.write("coqui/packages/core/coqui_platform/AGENTS.md", "# coqui_platform\n")
            repo.commit("seed files on main")

            # (d) > 6 changed lines, (e) added (A) and deleted (D) .dart files, (f) non-.dart files
            repo.branch("contracts/260")
            repo.write("coqui/packages/core/coqui_contracts/lib/src/platform.dart", "// new\n")
            repo.write("coqui/packages/core/coqui_platform/lib/src/big.dart", "n1\nn2\nn3\nn4\n")  # 4+4 = 8 > 6
            repo.write("coqui/packages/core/coqui_platform/lib/src/added.dart", "// new file\n")
            (repo.root / "coqui/packages/core/coqui_platform/lib/src/old.dart").unlink()
            repo.write("coqui/packages/core/coqui_platform/pubspec.yaml", "name: coqui_platform\n# edit\n")
            repo.write("coqui/packages/core/coqui_platform/AGENTS.md", "# coqui_platform\n- note\n")
            repo.commit("invalid conformance edits")

            for runner in (self._run_check_lanes, self._run_pr_guardrails):
                res = runner(repo, "contracts/260")
                self.assertNotEqual(res.returncode, 0)
                self.assertIn("::error file=coqui/packages/core/coqui_platform/lib/src/big.dart::", res.stdout)
                self.assertIn("changed 8 lines", res.stdout)
                self.assertIn("exceeding max 6", res.stdout)
                self.assertIn("::error file=coqui/packages/core/coqui_platform/lib/src/added.dart::", res.stdout)
                self.assertIn("got status 'A'", res.stdout)
                self.assertIn("::error file=coqui/packages/core/coqui_platform/lib/src/old.dart::", res.stdout)
                self.assertIn("got status 'D'", res.stdout)
                self.assertIn("::error file=coqui/packages/core/coqui_platform/pubspec.yaml::", res.stdout)
                self.assertIn("::error file=coqui/packages/core/coqui_platform/AGENTS.md::", res.stdout)
                self.assertIn("must target .dart files only", res.stdout)

    def test_contracts_branch_rejects_locked_denied_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            repo.write("coqui/packages/core/coqui_contracts/lib/src/platform.dart", "// old\n")
            repo.write("coqui/packages/core/coqui_platform/lib/src/call/call.dart", "// old call\n")
            repo.write("coqui/packages/core/coqui_platform/lib/src/web/el_conv.dart", "// old el\n")
            repo.write("coqui/packages/core/coqui_platform/assets/elevenlabs/lib.js", "// old js\n")
            repo.write("coqui/app/android/app/build.gradle.kts", "// old gradle\n")
            repo.commit("seed locked files on main")

            # (g) 1-line edit in locked/denied paths alongside coqui_contracts/lib/**
            repo.branch("contracts/260")
            repo.write("coqui/packages/core/coqui_contracts/lib/src/platform.dart", "// new\n")
            repo.write("coqui/packages/core/coqui_platform/lib/src/call/call.dart", "// edited call\n")
            repo.write("coqui/packages/core/coqui_platform/lib/src/web/el_conv.dart", "// edited el\n")
            repo.write("coqui/packages/core/coqui_platform/assets/elevenlabs/lib.js", "// edited js\n")
            repo.write("coqui/app/android/app/build.gradle.kts", "// edited gradle\n")
            repo.commit("edit locked paths")

            for runner in (self._run_check_lanes, self._run_pr_guardrails):
                res = runner(repo, "contracts/260")
                self.assertNotEqual(res.returncode, 0)
                for locked_path in (
                    "coqui/packages/core/coqui_platform/lib/src/call/call.dart",
                    "coqui/packages/core/coqui_platform/lib/src/web/el_conv.dart",
                    "coqui/packages/core/coqui_platform/assets/elevenlabs/lib.js",
                    "coqui/app/android/app/build.gradle.kts",
                ):
                    self.assertIn(f"::error file={locked_path}::", res.stdout)
                self.assertIn("locked/denied path", res.stdout)

    def test_contracts_branch_rejects_non_package_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            repo.branch("contracts/260")
            repo.write("coqui/packages/core/coqui_contracts/lib/src/platform.dart", "// contracts\n")
            repo.write("docs/guide.md", "# nope\n")
            repo.write(".github/scripts/helper.py", "# nope\n")
            repo.write("tools/helper.py", "# nope\n")
            repo.write("coqui/tool/helper.dart", "// nope\n")
            repo.commit("non-package paths")

            for runner in (self._run_check_lanes, self._run_pr_guardrails):
                res = runner(repo, "contracts/260")
                self.assertNotEqual(res.returncode, 0)
                for bad_path in (
                    "docs/guide.md",
                    ".github/scripts/helper.py",
                    "tools/helper.py",
                    "coqui/tool/helper.dart",
                ):
                    self.assertIn(f"::error file={bad_path}::", res.stdout)

    def test_contracts_branch_rejects_malformed_branch_names(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = TempGitRepo(Path(tmp))
            repo.branch("work")
            repo.write("coqui/packages/core/coqui_contracts/lib/src/platform.dart", "// contracts\n")
            repo.commit("contracts")

            for bad_branch in ("contracts/", "contracts/abc", "contracts/260/extra", "contracts/260-fix"):
                with self.subTest(branch=bad_branch):
                    res_cl = self._run_check_lanes(repo, bad_branch)
                    self.assertNotEqual(res_cl.returncode, 0)
                    self.assertIn("contracts/<number>", res_cl.stdout)
                    res_pg = self._run_pr_guardrails(repo, bad_branch)
                    self.assertNotEqual(res_pg.returncode, 0)
                    self.assertIn("contracts/<number>", res_pg.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
