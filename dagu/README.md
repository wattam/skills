# Dagu workflow

This [Dagu](https://docs.dagu.sh/) workflow runs the `dagu-` stage skills in `skills/`, the unattended copies of `development-pipeline`. Each stage runs as one headless Pi call. See `../README.md` for installation.

## Files

| Path | Purpose |
| --- | --- |
| `development-pipeline-pi.yaml` | Runs the pipeline with Pi (`pi -p`). |
| `skills/` | Stage skills and the launcher skill. See [Skills](#skills). |
| `wiki/` | Created by the Dagu server because this folder is its workflow folder. Not used here. |

## Setup

1. Install Dagu. Download the release binary for your platform from https://github.com/dagucloud/dagu/releases, verify it against `checksums.txt`, and put `dagu` on `PATH`.
2. Point Dagu at this folder and define the `development-pipeline` queue in `~/.config/dagu/config.yaml`:
    ```yaml
    paths:
        dags_dir: "/absolute/path/to/skills/dagu"
    queues:
        enabled: true
        config:
            -   name: development-pipeline
                max_concurrency: 100
    ```
    `max_concurrency` caps parallel runs. Without the queue definition, Dagu runs one instance of the workflow at a time. A value of `0` or less starts no run.
3. Install and configure Pi. Make `pi` and `git` available on `PATH`. Install the skills with `../install-skills.sh`.
4. Start the server with `dagu start-all`. The launcher skill starts it for you when no scheduler runs. Open http://127.0.0.1:8080 and create the admin account on `/setup`. The CLI needs no account.

## Run

```bash
dagu enqueue development-pipeline-pi -- REQUEST="Add a nightly job that archives promotions older than 90 days" PROJECT_DIR=/abs/path/to/repo
dagu status development-pipeline-pi
```

`dagu enqueue` returns at once; the running scheduler executes the run. `dagu start` runs in the foreground until the run finishes or pauses.

To start and follow a run from an agent session, see [Starting a run from an agent session](#starting-a-run-from-an-agent-session).

| Parameter     | Required | Meaning                                                              |
|---------------|----------|----------------------------------------------------------------------|
| `REQUEST`     | yes      | Feature or bug description, as text or a file path.                  |
| `PROJECT_DIR` | yes      | Absolute path of the project repository. Every stage runs from here. |

The run fails at `preflight` when the project has uncommitted changes outside `specs/`. It ends `Aborted` at `onInit` when another run is `Queued`, `Running`, or `Waiting` in the same worktree. Runs in different worktrees or projects run in parallel. To run two pipelines on one repository, give each its own worktree (`git worktree add`).

The `init` handler writes `<workflow> <run ID>` to `dagu-development-pipeline.lock` in the worktree's git directory (`git rev-parse --absolute-git-dir`). Git does not track that directory. The run removes its lock when it ends. A lock whose run is no longer active is replaced.

To retry a failed run, retry from the failed step:

```bash
dagu retry --run-id <run-id> --step <failed step> --downstream development-pipeline-pi
```

The retry keeps the outputs of earlier steps, takes the worktree lock again, and skips `preflight`. A full `dagu retry` without `--step` re-runs `preflight`, which fails on the uncommitted changes of earlier stages. `dagu retry` runs in the foreground until the run finishes or pauses.

## Flow

```
preflight → spec → plan
  → plan_cross_check   (spec ↔ plan only, until 0 findings, at most 5 passes)
  → test
  → cross_check        (spec ↔ plan ↔ tests, until 0 findings, at most 5 passes)
  → implement
  → review_cycle  (review → address-review, repeats until a review finds 0 issues, up to 5 cycles)
  → report
```

- Each stage runs its skill in a fresh Pi session: `/skill:dagu-spec ${REQUEST}`, then `/skill:dagu-<stage> <spec folder>`.
- `plan_cross_check` invokes `/skill:dagu-cross-check <spec folder> spec-plan`. It ignores existing test documents and test files. `test` starts only after this loop reports `done`.
- `cross_check` invokes `/skill:dagu-cross-check <spec folder> all` after `test`. Both cross-check loops count all findings discovered in the last pass, including those fixed or dropped as intended. Each loop runs until a fresh pass finds nothing, at most 5 passes. A 5th pass that still finds findings continues to the next stage: a `done` pass leaves no open finding.
- Each stage ends with the JSON line its skill's `## Result` section defines. See **Result line** in [Differences from `development-pipeline`](#differences-from-development-pipeline). The workflow checks it against a JSON schema. Output in any other form fails the step after one retry.
- `review_cycle` is a sub-workflow named `review-cycle` in the same file. Dagu repeats single steps, and this loop needs two skills.
- `report` lists the stage documents, states whether review issues remain unresolved, and names the skill to run next.

## Pauses

Every stage has a human task, `<stage>_answers`. It opens only when the stage ends `blocked`. `review_answers` also opens when 5 review cycles still leave issues. The cross-check loops never pause on their pass limit. The pre-test cross-check uses `plan_cross_check_answers`; the post-test cross-check uses `cross_check_answers`. Review uses `review_answers`.

- Push back: re-runs the stage with your input. Answer the questions. At `review_answers` opened by the cycle limit, write `continue` to run more review cycles. No other human task accepts `continue`.
- Complete: ends the run. Dagu still marks that run `Succeeded`.

Answer in the web UI on the run's **Human tasks** tab, or from the CLI:

```bash
dagu human-task push-back --run-id <run-id> --step spec_answers --input answers="Use table promotions_v2" development-pipeline-pi
dagu human-task complete --run-id <run-id> --step spec_answers development-pipeline-pi
```

## Skills

Each stage skill does the same job and writes the same documents as its `development-pipeline` counterpart. See `../development-pipeline/README.md` for the stages and their documents.

### Differences from `development-pipeline`

- **No questions.** Each stage uses its own recommendation when the evidence supports an answer. It records each decision and its evidence under `## Decisions`.
- **Blocked instead of guessing.** When no evidence supports an answer, the skill collects every such question and ends `blocked`. The workflow pauses and shows you the questions.
- **Human input through push-back.** Your answers return in a `## Push-back Context` section of the next prompt. They override the skill's own answers and are recorded with `human answer` as the evidence. Dagu also adds the section to every later stage that the push-back reruns. Those stages ignore it, because it names no previous stdout log of their own.
- **Answers carried across re-runs.** The section holds only your latest input. Each stage lists the human answers it applied in `answers` of its result line. The next run reads them from the previous stdout log, so a stage that ends `blocked` again keeps your earlier answers. When `dagu-review` ends `blocked`, `dagu-address-review` does not run, so `dagu-review` carries your answers to `dagu-address-review` questions in its `answers`.
- **Two cross-check scopes.** `dagu-cross-check <spec folder> spec-plan` checks only spec and plan before tests. `dagu-cross-check <spec folder> all` checks all available axes after tests. Omitting the scope selects `all`.
- **Binding decisions.** Later stages treat every `## Decisions` entry as binding. `dagu-cross-check` does not report a difference that a decision records as intended. `dagu-address-review` records each review finding it disproves under the spec's `## Decisions`, so `dagu-review` does not report it again.
- **Fixed answers for other prompts.**
    - `dagu-spec` derives a new title when the title belongs to a different request. A re-run after a push-back reuses the folder of the previous run.
    - `dagu-spec` deletes the later pipeline documents when it overwrites the spec of the same request.
    - `dagu-implement` ends `blocked` when `CROSS-CHECK.md` has open findings.
    - `dagu-implement` installs no dependency without your approval in a push-back.
    - `dagu-implement` resumes after the Steps already applied in an earlier run.
    - `dagu-address-review` ends `blocked` when a review issue needs a requirement change or a decision on undefined behavior. It records your decision in the spec.
- **Result line.** The final message of every stage skill is one JSON object and nothing else, with no summary or code fence around it. The workflow parses and validates it:
    ```json
    {"status": "done|blocked", "folder": "specs/<kebab-title>", "findings": 0, "questions": "<one per line>", "answers": "<one per line>"}
    ```
    `findings` is the number of findings in a `dagu-cross-check` pass, the number of issues a `dagu-review` wrote, and the number of issues left unresolved by `dagu-address-review`. It is `0` for every other stage. `answers` is always empty for `dagu-cross-check` and `dagu-address-review`, which record applied answers in the documents.

### Starting a run from an agent session

Complete [Setup](#setup). In Pi, run `/skill:pi-dagu-pipeline` with a feature or bug description. The launcher checks for uncommitted changes outside `specs/` before queueing `development-pipeline-pi`. It reports each stage as it finishes, relays questions the pipeline cannot answer from evidence, and passes your answers back unchanged. At the end it lists the documents and decisions. It never stops Dagu.

### Running a stage skill by hand

The stage skills work outside Dagu too. Called with a request, `dagu-spec` runs the stage without asking you anything. It ends with the JSON result line.

## Permissions

Pi runs as your OS user, with your logins, settings, and global instructions. Pi has no approval prompts. Git runs with your OS user's permissions.

## Limits

- A re-run after a push-back is a new session. The stage repeats its investigation.
- The JSON check validates the format only, not the stage's work.
- `test` runs once, before `implement`.
