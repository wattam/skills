---
name: pi-dagu-pipeline
description: Run the development pipeline unattended with Pi through the Dagu workflow development-pipeline-pi and relay its questions to me.
disable-model-invocation: true
---

## Inputs

- A feature or bug description as text or a file path. Required.
- Optional project repository path. Default to the current working directory. Resolve it to an absolute path.
- Optional run ID of an existing `development-pipeline-pi` run. When given, skip steps 3–5 and monitor that run.

## Detached launch

To launch `dagu <arguments>` detached, start it in the background so it keeps running after this session ends. Write its output to `<log path>`:

- POSIX shell: `nohup dagu <arguments> > <log path> 2>&1 &`.
- Windows PowerShell: `Start-Process dagu -ArgumentList <arguments as comma-separated single-quoted strings> -WindowStyle Hidden -RedirectStandardOutput <log path> -RedirectStandardError <log path>.err`.

## Workflow

1. Check the tools. Run `dagu version`. Run `dagu ls` and confirm it lists `development-pipeline-pi`. Stop if either check fails.
2. Ensure the scheduler runs. Run `dagu config` and read the `Service registry:` path. The scheduler runs when a JSON file in `<service registry>/scheduler/` has `"status": 1` and its `pid` is a running process. Check the process with `kill -0 <pid>` in a POSIX shell or `Get-Process -Id <pid>` in Windows PowerShell. When no file passes, launch `dagu start-all` detached (see `## Detached launch`) with the log path `<system temporary directory>/dagu-start-all.log`. Check the registry every 5 seconds for up to 30 seconds. When a file passes the same check, tell me you started Dagu, give me the log path, and state that the web UI is at http://127.0.0.1:8080. Otherwise stop and quote the last 20 lines of the log files.
3. Check the project. Run `git -C <project> rev-parse --is-inside-work-tree`. Run `git -C <project> status --porcelain -- . ':(exclude)specs'`. Stop if the path is not a repository or the second command prints anything. List the changed paths when you stop.
4. Check for an active run in the project worktree. Run `git -C <project> rev-parse --absolute-git-dir`. If `<git dir>/dagu-development-pipeline.lock` exists, read `<workflow> <run ID>` from it and run `dagu status --run-id <run ID> <workflow>`. The run is active when the first nonblank line of stdout starts with `Queued`, `Running`, or `Waiting`.
   - Active run of `development-pipeline-pi`: give me its run ID and ask whether to monitor that run instead. On my approval, go to step 6 with that run ID. Otherwise stop.
   - Active run of another workflow: give me its run ID and workflow name, and stop.
5. Start the run. Build the run ID `pi-<kebab-case summary of the request, at most 40 characters>-<YYYYMMDDHHMMSS>`. Use only lowercase letters, digits, and dashes. When the description is text, write it unchanged to a new file under the system temporary directory, and use that file path as `<request path>`. When the description is a file path, resolve it to an absolute path and use that path. Every workflow stage runs in the project directory, so a relative path would resolve against it. The shell would expand `$`, backticks, double quotes, and backslashes in inline text. Run:
   `dagu enqueue --run-id <run-id> development-pipeline-pi -- "REQUEST=<request path>" "PROJECT_DIR=<absolute project path>"`.
   Give me the run ID.
6. Track the run. Use `## Track the run`. Report each newly finished stage in one line. Report nothing between changes.
   - `Queued` for 3 minutes: repeat step 2. If the run is still `Queued` 3 minutes after that check, tell me once that the scheduler has not picked it up. Continue monitoring.
   - `Waiting`: go to step 7 and wait for my reply.
   - `Succeeded`, `Failed`, or `Aborted`: go to step 8.
7. Relay the waiting human task. Find the step marked `[waiting]` in the status output. `plan_cross_check_answers` belongs to the pre-test spec-plan cross-check; `cross_check_answers` belongs to the post-test cross-check; `review_answers` belongs to the review cycle. Read its prompt. When the prompt text is wrapped or cut, read the questions from the stdout file listed under the matching stage step.
   - `<stage>_answers` with status `blocked`: ask me each question, one at a time. Add no recommendation of your own; the stage found no evidence-backed answer.
   - `review_answers` with status `done` and findings above 0: the review loop reached its 3-cycle limit. Ask me whether to run up to 3 more cycles or end the run. The cross-check loops continue to the next stage if they reach their limit with status `done`.
   Act on my reply:
   - Answers: write `{"answers": "<question 1>\n<my answer 1>\n..."}` to a new file under the system temporary directory. Run `dagu human-task push-back --run-id <run-id> --step <step> --inputs-json "$(cat <json file>)" development-pipeline-pi`. The shell does not expand the file content, so quotes, `$`, and backticks in my words pass unchanged.
   - More loop passes: the same steps with `{"answers": "continue"}`.
   - End the run: `dagu human-task complete --run-id <run-id> --step <step> development-pipeline-pi`.
   Encode the JSON correctly; escape double quotes, backslashes, and newlines. Return to step 6.
8. Report the outcome.
   - `Succeeded` with the `report` step succeeded: name the spec folder and list its documents. Quote the `report` step output, including whether review issues remain. List every `## Decisions` entry in the spec folder documents, each with its question and answer, so I can review the answers the pipeline chose without me.
   - `Succeeded` with the `report` step skipped: the run ended at a pause. State that, and name the last stage that finished.
   - `Failed`: name the failed step and quote the error lines from the status output. Ask whether to retry from that step. Use the failed step of the main workflow; a failure inside `review-cycle` shows as `review_cycle`. On my approval, launch `dagu retry --run-id <run-id> --step <failed step> --downstream development-pipeline-pi` detached (see `## Detached launch`) with the log path `<system temporary directory>/dagu-retry-<run-id>.log`. Return to step 6.
   - `Aborted` with `onInit` failed: another run holds the worktree. Quote the error lines and give me the run ID they name.
   - `Aborted` otherwise: the run was stopped. State the last stage that finished.

## Track the run

Run a foreground wait-for-change loop in the shell tool. Keep the polls, sleeps, and comparisons inside one shell call per wait window. If a wrapper is required to reach the shell, use it for the whole loop, not for individual polls. Do not detach a watcher that cannot notify this session.

1. Poll `dagu status --run-id <run-id> development-pipeline-pi` immediately on entry to step 6, then every 60 seconds. Capture stdout and stderr separately. Read `<state> - <time>` from the first nonblank line of stdout. Take a fresh reading of the same run ID after an interruption. Do not enqueue a replacement run.
2. Compare the run state and the set of top-level stage IDs marked `[succeeded]`, such as `spec` in `├─spec (1m 48s) [succeeded]`. Ignore timestamps, elapsed times, repeat counts, and nested steps. Carry the comparison baseline across wait windows so unchanged stages do not get reported again.
3. Return the initial snapshot once. After that, return early on a state change, newly finished stages, or a queue check or warning due under step 6. Use elapsed time since first observing `Queued`, not the timestamp in the header. Keep queue timing and completed checks across wait windows. Reset them when the run leaves `Queued`.
4. Return only the state and relevant stage IDs while the run is active. Return the full status snapshot for `Waiting`, `Succeeded`, `Failed`, or `Aborted`, so steps 7 and 8 have the prompt, outputs, or errors. On a nonzero exit, missing header, or unexpected state, return diagnostics. Recheck once after 60 seconds. If the problem persists, report that monitoring stopped and leave the run alone.
5. End the wait window after 15 minutes without an event and return `unchanged`. Leave time before the tool deadline for the loop to exit normally. Shorten the window only to fit the tool's limit. On `unchanged`, start the next window without a user update. Cancel only the monitor if interrupted, not Dagu.

## Constraints

- Never answer a pipeline question or choose to continue a loop yourself. Pass my words unchanged.
- Do not edit project files, pipeline documents, or workflow files. The pipeline owns them.
- Use version control only for read-only inspection.
- Do not stop, retry, or dequeue a run without my approval.
- Never stop a Dagu process.

## Stop conditions

- No description provided.
