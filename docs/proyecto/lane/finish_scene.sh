#!/bin/bash
# finish_scene.sh WORKTREE SCENE FIRSTSTATE "story1,story2,story3" : after the list merge: remake generated files, static checks,
# the scene's own tests, all paths, frames from the real app. Prints short results.
W=$1; X=$2; ST=$3; STORIES=$4; S=/tmp/claude-0/-home-user-field-notes/869ef226-e8c5-5d2f-b5ba-ad271f43401a/scratchpad
export CHROME_EXECUTABLE=/opt/sdk/chrome-nosandbox.sh; cd $W || exit 1
node coqui/tool/ref/pp/make.js --only "$X/$ST" 2>&1 | tail -1
(cd coqui/packages/core/coqui_scenes && for t in make_sheets make_set_fixture make_sprite_fixture; do dart run tool/$t.dart 2>&1 | tail -1 | cut -c1-120; done)
(cd coqui/packages/core/coqui_pixel && dart run tool/make_fixtures.dart 2>&1 | tail -1 | cut -c1-100)
node coqui/tool/ref/pp/check.js 2>&1 | tail -1
(cd coqui && dart format . 2>&1 | tail -1; flutter analyze 2>&1 | tail -1; dart run tool/check_boundaries.dart 2>&1 | tail -1)
echo "--- scenes tests"; (cd coqui/packages/core/coqui_scenes && flutter test test/coqui_scenes_test.dart $(ls test | grep "^${X}_.*_test.dart" | sed 's/^/test\//') 2>&1 | grep -aE "All tests passed|Some tests failed|\[E\]" | cut -c1-260 | tail -6)
echo "--- stories test"; (cd coqui/packages/features/feature_story && flutter test test/${X}_stories_test.dart 2>&1 | grep -aE "All tests passed|Some tests failed|\[E\]" | cut -c1-300 | tail -6)
echo "--- paths"; (cd coqui/packages/features/feature_story && flutter test tool/${X}_paths_test.dart 2>&1 | grep -aE "All tests passed|Some tests failed|\[E\]|plays|paths|rules|broken" | cut -c1-260 | tail -8)
echo "--- frames"; python3 coqui/tool/make_previa.py --places calle --allow-missing-scenes > /dev/null 2>&1; rm -rf $S/o_$X/frames; mkdir -p $S/o_$X/frames
(cd coqui/app && flutter test tool/gate_a_frames_test.dart --dart-define=OUT=$S/o_$X/frames --dart-define=TXT=no --dart-define=STORIES=$STORIES 2>&1 | grep -aE "All tests passed|Some tests failed|\[E\]" | cut -c1-200 | tail -3)
python3 - <<P
import json,glob
for f in glob.glob('$S/o_$X/frames/summary.json'):
    d=json.load(open(f)); print(json.dumps(d)[:900])
P
git checkout -- coqui/app/assets/previa; git clean -fdq coqui/app/assets/previa; echo "historia dirty: $(git status --porcelain historia | wc -l)"; git status --short | cut -c1-70 | head -20; echo finished
