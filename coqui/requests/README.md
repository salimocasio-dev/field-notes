# requests/

A request file is a note from a builder to the orchestrator.

A builder writes one when it needs something it may not do itself:

- a change in a package that is not its own (boundary rule 7);
- a third-party package that is not in the list (builders may not add one);
- a change to a contract (after order 02 only the orchestrator changes one).

Then the builder uses the fake or a local copy and carries on.

## One request, one file

The file is named `<order number>-<your package>-needs-<target package>-<short-slug>.md`. Lower case, hyphens.

For example: `21-feature-words-needs-coqui-ui-picture-tile.md`.

It has four headings:

- **What I need**: the exact member or behaviour.
- **Why**: the order line that needs it.
- **What I am using meanwhile**: the fake or local copy.
- **Order and branch**: the order number and the lane branch.

This folder is open to every lane. A lane branch may add files here and nowhere outside its own package. The orchestrator reads the requests and decides.
