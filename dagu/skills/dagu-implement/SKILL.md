---
name: dagu-implement
description: Execute an implementation plan without human interaction.
disable-model-invocation: true
---

Flow: `dagu-spec → dagu-plan → dagu-cross-check (spec-plan) → dagu-test → dagu-cross-check (all) → dagu-implement → dagu-review → dagu-address-review`. A workflow orchestrator runs each stage unattended in a fresh session. Loops stop on a clean pass or when blocked. The orchestrator runs up to 2 `spec-plan` passes, 3 `all` passes, and 3 review cycles without human input.

## Inputs

- A folder path containing a file ending with `PLAN.md`, or a direct path to that file. Expected folder location: `specs/<kebab-title>/`.
- Picked up automatically from the plan's folder when present, skipped without penalty when absent. Derive each filename by replacing the trailing `PLAN.md` in the plan filename:
    - `TEST.md` — test changes from a test-first `dagu-test` run, plus the Setup table with the exact test commands.
    - `CROSS-CHECK.md` — open inconsistencies between the spec, plan, and tests.
    - `IMPLEMENT.md` — the report of an earlier run of this stage.
- Optional `## Push-back Context` section with human input (see Unattended operation).

## Workflow

1. Locate and ingest the plan. If the input is a folder, list its contents and identify the file ending with `PLAN.md`. Read it in full. Treat Context, Steps, Acceptance criteria, and `## Decisions`
   entries as the binding source of work to perform. Read `TEST.md`, `CROSS-CHECK.md`, and `IMPLEMENT.md` in full when present. Read the project instructions.
2. Check open inconsistencies. If `CROSS-CHECK.md` is present, end `blocked`. Put the open question of each finding in `questions`. Change no file and write no
   report.
3. Investigate the codebase. For each file, symbol, signature, path, or command named in the plan, search and read the codebase to confirm its current state, exact location, and surrounding
   patterns before editing. Locate targets by symbol; treat plan line numbers as hints. When `IMPLEMENT.md` exists, treat each Step whose change the code already contains as completed.
4. Identify gaps. Scan the plan and the investigation for missing information that blocks execution. Treat each of these as a potential gap:
    - **Missing target** — a Step names a file, symbol, or path that does not exist and the plan does not say to create it.
    - **Ambiguous action** — a Step's action, signature, payload, SQL, or command is not concrete enough to apply without choosing among alternatives.
5. Resolve every gap as described in Unattended operation. If any gap stays unanswered, end `blocked` before changing any file.
6. Execute the Steps in sequential order, starting at the first Step not completed. Do not reorder, skip, batch ahead, or parallelize. Complete a Step and confirm it succeeded before starting the
   next.
7. Verify the Acceptance criteria. After the last Step, check each Acceptance criterion. Running the project's full test suite — every test, not only the ones related to the change — is always
   one of the Acceptance criteria unless the plan says not to. Resolve each check command in this order: the command the plan supplies, the matching command in the `TEST.md` Setup table, the
   command found in the project's build and test configuration. Record for each criterion the check used and its final result. A failed check does not stop the run.
8. Write the report to a markdown file inside the same folder as the plan. Filename: replace the trailing `PLAN.md` with `IMPLEMENT.md`. Overwrite if it exists. Write the report also when the
   run stops at a blocked Step (see Stop conditions).
9. End with the result (see Result). Use `findings: 0`.

## Unattended operation

An orchestrator runs this skill in a fresh session. No human reads the session.

- Never ask a question or wait for a reply.
- Never end with a prose summary. The final message is only the `## Result` JSON object.
- Use your own recommendation to answer a gap when codebase evidence supports it. Record it under `## Decisions` in the report: the question, the answer, and the evidence.
- Do not guess when no evidence supports an answer. Collect every such question. Then end `blocked` before changing any file and write no report.
- The prompt can contain a `## Push-back Context` section. When it names a previous stdout log, its `Reviewer feedback` holds human answers to the questions in that log, from an earlier run of
  this stage, or an approval to install a named dependency. The `answers` in that log hold the human answers and approvals that earlier runs of this stage applied. Apply every answer
  from both. The feedback overrides an earlier answer to the same question. Human input overrides your own answers. Record each applied answer under `## Decisions` with
  `human answer` as the evidence. When it names no previous stdout log, the feedback belongs to an earlier stage, which recorded it in its own document. Ignore it.
- On a stop condition, end `blocked` and state the stop reason in `questions`.

## Execution discipline

- Version control is off-limits for writes. Do not create, switch, rename, or check out branches; do not commit, stage, push, pull, merge, rebase, stash, or reset. Use `git` only for read-only
  inspection (e.g. `git status`, `git diff`).
- Stay inside the plan except for test-run setup repairs. Make only the changes the Steps describe or those necessary to unblock tests. No unrelated refactors, renames, reformatting, or dependency upgrades.
- If a Step or Acceptance test fails due to setup/infrastructure unrelated to feature logic, repair the blocker, update affected commands/setup in existing `PLAN.md` and `TEST.md`, then rerun the test. Do not change requirements, coverage, test assertions, or feature behavior to make tests pass. Record remaining test failures as `failed`.
- Do not install dependencies or change the environment unless the Push-back Context approves the named dependency. A Step that cannot complete without one is blocked (see Stop conditions). Mark a
  check that cannot run without one `unverified` and name the dependency in its Check column.
- No partial placeholders. A Step is either completed fully or reported as blocked. No TODOs or stubs in the code.
- Match the conventions and style of the surrounding code being edited. Use clear names. Keep functions and classes small and readable. Do not duplicate logic within the change. Leave no dead, debug, or commented-out code. Comment non-obvious code and keep touched comments accurate. Write specific error messages and clean up on failure. Avoid tight coupling and code that is hard to test.
- Outside the plan's Steps, write only files needed for test-run setup repairs, affected `PLAN.md` or `TEST.md` setup/command details, and the `IMPLEMENT.md` report.

## Content rules

- Optimized for LLM consumption: short declarative sentences, explicit identifiers, no rhetorical flourish.
- The report is a **record of what was changed and verified**, not a plan or rationale. Do not describe WHY an edit was made. `## Decisions` entries are the only exception.
- The report must be **self-contained**. Inline every file path, the full text of every Acceptance criterion, and the exact command or assertion used to check it; never substitute a reference like
  "see the plan" for the information itself.
- Status values: `verified` (the criterion's check ran and passed), `failed` (it ran and did not pass), `unverified` (it could not be run).
- Do not include source code or diffs in the report.
- No TODOs or `<TBD>` placeholders.

## File structure

```md
# Implement: <short title taken from the plan>

## Files

| File               | Change                     | Step / setup           |
|--------------------|----------------------------|------------------------|
| `path/to/file.ext` | created / edited / deleted | Step <n> or test setup |

## Acceptance criteria

| Criterion                    | Status                         | Check                                                |
|------------------------------|--------------------------------|------------------------------------------------------|
| <criterion text>             | verified / unverified / failed | <command or assertion used, or why it could not run> |

## Blocked

<include only if the run stopped at a blocked Step>

- Step <n>: <what blocked it>. Steps completed: <list>. Steps not executed: <list>.

## Decisions

- <question> — <answer> — Evidence: <`path:line`, document location, or `human answer`>
```

Omit `## Blocked` when no Step blocked. Omit `## Decisions` when no gap needed an answer. Do not introduce other top-level sections.

## Result

The orchestrator parses the final message of the session as JSON. Make the final message exactly one JSON object and nothing else. Its first character is `{` and its last character is `}`. Write no summary, heading, explanation, or code fence before or after it. Write the object once. Report the work only through the documents and this object.

```json
{"status": "done", "folder": "specs/<kebab-title>", "findings": 0, "questions": "", "answers": ""}
```

- `status`: `done` when every Step completed and the report is written; `blocked` when the run stopped on unanswered questions, open cross-check findings, a blocked Step, or a stop condition.
- `folder`: the spec folder path relative to the current working directory.
- `findings`: always `0` for this stage.
- `questions`: one blocked question per line. Make each question self-contained: name the gap, finding, or blocked Step and the decision required, for example approval to install a named
  dependency. Use an empty string when `done`.
- `answers`: every human answer and dependency approval applied in this run, including those from the previous stdout log, one `<question> — <answer>` per line. Use an empty string
  when none was applied. A later run reads them from the previous stdout log.

## Stop conditions

- No folder or file provided.
- Input folder contains no file ending with `PLAN.md`, or contains multiple.
- Provided file does not end with `PLAN.md`.
- Plan is unreadable or empty.
- `CROSS-CHECK.md` is present. Write no report.
- A Step still cannot be completed after applicable setup repairs (missing dependency, conflicting code, failing command, unresolved gap) — stop at that Step, execute no later Steps, and still write the report: criteria not checked
  because of the block are `unverified`, and `## Blocked` names the blocked Step, what blocked it, the Steps completed, and the Steps not executed.
