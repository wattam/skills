---
name: dagu-spec
description: Turn a natural-language feature/bug-fix request into a specification file without human interaction.
disable-model-invocation: true
---

Flow: `dagu-spec → dagu-plan → dagu-cross-check (spec-plan) → dagu-test → dagu-cross-check (all) → dagu-implement → dagu-review → dagu-address-review`. A workflow orchestrator runs each stage unattended in a fresh session. Loops stop on a clean pass or when blocked. The orchestrator runs up to 2 `spec-plan` passes, 3 `all` passes, and 3 review cycles without human input.

## Inputs

- A natural-language description of a feature or bug fix, provided as text and/or as a file path.
- Optional `## Push-back Context` section with human input (see Unattended operation).

## Workflow

1. Classify the request as **feature** or **bug fix** and pick the template variant (see "File structure" below).
2. Investigate the codebase. Search and read the codebase to locate the files, symbols, and existing patterns relevant to the request.
3. Derive a short title in kebab-case for the filename. Example: `add-promotion-archive-job`. When a `## Push-back Context` names a previous stdout log with a non-empty `folder`, use that folder's name as the title instead. Otherwise, when `specs/<title>/<title>-SPEC.md` already exists, read it. If it describes a different request, derive a different title by appending `-2`, `-3`, … until the folder holds no spec or the spec of the same request. The title is final after this step; the result reports its folder even when the run ends `blocked`.
4. Identify gaps. Scan the request and what the investigation surfaced for missing information that would block writing a useful spec. Treat each of these as a potential gap:
    - Acceptance criteria not testable (no observable pass/fail)
    - No specific files, modules, or existing patterns to point at in Context
    - No concrete example (input → output, before → after)
    - Edge cases not surfaced (null, empty, unauthorized, oversized, concurrent, …)
    - Constraints/gotchas not stated (auth, perf, ordering, idempotency, side effects)
    - Feature:
        - Scope bullets not listable (2–5 concrete items)
        - Out-of-scope items unclear (behavior that must not change)
    - Bug fix:
        - Current behavior not stated
        - Expected-behavior bullets not listable (each a discrete observable behavior that should happen instead)
        - Reproduction steps missing when the behavior is non-obvious
5. Resolve every gap as described in Unattended operation. If any gap stays unanswered, end `blocked` and write no file.
6. Write the spec. Create a folder named `specs/` in the current working directory (if it does not already exist), then create a subfolder inside of it whose name is the derived kebab-case title.
   Write the spec inside that subfolder as `<kebab-case-title>-SPEC.md` (e.g. `specs/add-promotion-archive-job/add-promotion-archive-job-SPEC.md`). If the subfolder already exists, reuse it.
   If the target file already exists, it describes the same request (see step 3). Overwrite it and delete each pipeline
   document derived from the spec filename (`PLAN.md`, `TEST.md`, `CROSS-CHECK.md`, `IMPLEMENT.md`, `REVIEW.md`), because it derives from the previous spec.
7. End with the result (see Result). Use `findings: 0`.

## Unattended operation

An orchestrator runs this skill in a fresh session. No human reads the session.

- Never ask a question or wait for a reply.
- Never end with a prose summary. The final message is only the `## Result` JSON object.
- Use your own recommendation to answer a gap when codebase evidence supports it. Record it under `## Decisions` in the spec: the question, the answer, and the evidence.
- Do not guess when no evidence supports an answer. Collect every such question. Then end `blocked` and write no file.
- The prompt can contain a `## Push-back Context` section. Its `Reviewer feedback` holds human answers to questions from an earlier run. The previous stdout log it names holds the earlier questions and, in `answers`, the human answers that earlier runs applied. Apply every answer from both. The feedback overrides an earlier answer to the same question. Human input overrides your own answers. Record each applied answer under `## Decisions` with `human answer` as the evidence. Reuse the `folder` from that log (see step 3).
- On a stop condition, end `blocked` and state the stop reason in `questions`.

## Content rules

- Optimized for LLM consumption: short declarative sentences, explicit identifiers, no rhetorical flourish.
- Use version control only for read-only inspection.
- Describe **WHAT** changes and **WHY** to scope it. Do not describe **HOW**.
- The spec must be **self-contained**. Everything needed to scope the work must appear in the spec. Do not write "see the ticket" or "as discussed"; inline the information.
- Point at specific files in Context. Example: "Look at `service/PromotionService.java` for the existing archive pattern".
- No TODOs or `<TBD>` placeholders — every gap must be answered in step 5.

## File structure

### Feature template

```md
# <Title>

## Goal

<what this does and why it matters>

## Scope

- <2–5 bullets of what is in>

## Out of scope

- <what is deliberately untouched; omit this section if no behavior is at risk>

## Acceptance criteria

- <testable condition>
- <testable condition>

## Context

- `path/to/file.ext` — <what it is / why it is relevant>
- Existing pattern to follow: <short description or `path/to/file.ext:symbol`>

## Examples

<input → expected output, or before → after; ≥1 normal case + 1 edge case>

## Notes

<constraints, gotchas, things not to assume — only if non-obvious>

## Decisions

- <question> — <answer> — Evidence: <`path:line`, document location, or `human answer`>
```

Omit `## Decisions` when no gap needed an answer.

### Bug-fix template

Identical to the feature template, except: `## Goal` and `## Scope` are replaced by the three sections below.
`## Examples` placeholder becomes `<input that reproduces the bug → wrong output (current); same input → right output (expected)>`.

```md
## Current behavior

<what happens now, with reproduction steps if non-obvious>

## Expected behavior

- <2–5 bullets, each one observable behavior that should happen instead; one bullet per discrete behavior so downstream stages can map, test, and review them individually>

## Suspected cause

<optional — only if there is a real hypothesis; do not speculate>
```

## Result

The orchestrator parses the final message of the session as JSON. Make the final message exactly one JSON object and nothing else. Its first character is `{` and its last character is `}`. Write no summary, heading, explanation, or code fence before or after it. Write the object once. Report the work only through the documents and this object.

```json
{"status": "done", "folder": "specs/<kebab-title>", "findings": 0, "questions": "", "answers": ""}
```

- `status`: `done` when the spec is written; `blocked` when the run stopped on unanswered questions or a stop condition.
- `folder`: the spec folder path relative to the current working directory. Use an empty string when no folder was derived.
- `findings`: always `0` for this stage.
- `questions`: one blocked question per line. Make each question self-contained: name the gap and the candidate answers. Use an empty string when `done`.
- `answers`: every human answer applied in this run, including those from the previous stdout log, one `<question> — <answer>` per line. Use an empty string when none was applied. A later run reads them from the previous stdout log.

## Stop conditions

- No description provided.
- Description is still not actionable after resolving gaps: no target file, symbol, behavior, or user-visible change can be identified.
- File path supplied is unreadable or empty.
