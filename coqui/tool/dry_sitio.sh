#!/usr/bin/env bash
# Dry run of the one part of .github/workflows/coqui-sitio.yml that cannot run on a branch: the
# step "Commit the build to app/ on main". No network, no GitHub: a local bare repo stands in
# for GitHub, and the step's own text is cut out of the workflow file and run in a shallow clone
# of it (as actions/checkout makes one).
#
#   bash tool/dry_sitio.sh [build dir]      (from anywhere)
#
# Without a build dir it uses a few small fake files. It shows, and fails if any is wrong:
#   1. main moved after the checkout (the audio job pushed): the app commit is put on top of the
#      newest main and pushed; app/ is replaced (a stale file is gone); nothing outside app/ changes
#   2. the same build again: "nothing new", no commit
#   3. main moves once more between the pull and the push (the first push is refused): the step
#      pulls again and the second push goes through
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workflow="$here/../../.github/workflows/coqui-sitio.yml"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
real_git="$(command -v git)"
fail() { echo "dry_sitio: FAILED: $*" >&2; exit 1; }
ok() { echo "ok  $*"; }

# the step's text, from the workflow file
python3 -I - "$workflow" > "$work/step.sh" <<'EOF'
import sys, yaml
steps = yaml.safe_load(open(sys.argv[1]))["jobs"]["sitio"]["steps"]
step = next(s for s in steps if s.get("name") == "Commit the build to app/ on main")
print(step["run"])
EOF

# the build it will commit
mkdir -p "$work/sitio"
if [ $# -ge 1 ]; then
  cp -a "$1/." "$work/sitio/"
else
  mkdir -p "$work/sitio/assets" "$work/sitio/icons"
  echo '<html>app</html>' > "$work/sitio/index.html"
  echo 'js' > "$work/sitio/main.dart.js"
  echo 'a' > "$work/sitio/assets/a.bin"
  echo 'p' > "$work/sitio/icons/Icon-192.png"
fi

# GitHub: a bare repo holding main; the old site at its root, an audio folder, a stale app/ file
cd "$work"
git init -q --bare -b main origin.git
git clone -q origin.git seed 2>/dev/null
(
  cd seed
  git config user.email seed@example.com; git config user.name seed
  mkdir -p historia/audio coqui app
  echo '<html>old site</html>' > index.html
  echo 0 > coqui/BUILD
  echo x > historia/audio/a.mp3
  echo stale > app/old.txt
  git add -A; git commit -q -m "main before"; git push -q origin main
)
# someone else pushing to main: the audio job
git clone -q origin.git other 2>/dev/null
git -C other config user.email voz@example.com; git -C other config user.name coqui-voz
audio_commit() {
  (cd other && git pull -q && echo "$1" > "historia/audio/$1.mp3" && git add -A \
    && git commit -q -m "Audio: cuento ($1)" && git push -q origin main)
}
# the runner: a shallow clone, then the step, with the env the workflow gives it
checkout() { rm -rf ws; git clone -q --depth 1 "file://$work/origin.git" ws 2>/dev/null; }
run_step() { (cd ws && RUNNER_TEMP="$work" BUILD="$1" bash "$work/step.sh" 2>&1); }
count() { git -C origin.git rev-list --count main; }
exists() { git -C origin.git cat-file -e "main:$1" 2>/dev/null; }

echo "== 1. main moved after the checkout"
checkout
audio_commit b
before="$(count)"
run_step 7 | tail -3
[ "$(count)" -eq $((before + 1)) ] || fail "expected one new commit on main"
[ "$(git -C origin.git log -1 --format=%s main)" = "app: build 7" ] || fail "the last commit is not 'app: build 7'"
[ "$(git -C origin.git log -2 --format=%s main | tail -1)" = "Audio: cuento (b)" ] || fail "the audio commit is not under it"
exists app/index.html || fail "app/index.html is not on main"
! exists app/old.txt || fail "the stale app/old.txt is still on main"
exists historia/audio/b.mp3 || fail "the audio commit's file was lost"
[ "$(git -C origin.git show main:index.html)" = '<html>old site</html>' ] || fail "the old site's index.html changed"
outside="$(git -C origin.git show --name-only --format= main | grep -vc '^app/' || true)"
[ "$outside" -eq 0 ] || fail "the app commit touches $outside file(s) outside app/"
ok "the app commit sits on top of the audio commit; app/ replaced; nothing outside app/ touched"

echo "== 2. the same build again"
checkout
before="$(count)"
run_step 7 | tail -1
[ "$(count)" -eq "$before" ] || fail "a commit was made although nothing changed"
ok "nothing new: no commit"

echo "== 3. main moves again between the pull and the push"
echo changed > "$work/sitio/main.dart.js"
checkout
mkdir -p fakebin
cat > fakebin/git <<EOF
#!/bin/bash
if [ "\$1" = push ] && [ ! -e "$work/pushed_once" ]; then
  touch "$work/pushed_once"
  (cd "$work/other" && "$real_git" pull -q && echo c > historia/audio/c.mp3 && "$real_git" add -A \\
    && "$real_git" commit -q -m "Audio: cuento (c)" && "$real_git" push -q origin main)
fi
exec "$real_git" "\$@"
EOF
chmod +x fakebin/git
out="$(PATH="$work/fakebin:$PATH" run_step 8)"
grep -q "push refused (attempt 1 of 5)" <<<"$out" || fail "the first push was not refused"
[ "$(git -C origin.git log -1 --format=%s main)" = "app: build 8" ] || fail "the second push did not go through"
[ "$(git -C origin.git log -2 --format=%s main | tail -1)" = "Audio: cuento (c)" ] || fail "the second audio commit is not under it"
exists historia/audio/c.mp3 || fail "the second audio commit's file was lost"
ok "first push refused, pulled again, second push went through, on top of the newest main"

echo "== the dry run passed"
