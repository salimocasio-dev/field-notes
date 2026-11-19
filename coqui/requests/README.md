# requests/

A request file is a note from a builder to the orchestrator.

A builder writes one when it needs something it may not do itself:

- a change in a package that is not its own (boundary rule 7);
- a third-party package that is not in the list (builders may not add one);
- a change to a contract (after order 02 only the orchestrator changes one).

Then the builder uses the fake or a local copy and carries on.

A request says what is needed, in which package, why the builder needs it, and what it used meanwhile.

This folder is open to every lane. A lane branch may add files here and nowhere outside its own package. The orchestrator reads the requests and decides.
