---
name: commit
description: Write a Conventional Commits message for staged or specified files and commit after my approval.
disable-model-invocation: true
---

## Main Objective

Commit a set of changes with a concise Conventional Commits message that I approve first.

## Inputs

- **Files (optional).** Paths to commit instead of the staged changes.
- Nothing → the staged changes.

## Workflow

1. Resolve the change set.
    - No files given: read `git diff --cached`. Stop and tell me if nothing is staged.
    - Files given: read `git diff HEAD -- <paths>`. Stop and tell me if a path is untracked or has no changes.
2. Read the repository's commit conventions: `git log` subjects, commit-lint configuration, and contribution or agent instruction files.
3. Write the message per the message rules.
4. Show me the message and wait for approval. If I request changes, revise and show it again.
5. Commit after approval. Check that the change set still matches step 1; if not, return to step 1. Pass the message through a quoted heredoc to `git commit -F -`. With files given, append `-- <paths>`.
6. Confirm with a one-line message: the commit hash and subject. If the commit fails, show the error output.

## Message rules

- Follow the Conventional Commits specification: `<type>: <description>`.
- Pick the type that matches the change: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `style`, `chore`, or `revert`. Mark a breaking change with `!` after the type.
- Add a scope only when a repository rule or convention requires one.
- Write the description in imperative mood, without a trailing period, within 72 characters. Match the repository's casing.
- Add a body only when the subject cannot explain the change alone. The body is a blank line followed by `- ` bullet points, one short line each.
- Add no footer and no trailers, including `Co-authored-by` and generated-by lines.
- Be concise. State what changed and why; do not list files or restate the diff.

## Constraints

- Never run `git add` or any other staging command. With files given, commit them through `git commit -- <paths>` only.
- Never pass `--no-verify`, `--amend`, or `--allow-empty`.
- Run no git command that mutates the repository other than the approved `git commit`.

## Stop conditions

- Nothing is staged and no files are given.
- A given path is untracked or unchanged.
- I reject the message without requesting changes.
