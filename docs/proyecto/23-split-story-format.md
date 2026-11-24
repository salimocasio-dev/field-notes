# Split story format: shared games, per-language lines, and ID-to-word tables

Written for story #57 (Page 19, "Before going deeper", section 2).

## Why the split exists

Every Coquí story is two distinct things:

1. **The game** — the scene, camera moves, acts, random draws, beats, touch/choice logic, stake, progress dots, and ending. None of this depends on the language being learned.
2. **The lines** — the title, place name, focus/review word lists, spoken clip texts, free-poke naming table, and the mapping from internal touch/tested IDs to target-language words.

Splitting every story into a language-neutral **game** file and a per-language **lines** file (backed by a per-language **ID-to-word table**) means the same stories play in every language. Adding a new language (for example French `fr` or Arabic `ar`) is purely content work under `content/lines/<lang>/` — no scene edits, no game edits, no Dart changes, and no app release.

## Directory layout

```
content/
  games/
    <id>.json              # Shared language-neutral game file (70 files)
  lines/
    <lang>/                # BCP-47 language code matching Language.code (e.g. "es")
      words.json           # Language-wide ID-to-word table
      <id>.json            # Per-language lines file (70 files for "es")
```

**Why `content/` sits at the repo root outside `historia/`:**

- `historia/` is frozen (bug fixes only).
- Pushing any change under `historia/cuentos/` triggers the paid Azure audio recording job.
- `coqui/tool/split_stories.py` enforces a hard guard that refuses to write inside `historia/cuentos/`, `historia/`, or its own `--src` directory.

The 70 split files in `content/games/` and `content/lines/es/` mirror all 70 legacy files in `historia/cuentos/`: 35 main stories, 11 `escucha`, 11 `haz`, 12 `cual`, and 1 `palabras` (`palabras-solas`).

## Exact key partition (all 24 legacy top-level keys)

Every legacy file in `historia/cuentos/*.json` uses keys from this exact 24-key set. Any unknown top-level key raises a `ValueError` in `split_stories.py` (fail loudly, never silently drop data).

| Legacy key | Destination | Required? | Notes |
| :--- | :--- | :--- | :--- |
| `id` | Both `game` and `lines` | Yes | Must match `<id>.json` filename stem. |
| `tipo` | `game` | No | `"escucha"`, `"haz"`, `"cual"`, or `"palabras"`; omitted on main stories. |
| `scene` | `game` | No | Scene ID (omitted on `palabras-solas`). |
| `next` | `game` | No | Next story ID on the map. |
| `goal` | `game` | No | Internal English goal summary. |
| `note` | `game` | No | Author/tool note (e.g. `cual-*`, `palabras-solas`). |
| `stake` | `game` | No | `{"thing": ..., "steps": ...}` stake definition. |
| `dots` | `game` | No | Total progress dots. |
| `bien` | `game` | No | Default praise clip ID. |
| `callado` | `game` | No | Silent-mode flag (e.g. `el-bebe-duerme`). |
| `cam` | `game` | No | Initial camera view (e.g. `donde-esta-el-pajaro`). |
| `beats` | `game` | No | Ordered list of story steps. |
| `final` | `game` | No | Ending step list. |
| `leer` | `game` | No | Ordered list of clip IDs for the reader view. |
| `items` | `game` (minus `"w"`) + `lines.item_words` | No | Only on `tipo == "cual"`. See below. |
| `title` | `lines` | Yes | Localized story title. |
| `place` | `lines` | No | Localized place name. |
| `nota` | `lines` | No | Language-specific grammar note before a new pattern (e.g. `quien-eres-tu`). |
| `focus_words` | `lines` | No | New tracked words for this story. |
| `back_again` | `lines` | No | Earlier tracked words returning in this story. |
| `also_heard` | `lines` | No | Words heard in clips but not tracked. |
| `names` | `lines` | No | Free-poke map `touch_id -> clip_id`. |
| `palabras` | `lines` | No | Per-story `tested_id -> word` override map (including `"-"` to suppress tracking). |
| `clips` | `lines` | Yes | Clip table `clip_id -> {who, text, habla?, tu_turno?}`. |

## JSON schemas

### 1. Shared Game File (`content/games/<id>.json`)

Envelope fields added on split (stripped on join): `"format": "coqui.game.v1"`.

```json
{
  "format": "coqui.game.v1",
  "id": "la-lluvia",
  "scene": "frente",
  "next": "el-bizcocho",
  "goal": "Get into abuela's house dry.",
  "stake": { "thing": "nube", "steps": 2 },
  "beats": [ ... ],
  "final": [ ... ],
  "leer": [ ... ]
}
```

Special `tipo` variants:
- **Main stories** (`tipo` absent): include `scene`, `beats`, `final`, and optional `next`, `goal`, `stake`, `dots`, `bien`, `callado`, `cam`, `leer`.
- **`tipo: "escucha"` and `tipo: "haz"`**: same structure as main stories with `"tipo"` set.
- **`tipo: "cual"`**: has `"items"`, a list of review-item dicts (`say`, `si`, `no`, plus any non-`"w"` fields) with the language-specific `"w"` field removed. Every source item in `"items"` must be a dict containing a string `"w"`.
- **`tipo: "palabras"`** (`palabras-solas`): holds only `"format"`, `"id"`, `"tipo"`, `"note"` in the game file (all word clips live in `lines`).

### 2. Per-Language Lines File (`content/lines/<lang>/<id>.json`)

Envelope fields added on split (stripped on join): `"format": "coqui.lines.v1"`, `"id"`, `"lang"`.

```json
{
  "format": "coqui.lines.v1",
  "id": "la-lluvia",
  "lang": "es",
  "title": "La lluvia",
  "place": "La casa",
  "focus_words": ["casa", "puerta", "ventana", "abuela", "hola", "toca", "abre"],
  "also_heard": [ ... ],
  "names": { "casa": "casa", "puerta": "puerta", ... },
  "clips": {
    "esta_casa": { "who": "narr", "text": "Esta es la casa de abuela." }
  }
}
```

- For **`tipo: "cual"`**, the lines file carries `"item_words"`: an array of strings parallel to `game["items"]` (same length, same index order). On join, `{"w": word, **item}` reconstructs each original `items[i]` entry verbatim.
- Optional keys (`place`, `nota`, `focus_words`, `back_again`, `also_heard`, `names`, `palabras`, `item_words`) are emitted only when present in the source.

### 3. Per-Language ID-to-Word Table (`content/lines/<lang>/words.json`)

```json
{
  "format": "coqui.words.v1",
  "lang": "es",
  "words": {
    "abajo": "abajo",
    "alla": "allá",
    "bebe": "bebe",
    "mama": "mamá",
    "nina": "niña",
    "nino": "niño",
    "nomas": "-",
    "pajaro": "pájaro",
    "tu": "tu",
    "ventana": "ventana"
  }
}
```

- Keys in `"words"` are sorted lexicographically and never contain `$` variable placeholders or `"-"`.
- For Spanish (`es`), `build_word_table` extracts all 284 concrete touch/tested/named/mapped IDs across the 70 stories by expanding `$var` references (`r'\$([a-z]+)'`, matching `steps.dart:35`) across `draw`, `reparte`, `calc`, and `decide` (up to 4 passes).
- In another language (e.g. `fr`), `content/lines/fr/words.json` maps those same language-neutral game IDs to target-language words (`"ventana": "fenêtre"`, `"puerta": "porte"`, `"casa": "maison"`).

## Word resolution precedence and per-story `palabras` overrides

At runtime, when a non-`libre` `decide` step resolves its concrete `tested_id` (from `tests` if truthy, else `pick`):

1. If `lines["palabras"][tested_id]` is a non-empty string -> use it.
2. Else if `words.json["words"][tested_id]` is a non-empty string -> use it.
3. Else -> fall back to `tested_id`.

If the resolved string is `"-"`, progress does **not** log the decision (matching `steps.dart:409`).

**Why per-story `lines.palabras` overrides stay alongside `words.json`:**

Some internal game IDs mean different words in different stories, or are tracked in one story and suppressed in another:

- **`bebe`**: in `la-piragua` it is the verb `"bebe"` (no override, resolves via `words.json` to `"bebe"`); in `la-familia` it is the noun `"bebé"` (`lines.palabras["bebe"] = "bebé"`).
- **`tu`**: in `otra-vez` it is the possessive `"tu"` (no override, resolves via `words.json` to `"tu"`); in `quien-eres-tu` it is the pronoun `"tú"` (`lines.palabras["tu"] = "tú"`).
- **`nino` / `nina`**: in `las-flores` they track `"niño"` / `"niña"` (and `words.json` maps them to `"niño"` / `"niña"`); in `la-piragua` they are suppressed (`lines.palabras["nino"] = "-"`, `lines.palabras["nina"] = "-"`).
- **`vaso_mesa` -> `"silla"`**: in `el-jugo`, a story-specific touch target (`vaso_mesa`) tests the contrast word `"silla"` via `palabras`.
- **`nomas` -> `"-"`**: dash-only in `otra-vez`, so `words.json["nomas"] = "-"`.

Keeping `lines.palabras` as the highest-precedence layer guarantees 100% identical progress logging on all 70 Spanish stories while letting any new language map every game ID cleanly in `words.json` and override only genuine homonyms or suppressions.

## Tooling and automated checks

The splitter, joiner, and verifier live in `coqui/tool/split_stories.py` (pure Python 3 standard library):

```bash
# Regenerate content/games/ and content/lines/es/ from historia/cuentos/
python3 coqui/tool/split_stories.py split

# Verify content/ matches historia/cuentos/ byte-for-byte, round-trips cleanly,
# and resolves every tested ID identically to legacy single-file behavior
python3 coqui/tool/split_stories.py check

# Join split files back into single-file JSONs in a temporary directory
# (NEVER pass historia/cuentos as --out; the tool refuses it)
python3 coqui/tool/split_stories.py join \
  --games content/games \
  --lines content/lines/es \
  --out /tmp/joined-stories
```

Automated verification:
- `coqui/tool/test/test_split_stories.py` checks all 70 real stories (exact in-memory and committed round-trip), `check_directory`, `words.json` completeness and homonym/suppression equivalence, coverage of every logged decision word in `coqui/ref/trazas/**/*.json`, synthetic French (`fr`) pairing with real `content/games/la-lluvia.json`, and safety/validation guards.
- Both `python3 tool/test/test_split_stories.py` and `python3 tool/split_stories.py check` are wired into `coqui/tool/test_all.sh` and CI.

## How downstream stories consume the split format

- **#58 (`feature_story` — story runner):** accepts either a split pair `(game, lines)` plus the course language's `words.json` table or a legacy single-file story map. When given split files, the runner reads structural steps (`beats`, `final`, `scene`, `stake`, `dots`, `bien`, `callado`, `cam`, `leer`) from `game`, reads localized strings (`title`, `place`, `nota`, `names`, `clips`, `palabras`, `item_words`) from `lines`, and resolves tested IDs via the precedence rule above (`lines.palabras` -> `words.json` -> `tested_id`). All existing path tests and reference traces (`coqui/ref/trazas/`) must produce identical results from split files and legacy single files.
- **#59 (`coqui_content` — content loader):** serves each story's shared `content/games/<id>.json` together with `content/lines/<lang>/<id>.json` and `content/lines/<lang>/words.json` for the active `course.language.code`, so switching or adding a language loads that language's lines and records progress under that language's words without changing any game file or Dart code.
