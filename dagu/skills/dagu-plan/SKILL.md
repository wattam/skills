---
name: dagu-plan
description: Turn a specification into an implementation plan without human interaction.
disable-model-invocation: true
---

Flow: `dagu-spec → dagu-plan → dagu-cross-check (spec-plan) → dagu-test → dagu-cross-check (all) → dagu-implement → dagu-review → dagu-address-review`. A workflow orchestrator runs each stage unattended in a fresh session. Loops stop on a clean pass or when blocked. The orchestrator runs up to 2 `spec-plan` passes, 3 `all` passes, and 3 review cycles without human input.

## Inputs

- A folder path containing a file ending with `SPEC.md`. Expected location: `specs/<kebab-title>/`.
- Optional `## Push-back Context` section with human input (see Unattended operation).

## Workflow

1. Locate and ingest the spec. List the folder contents, identify the file ending with `SPEC.md`, and read it in full. Treat its `## Decisions` entries as binding.
2. Investigate the codebase. Open each production file the spec's Context names, plus their direct callers and related entities. Extract exact signatures, current line targets, and existing
   patterns to mirror. Look for **prefactoring opportunities** — existing code worth restructuring first, without changing behavior, to make the feature change simpler to apply. Find the exact
   commands that run the project's full test suite and each test type.
3. Identify gaps. Scan the spec and what the investigation surfaced for missing information that would block execution. Treat each of these as a potential gap:
    - **Identifiers** — target files/modules/directories, function/class/endpoint/table/column names, dependencies/libraries/versions not pinned.
    - **Behavior** — input/output shapes, types, schemas, edge cases, error handling, failure modes, side effects (DB writes, network calls, file I/O) not described.
    - **Constraints** — auth, permissions, role requirements not stated.
    - **Verification** — acceptance criteria, check commands, migration/rollout/backfill steps not stated.
4. Resolve every gap as described in Unattended operation. If any gap stays unanswered, end `blocked` and write no file.
5. Write the plan to a markdown file inside the same folder as the spec. Filename: replace the trailing `SPEC.md` with `PLAN.md`. Overwrite if it exists.
6. End with the result (see Result). Use `findings: 0`.

## Unattended operation

An orchestrator runs this skill in a fresh session. No human reads the session.

- Never ask a question or wait for a reply.
- Never end with a prose summary. The final message is only the `## Result` JSON object.
- Use your own recommendation to answer a gap when codebase evidence supports it. Record it under `## Decisions` in the plan: the question, the answer, and the evidence.
- Do not guess when no evidence supports an answer. Collect every such question. Then end `blocked` and write no file.
- The prompt can contain a `## Push-back Context` section. When it names a previous stdout log, its `Reviewer feedback` holds human answers to the questions in that log, from an earlier run of this stage. The `answers` in that log hold the human answers that earlier runs of this stage applied. Apply every answer from both. The feedback overrides an earlier answer to the same question. Human input overrides your own answers. Record each applied answer under `## Decisions` with `human answer` as the evidence. When it names no previous stdout log, the feedback belongs to an earlier stage, which recorded it in its own document. Ignore it.
- On a stop condition, end `blocked` and state the stop reason in `questions`.

## Content rules

- Optimized for LLM consumption: short declarative sentences, explicit identifiers, no rhetorical flourish.
- Describe **HOW**, never **WHY** — no rationale, no background. `## Decisions` entries are the only exception.
- The plan must be **self-contained**: inline every identifier, path, signature, schema, role, and value. Never substitute a reference like "see the spec" for the information itself.
- Use ordered steps; one concrete action per step.
- For each step, include when applicable: the exact file path, the exact symbol, the exact signature/payload/SQL, and the exact command to run. Identify targets by symbol. Add the current line
  number only as a locator hint, because earlier Steps can shift lines.
- Place prefactoring Steps **before** the Steps that add the feature.
- Design Steps to reuse existing utilities, place code in the layer the codebase uses for it, keep functions and classes small, avoid duplicating logic across Steps, and state exact error messages and recovery behavior.
- Prefer code blocks and tables over prose.
- No TODOs or `<TBD>` placeholders — every gap must be answered in step 4.
- Do not create or update test files, and do not add test-writing steps to the plan. The `dagu-test` stage owns every test change.
- Each Acceptance criterion names its exact check: a command to run or an observable assertion.
- Include running the project's full test suite, with its exact command, as an Acceptance criterion unless the spec excludes it.
- A criterion can require tests authored in the `dagu-test` stage. State the behavior those tests must verify, not a test file or test name.
- Use version control only for read-only inspection.

## File structure

```md
# Implementation plan: <short title taken from the spec>

## Context

<one paragraph max — names the system, the entry point, and the artifact being changed. No motivation.>

## Steps

1. <action> — <file:symbol@line> — <signature/payload/SQL/command>
2. ...

## Acceptance criteria

- <check 1> — `<command>` or <observable assertion>
- <check 2> — `<command>` or <observable assertion>

## Decisions

- <question> — <answer> — Evidence: <`path:line`, document location, or `human answer`>
```

Omit `## Decisions` when no gap needed an answer.

## Result

The orchestrator parses the final message of the session as JSON. Make the final message exactly one JSON object and nothing else. Its first character is `{` and its last character is `}`. Write no summary, heading, explanation, or code fence before or after it. Write the object once. Report the work only through the documents and this object.

```json
{"status": "done", "folder": "specs/<kebab-title>", "findings": 0, "questions": "", "answers": ""}
```

- `status`: `done` when the plan is written; `blocked` when the run stopped on unanswered questions or a stop condition.
- `folder`: the spec folder path relative to the current working directory.
- `findings`: always `0` for this stage.
- `questions`: one blocked question per line. Make each question self-contained: name the gap and the candidate answers. Use an empty string when `done`.
- `answers`: every human answer applied in this run, including those from the previous stdout log, one `<question> — <answer>` per line. Use an empty string when none was applied. A later run reads them from the previous stdout log.

## Stop conditions

- No folder provided.
- Folder contains no file ending with `SPEC.md`, or contains multiple.
- Spec is unreadable or empty.
