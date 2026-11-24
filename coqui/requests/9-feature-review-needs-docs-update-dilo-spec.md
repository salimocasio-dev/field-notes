# Update Dilo specification in `docs/proyecto/15-repaso-juegos.md`

## What I need

Update `docs/proyecto/15-repaso-juegos.md` so the **Dilo** speaking card description and instruction line match Salim's `#9` direction:
- Instruction line: `'Listen. Say the sentence back.'` (replaces `'Listen. Say what comes next.'`).
- Audio & prompt: Dilo plays `line.clip` (the sentence to say back, not `line.before`) and displays the sentence with the tested target word highlighted before the learner speaks, while keeping verified speech recognition (`Skill.mouth` written only when heard right; no self-report button) and dropping story-frame screenshots from the reveal.

## Why

Issue `#9` ("Speaking cards: test something the learner can actually say back") implements Salim's override in `lane:feature_review`, which may not edit `docs/`.

## What I am using meanwhile

`feature_review` implements Salim's `#9` behaviour directly and notes the override in `lib/src/logic/repaso_plan.dart` and PR #136.

## Order and branch

Issue `#9` · branch `lane/feature_review/9` (PR #136).
