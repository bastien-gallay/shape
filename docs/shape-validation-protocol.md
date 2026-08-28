---
title: shape — qualitative validation protocol
status: draft, unimplemented
companion to: shape-spec-v1.1 (§5 calibration, §6 ledger)
---

# shape — qualitative validation protocol

**Goal** — change a ruleset and know within minutes whether it helped, without
rewriting a real document each time.

**Intended audience** — whoever tunes shape's rulesets and prompts.

**TL;DR** — 🛑 **The obvious design is broken.** Asking an LLM *which version is
better* rewards tables and bullets, which is precisely what shape produces — the
judge would confirm the transformation whatever its merit. The protocol therefore
makes the model **perform reading tasks**, and uses preference judging last, under
blinding, on a small subset.

**Contents** — Why judging fails · Instruments · Fixtures · Run protocol ·
Measures · Decision rules · Calibrating the judge · Cadence · Tuning · Protocol
failure modes.

---

## 1. Why naive LLM judging fails here

| Bias | Effect on shape | Severity |
| --- | --- | --- |
| **Formatting preference** | Judges reward tables, bullets, headings — shape's output by construction | 🛑 Fatal. This is the confound, not a nuisance. |
| **Verbosity / length** | Cuts to length in either direction move the verdict independently of quality | ⚠️ High for `condense` |
| **Self-preference** | A model rates text from its own family higher | ⚠️ High — the same family transforms and judges |
| **Position** | First or last option favoured | Medium — fixable by counterbalancing |
| **Fluency ≠ usability** | A judge reads fully and attentively; the real reader scans and gives up | ⚠️ High — the exact property under test |

⭐ **The consequence drives everything below.** A model asked *which is clearer* is
an unreliable instrument for this skill specifically. A model asked *find this fact
and report where you found it* is a decent one, because the answer is checkable
against ground truth and formatting only helps if it genuinely helps.

---

## 2. Four instruments, three of them cheap

| Instrument | Role | Nature | Cost |
| --- | --- | --- | --- |
| **Reader** | Performs retrieval and comprehension tasks against the document | Task, not opinion | Low |
| **Auditor** | Checks fact survival, protected content, invented claims | Near-deterministic; scripts where possible | Low |
| **Referee** | Blind pairwise preference | ⚠️ Opinion — used last and least | Medium |
| **Human (you)** | 5-second test, first-screen, tie-breaks | Ground truth for your own repos | 🔒 Scarce — budget ~20 min per release |

🛑 The Referee never sees a pair where one side is prose and the other is tables
*with no other difference*. That comparison measures the bias, not the skill.

---

## 3. Fixture corpus

Four tiers. The point of tiers 0 and 1 is exactly your requirement: adjust without
dogfooding.

| Tier | Unit | Size | Checked by | Runs |
| --- | --- | --- | --- | --- |
| **T0 — unit** | One defect, isolated | 10–30 lines | Assertions only, no model | Every commit |
| **T1 — section** | One coherent section | 100–300 words | Reader + Auditor | Every ruleset change |
| **T2 — document** | Whole real doc | 800–4 000 words | Reader + Auditor + human spot-check | Every release |
| **T3 — adversarial** | Must-not-break cases | any | Auditor + human | Every release, and on any refusal-logic change |

### T3 is the tier that is usually missing

| Fixture kind | Expected behaviour |
| --- | --- |
| Already-well-shaped document | ⛔ **No change.** Churn on a good document is a defect. |
| Compliance text with `MUST` / legal citations | Structure may change; wording is untouchable |
| Credits or ADR page with real names | Depersonalise must **not** fire |
| Four linear steps | ⛔ Must stay a list; no flowchart |
| Prose that genuinely resists tabulation | Must stay prose |
| Document already run through shape | Idempotent |

### Fixture file format — two files, never one

🛑 **The answer key never shares a file with the document.** A single file
carrying `must_preserve` and `q:`/`a:` in its own frontmatter defeats both
instruments at once: `census.sh` reads frontmatter as a block, so the whole file
reaches a cold Reader whose context now contains the answers — retrieval scores
100 % with no transform at all; and `verify-facts.sh` greps the whole target, so
a protected fragment quoted in the frontmatter satisfies the 100 % gate even
when the body deleted every occurrence. Both instruments report a pass they
never ran.

⭐ Stripping the frontmatter before each instrument would also work, and is
worse: it holds only as long as every consumer remembers. Two files cannot be
got wrong.

**`fixtures/T1-locate-004.md`** — the document, and nothing else. No fixture
frontmatter. This is what the Reader, `census.sh` and `verify-facts.sh` receive;
there is nothing to strip because there is nothing to strip out.

**`fixtures/T1-locate-004.key.yaml`** — the frozen key, which nothing on the
measurement path reads:

```yaml
id: T1-locate-004
tier: 1
task: locate          # locate | execute | decide | learn | comply
audience: dev-doc
modes: [diagnose, access-only]
defect: headings name topics instead of answering questions
expect: change        # change | no-change | refuse

frozen_at: 2026-08-27
document_sha256: "…"  # of the .md at freeze time

must_preserve:
  - "2026-08-25"
  - "npx markdownlint-cli2"

questions:            # authored by hand, once, frozen
  - q: Which command lints the worktree?
    a: npx markdownlint-cli2
  - q: What must be paired with a positive control?
    a: the name grep
```

🛑 **No `.key.yaml` ever enters a Reader context or an instrument input.** The
harness reads the key, asks the questions and scores the answers; only the
document crosses the transform and the gates. A harness that hands over the
fixture directory wholesale has cancelled the protocol.

⚠️ **`document_sha256` makes control 6 mechanical.** "Fixtures are frozen" is
otherwise a promise. The harness recomputes the hash and exits **4 — did not
run** on a mismatch, so a fixture edited to make a change pass is an error
rather than a matter of discipline. Re-freezing is deliberate: update the hash
and `frozen_at` in the same commit, and the diff says so.

📌 **Questions are authored by you, once, and frozen.** Model-generated questions
bias toward what the model finds salient. Fixtures are small and reused, so hand
authoring is affordable here — this is the single biggest quality lever in the
protocol.

---

## 4. Run protocol

| # | Control | Why |
| --- | --- | --- |
| 1 | Reader gets a **fresh context**, no knowledge of the edit | Otherwise it grades its own work |
| 2 | Reader is a **different model family whenever one is available**; ⚠️ record which family ran, every time | Self-preference |
| 3 | Every transform runs **k = 3** with different seeds | Variance is itself a defect signal |
| 4 | Referee sees A/B **stripped of provenance**, order randomised and counterbalanced | Position bias |
| 5 | Reader reports **which sections it opened**, not only the answer | Locate cost |
| 6 | Fixtures are **frozen**; the harness verifies `document_sha256` and exits 4 on a mismatch | Prevents silent goalpost drift |
| 7 | The `.key.yaml` never reaches a Reader context or an instrument input | The answer key is not evidence |

⚠️ **Control 2 is weaker than it reads, and says so on purpose.** A subagent
spawned from this skill runs the same model, and no config key selects another
family — so *must be a different family* would be breached on every run,
undetected. A numbered control that is always breached teaches the reader to
skip the list. Brief §F7 asks for a fresh context and *ideally* a different
model; this matches it, and control 1 carries the weight.

🛑 **Which family ran is recorded whichever way it goes.** Same-family runs are
not thereby discharged: they are same-family evidence, and the §2 threat stays
open above them. Numbers pooled across families without the label cannot be
re-read later when a second family becomes available.

⚠️ **Instability counts as failure.** If k = 3 runs on one fixture disagree on the
output shape, the ruleset is underdetermined — record the variance and treat it as a
finding, not as noise to average away.

---

## 5. Measures

| Measure | Instrument | Type |
| --- | --- | --- |
| Retrieval accuracy | Reader | correct / total, against frozen answers |
| Locate cost | Reader | sections opened before answering |
| Fact survival | Auditor + script | 🛑 binary, 100 % required |
| Invented claims | Auditor | count, must be 0 |
| Refusal correctness | Auditor | T3 only: did it correctly not act |
| Output stability | k runs | do the 3 outputs agree on shape |
| Visual profile | census | V1–V7 from spec v1.1 |
| Preference | Referee | forced binary choice + one-line reason |
| 5-second recall | Human | what did you retain, unprompted |
| First-screen verdict | Human | do you know what this doc is for |

⛔ **No Likert scales.** LLM 1–10 ratings are poorly calibrated and drift between
runs. Forced binary choice with a stated reason is more stable and more auditable.

---

## 6. Decision rules — when a change is accepted

Applied in order. First failure stops the evaluation.

| Order | Rule | On failure |
| --- | --- | --- |
| 1 | 🛑 Fact survival 100 % on every fixture | Reject, no discussion |
| 2 | 🛑 Zero invented claims | Reject |
| 3 | 🛑 Every T3 fixture behaves as declared | Reject |
| 4 | No fixture **regresses** on retrieval accuracy | Reject |
| 5 | Locate cost improves on ≥ ⅔ of T1/T2 fixtures | Hold, investigate |
| 6 | Output stable across k = 3 | Hold, tighten the ruleset |
| 7 | Referee and human agree on direction | If they disagree, ⭐ **human wins** |

⚠️ **n is small.** These are stop rules, not statistics. Rules 1–4 are absolute
because they are safety properties; rules 5–7 are judgement supported by evidence.

---

## 7. Calibrating the judge — do this before trusting it

The step that gets skipped, and the one that decides whether the Referee is worth
running at all.

1. Take 10 A/B pairs from T1, blind.
2. You choose. The Referee chooses. Independently.
3. Compute agreement.

| Agreement | Reading |
| --- | --- |
| ≥ 80 % | Referee usable as a pre-filter; you spot-check |
| 50–80 % | Referee usable only to flag pairs for you to look at |
| ≈ 50 % | ⛔ Referee is a coin flip on your documents — drop it, keep Reader + Auditor |

📌 Re-run calibration whenever the judge model changes. Track agreement in the
ledger; a drop is a signal about the model, not about shape.

⚠️ Your preference is ground truth **for your repositories**, not evidence about
readers in general. Do not let a high agreement number turn into a claim about
documents at large.

---

## 8. Cadence and cost

| Trigger | Tiers | Model calls | Your time |
| --- | --- | --- | --- |
| Commit | T0 | 0 | 0 |
| Ruleset change | T0 + T1 | ~30 | 0 |
| Release | all | ~150 | ~20 min |
| Judge model change | calibration set | ~20 | ~15 min |

⭐ T0 costing zero model calls is the point. Most tuning iterations should never
reach a model at all: a heading that fails the informativeness assertion fails it
deterministically.

---

## 9. Tuning — attributing an effect

To adjust without dogfooding, you need to know *which* change did what.

- Vary **one ruleset at a time**; hold fixtures, models and seeds fixed.
- Keep a matrix: ruleset version × fixture × measure.
- ⚠️ A change that improves T1 and degrades T2 is usually a rule that works on
  fragments and breaks on document-level structure — the most common shape of
  regression here.
- Record the ablation in the ledger (spec v1.1 §6) so the matrix accumulates rather
  than being rebuilt each time. `ledger.sh` carries the four keys the matrix is
  built from:

```sh
ledger.sh --fixture-id T1-locate-004 --ruleset-version v1.1 --run-index 2 \
          --reader-family <family> …
```

  🛑 `--fixture-id` without `--ruleset-version` is refused: an unattributable
  calibration run is worse than an absent one, because it still looks like
  evidence in the pile. A fixture run also names its own file
  (`<date>-<fixture>-<ruleset>-r<k>.json`), so the k = 3 replicates no longer
  differ only by a collision-breaking suffix.

---

## 10. Failure modes of the protocol itself

| Risk | Mitigation |
| --- | --- |
| Fixtures drift toward what shape already does well | ⭐ Every fixture that fails in real use gets added; the corpus grows from defects, not from intuition |
| The Referee's bias is rediscovered as a result | Calibration (§7) plus the rule that human wins |
| k = 3 averaged instead of read | Variance reported as its own line |
| T3 quietly stops being run because nothing ever fails there | Its failures are rare and expensive; run it on every release regardless |
| A frozen answer key turns out wrong | Fix it, and record the fix — a silently corrected key invalidates every prior comparison |
| Passing the suite is read as *the skill works* | It means *the skill did not regress on twelve documents you chose* |
