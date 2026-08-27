# Reader task — `comply`

The reader must establish what they are obliged to do, and be able to cite it.

**Target shape** — structured by obligation, not by narrative. One obligation
per addressable unit, with its identifier.

**Signature rule** — 🔒 normative wording is untouchable. `MUST`, `MUST NOT`,
`SHALL`, `SHOULD`, `MAY`, legal citations, article and clause numbers, effective
dates: verbatim, or the pass fails.

## Allowed transforms

- Regroup narrative text under the obligation it belongs to.
- Add an obligation index or contents with stable anchors.
- Add a heading naming the obligation, above unlabelled normative text.
- Separate obligation from guidance, keeping both, clearly labelled.

## Forbidden transforms

- ⛔ Rewording any normative sentence, at all, for any reason.
- ⛔ Changing `SHOULD` to `MUST` or the reverse — including "for clarity".
- ⛔ Renumbering clauses or dropping a citation, a date, or a version.
- ⛔ Summarising obligations. A summary of an obligation becomes the thing people
  cite, and it is not the obligation.
- ⛔ Condensing at all. `comply` documents run `access-only` at most.

## Acceptance questions

1. Is every normative sentence byte-identical to the source?
2. Is every clause number, citation and effective date present and unchanged?
3. Is each obligation individually addressable by an anchor?
4. Is guidance visibly distinguished from obligation?
