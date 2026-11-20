# Utility

Each skill here is invoked on its own and shares no artifact chain with any other. See `../README.md` for installation.

## `init-agents-md`

Run `/init-agents-md` inside any repo to write a minimal `AGENTS.md` at its root from an investigation of the repo plus a short interview. Every line must earn its place: only information an agent
could not infer from the repo itself.

## `solo-review`

Run `/solo-review` to review a set of code changes (file paths, a directory, a git diff range, or the uncommitted working tree) against loose context — a free-text intent, a pasted ticket, or a
document you point it at — or, with no context, for correctness and convention compliance alone. When it finds issues, it writes them to a `REVIEW.md`; when it finds none, it writes no file.

## `solo-address-review`

Run `/solo-address-review` with a review file or pasted findings to validate claims, fix confirmed issues, and run checks. It accepts any code review format and optional requirements or context. With no review input, it reads `REVIEW.md` in the current working directory. It updates finding statuses in a local review file or reports them in chat for pasted reviews. It requires no pipeline documents.

## `push-review`

Run `/push-review` with a GitHub pull request URL and, optionally, a review file to post each finding as an inline comment on the pull request. With no review file, it uses the `.md`, `.txt`, or `.html` file in the current working directory whose name contains `review`. It submits one comment-only review with no summary. Findings it cannot anchor to the pull request diff are reported in chat. Requires the GitHub MCP server.

## `pull-review`

Run `/pull-review` with a GitHub pull request URL to write every review, inline thread with replies, and conversation comment to `REVIEW.md` in the current working directory. It writes no file when the pull request has no review activity. Requires the GitHub MCP server.

## `commit`

Run `/commit` to commit the staged changes, or `/commit <paths>` to commit only those tracked files. It writes a concise Conventional Commits message, shows it for approval, and commits after you approve. It never stages files; untracked files must be staged first.
