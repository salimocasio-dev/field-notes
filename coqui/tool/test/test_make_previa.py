"""Tests for coqui/tool/make_previa.py: scene_places.json parity and scene-folder discovery.

    python3 coqui/tool/test/test_make_previa.py
"""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
TOOL_DIR = Path(__file__).resolve().parents[1]
COQUI_DIR = TOOL_DIR.parent
sys.path.insert(0, str(TOOL_DIR))
import make_previa  # noqa: E402


class MakePreviaTest(unittest.TestCase):
    def test_places_match_scene_places_json(self):
        data = json.loads((TOOL_DIR / "scene_places.json").read_text(encoding="utf-8"))
        expected = [(p["id"], list(p["scenes"])) for p in data["places"]]
        self.assertEqual(make_previa.PLACES, expected)
        self.assertEqual(len(make_previa.PLACES), 7)
        self.assertEqual(sum(len(scenes) for _, scenes in make_previa.PLACES), 28)

    def test_registry_scenes_matches_make_scenes_list(self):
        discovered = make_previa.registry_scenes()
        res = subprocess.run(
            ["dart", "run", "tool/make_scenes.dart", "--list"],
            cwd=COQUI_DIR,
            capture_output=True,
            text=True,
            check=True,
        )
        dart_scenes = [line.strip() for line in res.stdout.splitlines() if line.strip()]
        self.assertEqual(discovered, set(dart_scenes))
        self.assertEqual(len(discovered), len(dart_scenes))

    def test_discovers_scenes_and_ignores_helpers_in_temp_dir(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            # Helper directories without <dir>.dart are ignored.
            (root / "calle").mkdir()
            (root / "calle" / "calle_cast.dart").write_text("// helper\n", encoding="utf-8")

            # Valid scene folder with Scene create... factory.
            (root / "orilla").mkdir()
            (root / "orilla" / "orilla.dart").write_text(
                "Scene createOrilla() => Orilla();\n", encoding="utf-8"
            )

            self.assertEqual(make_previa.registry_scenes(str(root)), {"orilla"})

            # Scene folder with <dir>.dart missing Scene create... raises Refused.
            (root / "bad").mkdir()
            (root / "bad" / "bad.dart").write_text(
                "void notAFactory() {}\n", encoding="utf-8"
            )
            with self.assertRaises(make_previa.Refused):
                make_previa.registry_scenes(str(root))


if __name__ == "__main__":
    unittest.main(verbosity=2)
