# Request: check_app.mjs expectation for Hablar's words

## What I need
In coqui/tool/check_app.mjs, update the "the Hablar tab opens" seed check (android and iPhone) to match the Noche Hablar screen's text, or stop asserting the old words.

## Why
N4.9 (#110) does not change Hablar's screen, but the run shows both `*-seed: the Hablar tab opens` checks FAIL on the old-words expectation. Every other check passes.

## What I am using meanwhile
Reporting the two FAILs in the PR body. The shell is unchanged there.

## Order and branch
Any time; lane of coqui/tool. Noche routes (Languages, Plans, Import, Place) also have no module answering yet; the shell logs a line and does nothing.
