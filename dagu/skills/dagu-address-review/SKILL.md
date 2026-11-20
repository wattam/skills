---
name: dagu-address-review
description: Validate review findings, fix confirmed issues, and update existing pipeline documents without human interaction.
disable-model-invocation: true
---

Flow: `dagu-spec → dagu-plan → dagu-cross-check (spec-plan) → dagu-test → dagu-cross-check (all) → dagu-implement → dagu-review → dagu-address-review`. A workflow orchestrator runs each stage unattended in a fresh session. It repeats each `dagu-cross-check` stage until a pass finds no finding or 5 passes run, and repeats `dagu-review → dagu-address-review` until a review finds no issue.

## Inputs

- A spec folder path or its review file. Expected folder: `specs/<kebab-title>/`. The folder must contain one file ending with `SPEC.md` and its matching `REVIEW.md`.
- Picked up automatically from that folder when present, skipped without penalty when absent: `PLAN.md`, `TEST.md`, `IMPLEMENT.md`, and `CROSS-CHECK.md`. Derive each filename by replacing the
  trailing `SPEC.md` in the spec filename.
- Optional `## Push-back Context` section with human input (see Unattended operation).

## Workflow

1. Read the documents. Locate the single file ending with `SPEC.md` and read it in full. Derive related filenames by replacing that suffix. Read the matching `REVIEW.md` and every present
   optional document in full. Treat every `## Decisions` entry as binding. Read the project instructions.
2. Validate each review finding. Read the cited code, related tests, and relevant spec Context files. Check the claim against the documents and current code. The spec defines intended behavior.
   Do not treat review claims or earlier verification results as proof. Distinguish confirmed issues from false findings, issues already fixed, and issues that cannot be validated.
3. Fix confirmed issues directly. Never ask questions or wait for a reply. Make only the required code and test changes. Add or correct regression tests against the specified behavior. Do not
   change requirements or weaken assertions merely to dismiss a finding. A finding whose fix needs a requirement change stays unresolved and needs a human decision (see Unattended operation).
   Leave blocked or uncertain issues unresolved and continue with independent fixes.
4. Verify the changes. Run the affected acceptance checks and the full project test suite unless the plan excludes it. Keep an issue unresolved if its correction or verification is
   incomplete. Record actual results; do not claim that failed or unrun checks passed.
5. Update existing documents in place. Rewrite affected content as if originally authored for the corrected version. Preserve document structures, including every `## Decisions` section. Do not
   create documents or append repair history.
    - Update the spec only where a fix changed an identifier, path, or Context pointer it names. Do not change Goal, Scope, Out of scope, Current behavior, Expected behavior, Acceptance criteria,
      Examples, Notes, or Decisions, except to apply a human decision or record an invalidated finding (see Unattended operation). Keep the spec about WHAT and WHY.
    - Update the plan where needed. Keep it about HOW. Integrate corrections into the existing Steps and Acceptance criteria.
    - Update test file lists, test types, test names, and coverage. Map each Coverage row to its source requirement in the spec or plan. Update the `Results` table when present with the checks
      from step 4.
    - Update implementation file lists and acceptance results for the complete change, not only this repair. Use `verified`, `failed`, or `unverified` according to current checks. Do not
      retain success claims invalidated by the changes.
    - In `REVIEW.md`, change only the tag at the end of each issue heading: append ` [fixed]` for verified fixes, including earlier fixes; append ` [invalidated]` for disproved findings. Replace
      an existing tag instead of adding a second one. Leave unresolved issues untagged. Preserve every issue and all other content.
    - In `CROSS-CHECK.md`, do not resolve an open finding by choosing an answer; each one needs a human decision. Remove a finding only when the updated documents and tests no longer contain the
      conflict. Update remaining evidence and line numbers. Delete the report if no findings remain.
6. End with the result (see Result).

## Unattended operation

An orchestrator runs this skill in a fresh session. No human reads the session.

- Never ask a question or wait for a reply.
- Never end with a prose summary. The final message is only the `## Result` JSON object.
- Use your own judgment to decide whether a finding is valid based on the spec and codebase evidence.
- A finding needs a human decision when its fix needs a requirement change, or when the spec and codebase evidence do not define the intended behavior it depends on. Fix every
  independent finding first. Then end `blocked` with one question per such finding.
- The prompt can contain a `## Push-back Context` section. When it names a previous stdout log, its `Reviewer feedback` holds human answers to the questions in that log, from an earlier
  review cycle. The `answers` in that log hold human answers from earlier review cycles, including answers to questions of this stage that `dagu-review` carried while this stage did not
  run. Apply each answer from both that decides a finding in `REVIEW.md`. The feedback overrides an earlier answer to the same question. Ignore an answer that classifies an unmapped
  change; `dagu-review` applies it. Human input overrides your own answers.
  When it names no previous stdout log, the feedback belongs to an earlier stage, which recorded it in its own document. Ignore it.
- Apply a human decision in the spec. Change the affected spec section as the answer states and record the answer under the spec's `## Decisions` with `human answer` as the evidence. Skip
  an answer the spec already records. Then fix the finding against the updated spec, or tag it ` [invalidated]` when the answer keeps the current behavior.
- Record each finding you tag ` [invalidated]` on your own evidence under the spec's `## Decisions`: whether the cited behavior is an issue, the answer, and the evidence that disproves it.
  Skip a finding the spec already records. A later `dagu-review` must not report it again.
- On a stop condition, end `blocked` and state the stop reason in `questions`.

## Fix discipline

- Preserve unrelated work and follow existing code and test conventions.
- Do not introduce maintainability defects: unclear names or hard-to-follow code, oversized or complex functions or classes, duplication, dead, debug, or commented-out code, wrong, stale, or missing comments on non-obvious code, vague error messages, missing error recovery or cleanup, tight coupling, wrong abstraction level, or code that is hard to test.
- Use version control only for read-only inspection.
- Do not install dependencies or change the environment. Record a check that cannot run without them as `unverified`.
- Complete removals, including obsolete tests, imports, references, and fallback code.

## Content rules

- Use short declarative sentences and explicit identifiers.
- Keep documents self-contained. Leave no TODOs, stubs, or placeholders.

## Result

The orchestrator parses the final message of the session as JSON. Make the final message exactly one JSON object and nothing else. Its first character is `{` and its last character is `}`. Write no summary, heading, explanation, or code fence before or after it. Write the object once. Report the work only through the documents and this object.

```json
{"status": "done", "folder": "specs/<kebab-title>", "findings": 0, "questions": "", "answers": ""}
```

- `status`: `done` when every finding was validated and none needs a human decision; `blocked` when a finding needs a human decision or a stop condition applies.
- `folder`: the spec folder path relative to the current working directory.
- `findings`: the number of review issues left unresolved.
- `questions`: one question per finding that needs a human decision, one per line, or the stop reason. Make each question self-contained: name the issue title, the cited file and line
  range, the spec item in conflict, and the candidate decisions. Use an empty string when `done`.
- `answers`: always an empty string for this stage. Applied answers are recorded in the spec.

## Stop conditions

- No folder or review file is provided.
- The folder contains no file ending with `SPEC.md`, or contains multiple.
- The spec or its matching `REVIEW.md` is missing, empty, or unreadable.
