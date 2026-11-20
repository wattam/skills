---
name: dagu-cross-check
description: Cross-check a specification, implementation plan, and test document for inconsistencies, then resolve each one without human interaction.
disable-model-invocation: true
---

Flow: `dagu-spec → dagu-plan → dagu-cross-check (spec-plan) → dagu-test → dagu-cross-check (all) → dagu-implement → dagu-review → dagu-address-review`. A workflow orchestrator runs each stage unattended in a fresh session. It repeats each `dagu-cross-check` stage until a pass finds no finding or 5 passes run, and repeats `dagu-review → dagu-address-review` until a review finds no issue.

## Inputs

- A folder path with the expected location `specs/<kebab-title>/`. The folder contains these documents:
    - Exactly one file ending with `SPEC.md` — mandatory.
    - Exactly one file ending with `PLAN.md` — mandatory.
    - The matching test document — optional. Derive its filename by replacing the trailing `SPEC.md` in the spec filename with `TEST.md`.
- Optional scope after the folder path: `spec-plan` or `all`. Default: `all`.
- Optional `## Push-back Context` section with human input (see Unattended operation).

## Scopes

- `spec-plan`: run before `dagu-test`. Check only **Spec ↔ Plan**. Ignore the test document even when it exists. Do not read or modify test files or the test document.
- `all`: run after `dagu-test`. Check **Spec ↔ Plan**, **Spec ↔ Tests**, and **Plan ↔ Tests**. Skip the test axes when the test document is absent.
- Both scopes use the same report filename, result contract, and finding count. In each scope the workflow advances when a pass reports `done`, even when that pass counted findings.

## Workflow

1. Locate and ingest the spec and plan. List the folder contents. Identify the files ending with `SPEC.md` and `PLAN.md`. Read both in full. The spec is the authority on intended behavior. The plan is the authority on intended changes.
2. Select the scope. For `spec-plan`, skip the test document, test files, and both test axes. For `all`, derive the test document filename by replacing the trailing `SPEC.md` in the spec filename with `TEST.md`. If the folder contains that file, read it in full. Read each existing test file cited in its `Changes` and `Coverage` tables. Verify that each deleted file or named test is absent. Treat an unreadable expected file or an incomplete deletion as an inconsistency in step 4. If the matching test document is absent, skip the **Spec ↔ Tests** and **Plan ↔ Tests** axes.
3. Investigate the codebase. Search and read the codebase to locate the files, symbols, test suites, and existing patterns relevant to the check.
4. Cross-check the documents along the axes selected by the scope. For each finding, capture the exact location in each document. Use a spec section or criterion and a plan Step or criterion. For a test axis, also use a test `file::test_name`. Capture the conflicting statements. Tag the finding as a **confirmed inconsistency** when the evidence shows a disagreement. Tag it as an **ambiguous divergence** when the evidence cannot show if the difference is intended. A difference that a `## Decisions` entry in the spec, plan, or test document records as intended is not a finding. Collect all findings before resolving any. Do not fix files yet. Treat each item as a potential inconsistency:
    - **Spec ↔ Plan**
        - A Scope item or Expected-behavior bullet has no matching plan Step.
        - A plan Step introduces behavior that does not trace to a Scope item, Expected-behavior bullet, Note, or Context entry.
        - A spec Acceptance criterion is addressed by no plan Step and no plan Acceptance criterion.
        - A plan Acceptance criterion contradicts a spec Acceptance criterion or has no basis in the spec.
        - A file path, symbol, signature, endpoint, table, or column has different identifiers in the two documents.
        - A plan Step contradicts a spec Example for the same input.
        - A spec constraint for authorization, ordering, idempotency, performance, side effects, or null and empty input has no matching plan Step or is contradicted by one.
        - A plan Step changes an item that the spec lists as out of scope.
    - **Spec ↔ Tests**
        - A Scope item, Expected-behavior bullet, Example, edge case, or spec Acceptance criterion has no Coverage row and no assertion in a read test.
        - A test asserts behavior that contradicts a spec Example or Acceptance criterion.
        - A test exercises behavior that the spec lists as out of scope or that does not trace to a spec item.
        - For a bug fix, no test uses the reproduction input from the Current behavior or Examples and asserts the corrected result defined by the Expected behavior. At least one test must cover both. It must not assert the old incorrect result.
        - A Coverage row cites a spec location or requirement that the spec does not contain.
    - **Plan ↔ Tests**
        - A test target has a symbol, signature, path, endpoint, or data shape that differs from the plan.
        - A test assertion contradicts a plan Step or plan Acceptance criterion.
        - A plan Step removes a target that a test still exercises, and no test deletion is recorded.
        - A testable behavior or target introduced or modified by a plan Step is exercised by no test.
        - A plan Acceptance criterion has no Coverage row and no assertion in a read test.
        - A Coverage row cites a plan Step or criterion that the plan does not contain.
5. Resolve every finding, one at a time. Include confirmed inconsistencies and ambiguous divergences. For each finding:
    - Decide the authoritative content from evidence, as described in Unattended operation. The spec wins on intended behavior. The plan wins on intended changes.
    - Apply the fix immediately. For `spec-plan`, edit only the spec and plan. For `all`, edit the spec, plan, test document, or test files as required and keep the test document and test files synchronized. Clear one disagreement before you resolve the next.
    - When the evidence shows the difference is intended, drop the finding and record the reason under `## Decisions`: in the plan for a Spec ↔ Plan finding, in the test document for a Spec ↔ Tests or Plan ↔ Tests finding. A later pass must not report it again.
    - Leave the finding open when no evidence settles it.
6. Write the cross-check only when step 5 leaves at least one finding open. Write it in the spec folder. Replace the trailing `SPEC.md` with `CROSS-CHECK.md` for the filename. Overwrite the file if it exists. List only open findings. Do not write a file when all findings are resolved. Delete an existing cross-check file when all findings are resolved, because it is stale.
7. End with the result (see Result). Use `status: blocked` when a finding stays open.

## Unattended operation

An orchestrator runs this skill in a fresh session. No human reads the session.

- Never ask a question or wait for a reply.
- Never end with a prose summary. The final message is only the `## Result` JSON object.
- Use your own recommendation to resolve a finding when codebase evidence or the document authority rules settle it. Record each decision that keeps a difference under `## Decisions` as step 5 describes: the question, the answer, and the evidence.
- Do not guess when no evidence settles a finding. Leave it open, write it to the report in step 6, and end `blocked` with its open question.
- The prompt can contain a `## Push-back Context` section. When it names a previous stdout log, its `Reviewer feedback` holds human answers to the open findings in that log, from an earlier pass of this stage. Apply every answer when you resolve the matching finding. Human input overrides your own answers. Record each answer that keeps a difference under `## Decisions` with `human answer` as the evidence. When it names no previous stdout log, the feedback belongs to an earlier stage, which recorded it in its own document. Ignore it.
- On a stop condition, end `blocked` and state the stop reason in `questions`.

## Content rules

- Use short declarative sentences and explicit identifiers.
- The report lists only open findings.
- Make each open finding self-contained. Include the conflicting statement from each document. Do not use a reference such as "see the spec" or "see Step 4" in place of the statement.
- Use one numbered heading for each logical inconsistency. Use one row for each location when the same inconsistency occurs at more than one location.
- Do not include document summaries, agreements, praise, or meta-commentary.
- Write each decision entry as `- <question> — <answer> — Evidence: <path:line, document location, or human answer>`. Add a `## Decisions` section at the end of the document when it has none.

## Fix discipline

- Do not run tests, install dependencies, or trigger code execution.
- Do not modify production code.
- Use version control only for read-only inspection.

## File structure

The report contains only findings left open in step 5. Use the three top-level sections in this fixed order. Omit a section with no open findings. Number findings from 1 in each section.

```md
# Cross-check: <short title taken from the spec>

## Spec ↔ Plan

### 1. <inconsistency title>

<one or two sentences that identify the disagreement and the affected items.>

Open question: <decision required to reconcile the files.>

| Artifact | Location           | Statement                       |
|----------|--------------------|---------------------------------|
| Spec     | <location in spec> | <quoted or paraphrased content> |
| Plan     | <location in plan> | <quoted or paraphrased content> |

## Spec ↔ Tests

### 1. <inconsistency title>

<use the same entry structure with Spec and Tests artifact rows>

## Plan ↔ Tests

### 1. <inconsistency title>

<use the same entry structure with Plan and Tests artifact rows>
```

## Result

The orchestrator parses the final message of the session as JSON. Make the final message exactly one JSON object and nothing else. Its first character is `{` and its last character is `}`. Write no summary, heading, explanation, or code fence before or after it. Write the object once. Report the work only through the documents and this object.

```json
{"status": "done", "folder": "specs/<kebab-title>", "findings": 0, "questions": "", "answers": ""}
```

- `status`: `done` when no finding stays open; `blocked` when a finding stays open or a stop condition applies.
- `folder`: the spec folder path relative to the current working directory.
- `findings`: the number of findings step 4 found in this pass, whether fixed, dropped as intended, or left open. The orchestrator repeats this stage until a pass reports `0`, at most 5 passes.
- `questions`: the open question of each open finding, one per line. Make each question self-contained: name the documents, quote the conflicting statements, and give the candidate answers. Use an empty string when `done`.
- `answers`: always an empty string for this stage. Applied answers are recorded in the documents.

## Stop conditions

- No folder is provided.
- The scope is neither `spec-plan` nor `all`.
- The folder does not contain exactly one file ending with `SPEC.md` and exactly one file ending with `PLAN.md`.
- The spec or plan is unreadable or empty.
