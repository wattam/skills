---
name: dagu-test
description: Create, edit, and delete tests based on a specification and implementation plan without human interaction.
disable-model-invocation: true
---

Flow: `dagu-spec → dagu-plan → dagu-cross-check (spec-plan) → dagu-test → dagu-cross-check (all) → dagu-implement → dagu-review → dagu-address-review`. A workflow orchestrator runs each stage unattended in a fresh session. It repeats each `dagu-cross-check` stage until a pass finds no finding or 5 passes run, and repeats `dagu-review → dagu-address-review` until a review finds no issue.

## Inputs

- A folder containing exactly one file ending with `SPEC.md` and exactly one file ending with `PLAN.md`. Expected location: `specs/<kebab-title>/`.
- Optional `## Push-back Context` section with human input (see Unattended operation).

## Modes

- **Test-first** — the folder contains no `IMPLEMENT.md`. The production change does not exist yet. Do not run tests.
- **Post-implementation** — the folder contains the `IMPLEMENT.md` derived from the spec filename. Run the tests in step 6.

## Workflow

1. List the folder contents. Identify the files ending with `SPEC.md` and `PLAN.md`. Read the spec and plan in full, including their `## Decisions` entries, which are binding. The spec defines
   behavior. The plan defines implementation targets. Select the mode. Read the project instructions.
2. Find the project test locations, frameworks, commands, and conventions. Search all test types for the behaviors and identifiers named in the documents. Read matching tests in full. Read
   production files if necessary.
3. Define the test changes following the project test conventions and test types.
    - Cover each spec behavior and Acceptance criterion.
    - Cover each testable plan change and Acceptance criterion.
    - Edit, create, and delete tests as needed.
    - Remove obsolete test imports and references.
4. Identify blockers. Include missing test infrastructure, unclear setup, ambiguous coverage, document conflicts, and uncertain deletions. Resolve each blocker as described in Unattended
   operation. If any blocker stays unanswered, end `blocked` before changing any file.
5. Apply the test changes.
6. Post-implementation mode only: run the changed tests, then the project's full test suite. Record each result. Do not edit an assertion to match observed output. A failing test stays failing
   and is recorded as `failed`.
7. Write the summary in the spec folder. Replace the trailing `SPEC.md` with `TEST.md`. Overwrite an existing file.
8. End with the result (see Result). Use `findings: 0`.

## Unattended operation

An orchestrator runs this skill in a fresh session. No human reads the session.

- Never ask a question or wait for a reply.
- Never end with a prose summary. The final message is only the `## Result` JSON object.
- Use your own recommendation to answer a blocker when codebase evidence supports it. Record it under `## Decisions` in the summary: the question, the answer, and the evidence.
- Do not guess when no evidence supports an answer. Collect every such question. Then end `blocked`, change no file, and write no summary.
- The prompt can contain a `## Push-back Context` section. When it names a previous stdout log, its `Reviewer feedback` holds human answers to the questions in that log, from an earlier run of this stage. The `answers` in that log hold the human answers that earlier runs of this stage applied. Apply every answer from both. The feedback overrides an earlier answer to the same question. Human input overrides your own answers. Record each applied answer under `## Decisions` with `human answer` as the evidence. When it names no previous stdout log, the feedback belongs to an earlier stage, which recorded it in its own document. Ignore it.
- On a stop condition, end `blocked` and state the stop reason in `questions`.

## Test discipline

- Derive expected results from the spec and plan, not from current implementation output. Assert observable behavior. Cover relevant boundary and error cases. Mock external dependencies, not the
  behavior under test.
- Run tests only in post-implementation mode. Do not install dependencies or change the environment. Record a check that cannot run without them as `not run`.
- Do not modify production code and build files.
- Modify fixtures, shared test infrastructure, test configuration, or CI configuration only when necessary.
- Do not add tautological tests. Remove existing tautological tests. Each test must verify production behavior against an independent expected result.
- Write maintainable test code: clear test names, readable tests, shared fixtures or helpers instead of duplicated setup, no dead, debug, or commented-out code, and accurate comments where a test is non-obvious.
- Use version control only for read-only inspection.

## Content rules

- Use short declarative sentences and explicit identifiers.
- Record changes, coverage, and results. Do not include rationale or test source code. `## Decisions` entries are the only exception.
- Make the summary self-contained. Include test paths, names, types, commands, and assertion focus.
- Do not add TODOs or `<TBD>` placeholders.

## Summary format

```md
# Test: <title from the spec>

## Setup

| Test type | Location | Framework / runner   | Command     |
|-----------|----------|----------------------|-------------|
| <type>    | `<path>` | <framework / runner> | `<command>` |

## Changes

| Action                     | File or test                      | Test type | Assertion focus     |
|----------------------------|-----------------------------------|-----------|---------------------|
| created / edited / deleted | `<path>` or `<path>::<test_name>` | <type>    | <observable result> |

## Coverage

| Source requirement                                   | Covered by            |
|------------------------------------------------------|-----------------------|
| <exact spec or plan location and quoted requirement> | `<path>::<test_name>` |

## Results

| Check                                         | Command     | Result                    |
|-----------------------------------------------|-------------|---------------------------|
| `<path>::<test_name>` or full test suite      | `<command>` | passed / failed / not run |

## Decisions

- <question> — <answer> — Evidence: <`path:line`, document location, or `human answer`>
```

Omit `Changes` when no test changed. Include `Results` only in post-implementation mode. Omit `Decisions` when no blocker needed an answer. Do not add other top-level sections.

## Result

The orchestrator parses the final message of the session as JSON. Make the final message exactly one JSON object and nothing else. Its first character is `{` and its last character is `}`. Write no summary, heading, explanation, or code fence before or after it. Write the object once. Report the work only through the documents and this object.

```json
{"status": "done", "folder": "specs/<kebab-title>", "findings": 0, "questions": "", "answers": ""}
```

- `status`: `done` when the summary is written; `blocked` when the run stopped on unanswered questions or a stop condition.
- `folder`: the spec folder path relative to the current working directory.
- `findings`: always `0` for this stage.
- `questions`: one blocked question per line. Make each question self-contained: name the blocker and the candidate answers. Use an empty string when `done`.
- `answers`: every human answer applied in this run, including those from the previous stdout log, one `<question> — <answer>` per line. Use an empty string when none was applied. A later run reads them from the previous stdout log.

## Stop conditions

- No folder is provided.
- The folder does not contain exactly one file ending with `SPEC.md` and exactly one file ending with `PLAN.md`.
- The spec or plan is unreadable or empty.
- No test location or infrastructure can be found.
