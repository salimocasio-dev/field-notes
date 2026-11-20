# The readers' verdicts behind `historia/datos/repaso.json`

`veredictos/<book>.json`: for each candidate sentence of a story book, the pages whose picture it clearly fits (`si`), clearly does not (`no`), or neither (`duda`), and the pairs of pages that look almost the same (`parecidas`). Judged Nov 20 2026 by fresh readers who saw the pictures and the sentences and nothing else.

`veredictos-par/<slug>.json`: for each sentence of a word, whether it fits picture A or B of the word's own review pair, both, neither, or is unclear. The readers did not know which picture the course calls right.

They are inputs of `coqui/tool/make_repaso.py` (`--veredictos`, `--veredictos-par`). Its `--hojas-libro` and `--hojas-par` make the sheets a reader needs; its validators check a verdict file. When stories or books change, the tool refuses stale verdicts: judge the changed books and words again.
