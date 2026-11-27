#!/usr/bin/env python3
"""Unit tests for .github/scripts/claude_pr_review.py using Python stdlib only."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import claude_pr_review as cpr


class IsNoneItemTests(unittest.TestCase):
    def test_empty_and_bullet_only_are_none(self) -> None:
        cases = ["", "   ", "-", "*"]
        for raw in cases:
            with self.subTest(raw=raw):
                self.assertTrue(cpr._is_none_item(raw))

    def test_single_chunk_none_variants_are_none(self) -> None:
        cases = [
            "None",
            "none.",
            "**None**.",
            "**None.**",
            "`None`.",
            "(None).",
            "(None.)",
            "N/A",
            "No blockers",
            "No blockers found.",
            "No warnings",
            "No notes",
            "No warnings / notes",
            "No warnings or notes",
        ]
        for raw in cases:
            with self.subTest(raw=raw):
                self.assertTrue(cpr._is_none_item(raw))

    def test_per_chunk_none_variants_are_none(self) -> None:
        cases = [
            "None in this chunk",
            "None in this chunk.",
            "None in this chunk (1 of 3)",
            "None in this chunk (1 of 3).",
            "None in this chunk (2 of 4).",
            "None in this chunk (chunk 2 of 4).",
            "None in this chunk (part 1/3).",
            "No blockers in this chunk",
            "No blockers in this chunk (1 of 3).",
            "No blockers found in this chunk.",
            "None in chunk 1 of 3.",
            "None in chunk 2/4.",
            "None in chunk 1.",
            "None for this chunk.",
            "None (this chunk)",
            "None (in this chunk)",
            "None (1 of 3).",
            "**None in this chunk (1 of 3).**",
            "  - None in this chunk (1 of 3).",
        ]
        for raw in cases:
            with self.subTest(raw=raw):
                self.assertTrue(cpr._is_none_item(raw))

    def test_real_findings_and_exceptions_are_not_none(self) -> None:
        cases = [
            "None of the tests verify the fallback path.",
            "None of these files pass dart format.",
            "None — wait, foo.dart breaks...",
            "None — wait, foo.dart breaks the build.",
            "None - actually foo.dart breaks.",
            "None in this chunk — wait, foo.dart breaks.",
            "None in this chunk, except foo.dart breaks the build.",
            "None in this chunk; however, bar.dart leaks secrets.",
            "None in this chunk. Wait: foo.dart modifies historia/cuentos/.",
            "None (except foo.dart breaks).",
            "None (see below)",
            "(None) — wait, foo.dart breaks (1 of 3).",
            "None...",
            "no_blockers",
            "No blockers in this chunk, but foo.dart imports coqui_contracts/src/.",
        ]
        for raw in cases:
            with self.subTest(raw=raw):
                self.assertFalse(cpr._is_none_item(raw))


class ParseAndMergeReviewTests(unittest.TestCase):
    def test_single_chunk_none_inline_and_bulleted(self) -> None:
        inline_review = (
            "- **Verdict:** APPROVE\n"
            "- **Blockers:** None\n"
            "- **Warnings / Notes:** None\n"
        )
        verdict, blockers, warnings = cpr.parse_review(inline_review)
        self.assertEqual(verdict, "APPROVE")
        self.assertEqual(blockers, [])
        self.assertEqual(warnings, [])
        self.assertFalse(cpr.review_has_blockers(inline_review))

        bulleted_review = (
            "- **Verdict:** APPROVE\n"
            "- **Blockers:**\n"
            "  - None\n"
            "- **Warnings / Notes:**\n"
            "  - None\n"
        )
        verdict, blockers, warnings = cpr.parse_review(bulleted_review)
        self.assertEqual(verdict, "APPROVE")
        self.assertEqual(blockers, [])
        self.assertEqual(warnings, [])
        self.assertFalse(cpr.review_has_blockers(bulleted_review))

    def test_multi_chunk_all_clean_merges_to_approve(self) -> None:
        chunks = [
            (
                "- **Verdict:** APPROVE\n"
                "- **Blockers:** None in this chunk (1 of 3).\n"
                "- **Warnings / Notes:** No warnings in this chunk\n"
            ),
            (
                "- **Verdict:** APPROVE\n"
                "- **Blockers:**\n"
                "  - None in this chunk.\n"
                "- **Warnings / Notes:** No notes in this chunk\n"
            ),
            (
                "- **Verdict:** APPROVE\n"
                "- **Blockers:** No blockers in this chunk (3 of 3).\n"
                "- **Warnings / Notes:** None\n"
            ),
        ]
        merged = cpr.merge_chunk_reviews(chunks)
        verdict, blockers, warnings = cpr.parse_review(merged)
        self.assertEqual(verdict, "APPROVE")
        self.assertEqual(blockers, [])
        self.assertEqual(warnings, [])
        self.assertIn("- **Blockers:** None", merged)
        self.assertFalse(cpr.review_has_blockers(merged))

    def test_mixed_chunks_changes_requested_and_mistaken_approve(self) -> None:
        clean_chunk = (
            "- **Verdict:** APPROVE\n"
            "- **Blockers:** None in this chunk (1 of 2).\n"
            "- **Warnings / Notes:** None\n"
        )
        blocker_text = "foo.dart edits coqui_contracts directly."

        for chunk2_verdict in ("CHANGES REQUESTED", "APPROVE"):
            with self.subTest(chunk2_verdict=chunk2_verdict):
                chunk2 = (
                    f"- **Verdict:** {chunk2_verdict}\n"
                    "- **Blockers:**\n"
                    f"  - {blocker_text}\n"
                    "- **Warnings / Notes:** None\n"
                )
                merged = cpr.merge_chunk_reviews([clean_chunk, chunk2])
                verdict, blockers, _ = cpr.parse_review(merged)
                self.assertEqual(verdict, "CHANGES REQUESTED")
                self.assertEqual(blockers, [blocker_text])
                self.assertTrue(cpr.review_has_blockers(merged))

    def test_same_chunk_none_followed_by_real_blocker_preserves_blocker(self) -> None:
        real_blocker = "bar.dart modifies historia/cuentos/."
        bulleted = (
            "- **Verdict:** APPROVE\n"
            "- **Blockers:**\n"
            "  - None in this chunk (1 of 3).\n"
            f"  - {real_blocker}\n"
            "- **Warnings / Notes:** None\n"
        )
        inline_then_bullet = (
            "- **Verdict:** APPROVE\n"
            "- **Blockers:** None in this chunk (1 of 3).\n"
            f"  - {real_blocker}\n"
            "- **Warnings / Notes:** None\n"
        )
        for review in (bulleted, inline_then_bullet):
            with self.subTest(review=review):
                _, blockers, _ = cpr.parse_review(review)
                self.assertEqual(blockers, [real_blocker])
                self.assertTrue(cpr.review_has_blockers(review))

    def test_blockers_starting_with_none_are_never_stripped(self) -> None:
        cases = [
            (
                "- **Verdict:** APPROVE\n"
                "- **Blockers:** None of the tests verify the fallback path.\n"
                "- **Warnings / Notes:** None\n",
                "None of the tests verify the fallback path.",
            ),
            (
                "- **Verdict:** APPROVE\n"
                "- **Blockers:**\n"
                "  - None of the tests verify the fallback path.\n"
                "- **Warnings / Notes:** None\n",
                "None of the tests verify the fallback path.",
            ),
            (
                "- **Verdict:** APPROVE\n"
                "- **Blockers:**\n"
                "  - None — wait, foo.dart breaks the build.\n"
                "- **Warnings / Notes:** None\n",
                "None — wait, foo.dart breaks the build.",
            ),
        ]
        for review, expected in cases:
            with self.subTest(expected=expected):
                _, blockers, _ = cpr.parse_review(review)
                self.assertEqual(blockers, [expected])
                self.assertTrue(cpr.review_has_blockers(review))

    def test_per_chunk_warnings_ignored_while_real_warnings_preserved(self) -> None:
        chunks = [
            (
                "- **Verdict:** APPROVE\n"
                "- **Blockers:** None in this chunk (1 of 3).\n"
                "- **Warnings / Notes:** No warnings in this chunk\n"
            ),
            (
                "- **Verdict:** APPROVE\n"
                "- **Blockers:** None in this chunk (2 of 3).\n"
                "- **Warnings / Notes:**\n"
                "  - No notes in this chunk\n"
                "  - Consider adding a unit test for empty input.\n"
            ),
        ]
        merged = cpr.merge_chunk_reviews(chunks)
        verdict, blockers, warnings = cpr.parse_review(merged)
        self.assertEqual(verdict, "APPROVE")
        self.assertEqual(blockers, [])
        self.assertEqual(warnings, ["Consider adding a unit test for empty input."])
        self.assertFalse(cpr.review_has_blockers(merged))


class ChunkHeaderAndPromptTests(unittest.TestCase):
    def test_format_chunk_header_single_chunk_is_empty(self) -> None:
        self.assertEqual(cpr.format_chunk_header(1, 1, ["a.py"]), "")

    def test_format_chunk_header_multi_chunk_includes_context_and_literal_none(self) -> None:
        header = cpr.format_chunk_header(2, 3, ["a.py", "b.py"])
        self.assertIn("Chunk 2 of 3", header)
        self.assertIn("a.py", header)
        self.assertIn("b.py", header)
        self.assertIn("- **Blockers:** None", header)

    def test_system_prompt_instructs_literal_none(self) -> None:
        self.assertIn('literally "None"', cpr.SYSTEM_PROMPT)


class DiffExcludesTests(unittest.TestCase):
    def test_vendored_elevenlabs_worklet_excluded_narrowly(self) -> None:
        import os
        import subprocess
        import tempfile
        from pathlib import Path

        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            env = {
                **os.environ,
                "GIT_AUTHOR_NAME": "Test",
                "GIT_AUTHOR_EMAIL": "test@example.com",
                "GIT_COMMITTER_NAME": "Test",
                "GIT_COMMITTER_EMAIL": "test@example.com",
            }
            subprocess.run(["git", "init", "-q", "-b", "main"], cwd=repo, env=env, check=True)
            (repo / "README.md").write_text("base\n", encoding="utf-8")
            subprocess.run(["git", "add", "README.md"], cwd=repo, env=env, check=True)
            subprocess.run(["git", "commit", "-q", "-m", "base"], cwd=repo, env=env, check=True)
            base_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=repo, text=True
            ).strip()

            files = {
                "coqui/packages/core/coqui_platform/assets/elevenlabs/libsamplerate.worklet.js": "/* huge */\n",
                "coqui/packages/core/coqui_platform/assets/elevenlabs/LICENSE": "MIT\n",
                "coqui/packages/core/coqui_platform/assets/elevenlabs/sub/nested.worklet.js": "/* nested */\n",
                "coqui/packages/core/coqui_platform/lib/src/web/el_conv.dart": "// dart\n",
            }
            for rel, content in files.items():
                p = repo / rel
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(content, encoding="utf-8")
            subprocess.run(["git", "add", "."], cwd=repo, env=env, check=True)
            subprocess.run(["git", "commit", "-q", "-m", "head"], cwd=repo, env=env, check=True)
            head_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=repo, text=True
            ).strip()

            old_cwd = os.getcwd()
            try:
                os.chdir(repo)
                chunks, _ = cpr.get_diff_chunks(base_sha, head_ref=head_sha)
            finally:
                os.chdir(old_cwd)

            reviewed = [path for chunk_files, _ in chunks for path in chunk_files]
            self.assertNotIn(
                "coqui/packages/core/coqui_platform/assets/elevenlabs/libsamplerate.worklet.js",
                reviewed,
            )
            self.assertIn(
                "coqui/packages/core/coqui_platform/assets/elevenlabs/LICENSE",
                reviewed,
            )
            self.assertIn(
                "coqui/packages/core/coqui_platform/assets/elevenlabs/sub/nested.worklet.js",
                reviewed,
            )
            self.assertIn(
                "coqui/packages/core/coqui_platform/lib/src/web/el_conv.dart",
                reviewed,
            )


if __name__ == "__main__":
    unittest.main()
