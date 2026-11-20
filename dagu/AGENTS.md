## What this category is

The Pi workflow and the skills it runs. See `README.md` for usage.

- Workflow: `development-pipeline-pi.yaml`.
- Stage skills: `dagu-spec`, `dagu-plan`, `dagu-test`, `dagu-cross-check`, `dagu-implement`, `dagu-review`, `dagu-address-review`. Unattended copies of the `development-pipeline` skills.
- Launcher skill: `pi-dagu-pipeline`. Invoke it to queue `development-pipeline-pi`, relay human tasks, and report the result.

Put every `SKILL.md` in `skills/<name>/`. The install scripts install every `SKILL.md` in the repository. Dagu loads the workflow file from this folder. Every skill uses version control read-only.

## Relation to `development-pipeline`

- Each `dagu-<stage>` skill differs from `../development-pipeline/<stage>` only in: `name` and `description`, the `Flow:` line, the `spec-plan` and `all` scopes in `dagu-cross-check`, the `## Unattended operation` section, the `## Result` section, the `## Decisions` section in document templates, binding treatment of `## Decisions` entries, the recording of invalidated review findings under the spec's `## Decisions` in `dagu-address-review`, the deletion of later pipeline documents when `dagu-spec` overwrites a spec, the `IMPLEMENT.md` input and the resume after completed Steps in `dagu-implement`, and non-interactive replacements for every question or approval.
- Each stage skill opens with the same `Flow:` line. Update every copy when the flow changes.

## Stage skill conventions

- No stage skill asks a question or waits for a reply.
- Decision entries use the format `- <question> — <answer> — Evidence: <path:line, document location, or human answer>`.
- Put shared stage behavior in each stage skill. Each stage uses its own evidence-backed recommendations for unattended decisions.

## Launcher skill conventions

- Update `pi-dagu-pipeline` when the workflow name, a parameter, a human task step ID or form field, the `report` step, or the lock file name or format changes.
- Relay human input unchanged. Never answer a pipeline question or continue a loop without user input.
- Start `dagu start-all` in the background when no active scheduler is registered. Never stop a Dagu process.

## Workflow conventions

- `development-pipeline-pi.yaml` holds two YAML documents: the main workflow and the `review-cycle` sub-workflow. YAML anchors do not cross documents. Each document sets `harness.provider: pi`.
- Human tasks are allowed only in the main document.
- Define the global queue `development-pipeline` in the Dagu config.
- The `handler_on.init` handler takes the per-worktree lock `<git dir>/dagu-development-pipeline.lock`, holding `<workflow> <run ID>`. It runs on every run and every `dagu retry`. The `handler_on.exit` handler removes it. Keep the lock out of `preflight`: `dagu retry --step` skips `preflight`.
- `preflight` runs only at the start of a run. Its uncommitted-changes check fails once a stage changed files, so retries start at the failed step with `--step <step> --downstream`.
- Use string-form `output: VAR` and reference `${VAR.field}`. Object-form outputs are not visible to `repeat_policy` conditions. Read sub-workflow results as `${VAR.outputValues.field}`.
- Invoke stage skills with `/skill:<name>`. Keep `SKILL.md` files harness-agnostic.
- Keep the workflow in sync with the stage skills: skill names, flow order, stage inputs, the `## Push-back Context` feedback format, and the `REVIEW.md` and `CROSS-CHECK.md` filenames.

## Workflow contract

- Every stage step validates the `## Result` JSON object `{status, folder, findings, questions, answers}` with an `output_schema`. Change the `## Result` section of every stage skill and every `output_schema` in the workflow together.
- The final message of every stage skill is only the `## Result` JSON object: no prose, heading, or code fence before or after it. Keep that rule in the `## Result` and `## Unattended operation` sections of every stage skill.
- The workflow runs `plan_cross_check` after plan and before test with `dagu-cross-check <folder> spec-plan`. It runs `cross_check` after test with `dagu-cross-check <folder> all`. Each loop repeats until `findings` is `0` or the stage ends `blocked`, with a limit of 5 passes. Reaching the limit with `done` and findings above `0` continues to the next stage: those findings were resolved and none stayed open. Only `blocked` pauses a cross-check loop at its human task. Keep the pre-test check independent of existing test documents and test files.
- The workflow also repeats `dagu-review` until `findings` is `0`. Keep that meaning of `findings` in `dagu-cross-check` and `dagu-review`.

## Verification

- Run `dagu validate <file>` after every workflow edit.
- Test control flow with a mock agent. Shadow the provider with a custom harness, for example `harnesses: {pi: {binary: /path/to/mock, prefix_args: ["-p"], prompt_mode: arg}}`, in both documents of a test copy. Use an isolated `DAGU_HOME`. When another Dagu server runs, start the test server with `DAGU_COORDINATOR_ENABLED=false dagu start-all --port <free port>`.
