#!/bin/bash
# verify_build.sh N SHA : wait for the site build, the app commit, the pages deploy; compare live with the repo
N=$1; SHA=$2; R=salimocasio-dev/field-notes; cd /home/user/field-notes
wait_run(){ # workflow name, sha
  for i in $(seq 1 120); do
    j=$(gh run list -R $R --workflow "$1" --limit 20 --json headSha,status,conclusion 2>/dev/null | python3 -c "
import json,sys
for r in json.load(sys.stdin):
    if r['headSha']=='$2': print(r['status'],r['conclusion']); break")
    case "$j" in completed*) echo "$1: $j"; return;; esac; sleep 20; done; echo "$1: timeout ($j)"; }
wait_run "Coquí sitio" $SHA
for i in $(seq 1 60); do git fetch -q origin main 2>/dev/null; A=$(git log origin/main --format='%H %s' -20 | grep "app: build $N" | head -1 | cut -d' ' -f1); [ -n "$A" ] && break; sleep 15; done
echo "app commit: $A"
for i in $(seq 1 90); do
  d=$(gh api "repos/$R/deployments?environment=github-pages&per_page=5" 2>/dev/null | python3 -c "
import json,sys
for r in json.load(sys.stdin):
    if r['sha']=='$A': print(r['id']); break")
  if [ -n "$d" ]; then st=$(gh api "repos/$R/deployments/$d/statuses" 2>/dev/null | python3 -c "import json,sys; r=json.load(sys.stdin); print(r[0]['state'] if r else '')"); [ "$st" = success ] && break; fi
  sleep 20; done
echo "pages deploy: $d $st"
git pull -q origin main 2>/dev/null
bad=0; n=0
for f in $(git ls-files app); do n=$((n+1)); a=$(sha256sum "$f" | cut -d' ' -f1); b=$(curl -s --max-time 60 "https://salimocasio-dev.github.io/field-notes/$f?v=$N" | sha256sum | cut -d' ' -f1); [ "$a" = "$b" ] || { bad=$((bad+1)); echo "DIFF $f"; }; done
echo "live files: $n compared, $bad differ"
for u in historia/ historia/app.html prueba/ app/; do echo "$u $(curl -s -o /dev/null -w '%{http_code}' --max-time 60 https://salimocasio-dev.github.io/field-notes/$u)"; done
curl -s --max-time 60 "https://salimocasio-dev.github.io/field-notes/app/version.json?v=$N" | head -c 200; echo
wait_run "Coquí" $SHA
wait_run "Coquí Android" $SHA
echo done
