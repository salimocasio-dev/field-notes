# Runbook for builder agents (Coquí, A1)

Read this whole page before you touch anything. You are a builder working for an orchestrator who makes every decision. Do exactly the task you were given; when something needs a choice that your task does not settle, stop and report it instead of choosing.

## The project in four lines
- A Spanish course (Puerto Rican Spanish) for absolute beginners, played as short pixel-art stories. Static site: `historia/` in this repo, served by GitHub Pages from `main`.
- Each scene has three stories (a taught opening, a turn, two or three scored rounds, an ending) and twelve next-day picture pairs (¿Cuál?). Scripts are in `historia/notas/guiones/<scene>.md`; the build log and the rules learned so far are in `docs/proyecto/08-build-log-a1.md` (read its section "Script lessons so far").
- The owner's requirements: `docs/proyecto/03-requirements.md`. They outrank everything.
- Spanish on screen only (menus excepted). Original pixel art only. Course words stay Puerto Rican.

## Git
- Work on branch `ccr-2871b5d2-axaw8h`. Commit small, push often: `git push -q origin ccr-2871b5d2-axaw8h`. If a push is refused, `git pull -q --rebase origin ccr-2871b5d2-axaw8h` first (an audio job also commits to this branch).
- Every commit message ends with these two lines:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
  `Claude-Session: https://claude.ai/code/session_01XaggvtaHwrZFWHrVJ9zJ7n`
- Publishing (only when your task says so): `git fetch -q origin main && git merge-base --is-ancestor origin/main HEAD && git push -q origin HEAD:main`. Then check the Pages workflow (id 416688417) with the GitHub MCP tool `mcp__github__actions_list` (load it with ToolSearch `select:mcp__github__actions_list`; owner `salimocasio-dev`, repo `field-notes`, method `list_workflow_runs`, resource_id `416688417`) until the newest run is `completed` / `success`.
- Never create a pull request. Never push to any other branch.

## Audio (costs money: read carefully)
- Pushing a file under `historia/cuentos/` starts the "Voz" workflow (id 417069462), which records every new line with Azure and commits "Audio: cuento". A line pushed early and changed later is recorded twice.
- So story JSON is kept OUT of git (`.git/info/exclude`) until the orchestrator says its Spanish is final. Do not remove exclude lines unless your task says so.
- Generators print "N clips, M new, C characters to record". Report C. Never push anything that would record more than your task allows.
- ElevenLabs is never used by builders. No accounts, no keys, no spending, no emails.

## Local testing
- Start the server only for the length of your test batch: from the repo root, `curl -s -o /dev/null http://localhost:8765/ || (python3 -m http.server 8765 >/dev/null 2>&1 &)`. Stop it when you finish: `pkill -f "http.server 8765"`.
- Tools (in `historia/tools/`):
  - `juega.py <outdir|-> <plan> <cuento> <fast> "<query>"` plays one story by machine. Plan letters are r (right) / w (wrong), one per scored decision. Query sets the draws, e.g. `"txt=no&fa=leche&fb=queso"`; `txt=no` hides all words (for the wordless readers). With an outdir it saves numbered frames. With recorded audio a run takes 2 to 3 minutes: give it 4.
  - `matriz.sh <cuento> <plan> <query>` (one-line verdict: exit, pageerrors, finished, marcas, lost). Run many with `xargs -P 5 -L 1 bash historia/tools/matriz.sh < list.txt > out.txt`. A run is good when exit=0, pageerrors=0, finished=1, marcas match the plan (ok for r, x for w) and lost = number of w.
  - `cual_check.py "" "todo=1&n=20&txt=no&solo=word,word" <outdir>` plays picture pairs (all 140 with `todo=1&n=140`); it must end with every answer ok and `errors: []`.
  - `nivel_check.py "" <outdir> todo` plays the level check with every item; `app_check.py <outdir>` checks the app.
  - `hojas.py <dir> <outprefix> [per] [cols] [W]` makes numbered contact sheets; `sel.py <dir> <out.png> <n1,n2,..> [W] [cols]` picks frames. Both sort frames by number.
- Use a new folder name for every set of frames. Never `rm -rf` a path built from a variable (a safety check blocks it).
- `node --check <file.js>` after every edit of a scene file.

## Building a scene (pattern: La nevera)
- Scene file `historia/escenas/<id>.js`: copy the shared pieces from `historia/escenas/nevera.js` (tenida, gente, rana, bub2, talkAt, hud, marca, mueve, vuela, ranaA, corre) and register with `KIT.escena({id, CAM, heartAt, lugar, cosas, fresh, draw, hud, poke, acts, stake, talkAt, respIcon, estado})`. Touch targets are `cosas` ({id, si, box, m, z}). Acts are async functions; an act with `suelto:1` runs while the next line is said and `act("ya")` waits for it (`corre(o,pr)`). Acts may set `V.<name>` for the generator's `if`.
- Generator `historia/tools/gen_<id>.py`: copy the shape of `gen_nevera.py` (N/T/D helpers, `ask`, `decide`, `draw`, `calc`, `X`, `ok`, `CARD`, `dots`, `final`, `leer`). Clip ids are global: the same id must have the same text everywhere; the generator's last block prints clashes and missing clips (both must be 0). Every line in the script becomes exactly one clip, word for word.
- Wiring, when the task says so: `historia/curso.js` (the place's `cuentos` list, titles and minutes, the `cual` list), `historia/nivel.js` (level-check items), the previous story's `next` (in its own generator), and the `?v=` number in every html/js that carries it (`grep -rl "v=NN" --include=*.html --include=*.js .`).
- Test story files for looking at drawings: `historia/cuentos/z<id>N.json` with a single act `prueba`; they are excluded from git by `.git/info/exclude`.

## Reporting back
- Keep the final report short: what you did, what you checked and how (numbers), what failed, anything that needs a decision. Paths to any sheets you made. Never claim a check you did not run.
