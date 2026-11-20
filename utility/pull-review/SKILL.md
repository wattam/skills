---
name: pull-review
description: Pull every review, comment, and conversation from a GitHub pull request into a local REVIEW.md.
disable-model-invocation: true
---

## Main Objective

Write all review activity of a GitHub pull request to `REVIEW.md` in the current working directory.

## Inputs

- **Pull request URL (required).** `https://github.com/<owner>/<repo>/pull/<number>`, optionally followed by a subpath such as `/files`.

## Workflow

1. Check GitHub access. Confirm that GitHub MCP server tools are available, then fetch the authenticated user. Stop if the tools are missing or the call fails.
2. Parse owner, repository, and number from the URL.
3. Fetch every page of:
    - Pull request metadata: title, URL, head commit SHA.
    - Reviews: author, state, body, submission time.
    - Review threads: path, side, current and original lines, resolved and outdated flags, and every comment with author, body, and time.
    - Conversation comments: author, body, time.
4. Take the commented code of each line thread from the file at the head commit. For outdated threads and `LEFT`-side comments, take it from the comment's diff hunk.
5. Write the file to `REVIEW.md` in the current working directory. Overwrite if it exists. If the pull request has no reviews, threads, or conversation comments, write no file.
6. Confirm with a one-line message: the file written and the number of reviews, threads, and conversation comments, or that none were found and no file was written.

## Content rules

- Copy every body verbatim, including `suggestion` blocks, quotes, links, and bot comments. Convert Markdown headings inside bodies to bold text so the file structure stays intact. Do not summarize, translate, filter, or judge.
- Order reviews and conversation comments by time. Order threads by file path, then line.
- List every review in the `## Reviews` table. Give a review a numbered heading only when its body is not empty.
- Title each thread in at most 10 words, derived from its first comment.
- `Lines` refer to the head commit. Outdated threads use their original lines. Suffix `LEFT`-side lines with `(base)`. File-level threads use `—` for `Lines` and `Code`.
- `Code` holds the shortest snippet that identifies the commented lines.
- Write dates as `YYYY-MM-DD`.
- Omit any section that has no entries. Number headings sequentially from 1 within each section.

## File structure

```md
# Review: <pull request title> (#<number>)

<pull request URL>

## Reviews

| Reviewer | State               | Submitted  |
|----------|---------------------|------------|
| `@login` | `CHANGES_REQUESTED` | 2026-01-31 |
| `@login` | `APPROVED`          | 2026-02-02 |

### 1. `@login` — `CHANGES_REQUESTED`

<review body>

## Inline threads

### 1. <thread title>

Status: <open | resolved>[, outdated]

| File               | Lines | Code                  |
|--------------------|-------|-----------------------|
| `path/to/file.ext` | 12–14 | `<commented snippet>` |

**`@login`** (2026-01-31):

<comment body>

**`@login`** (2026-02-01):

<reply body>

## Conversation

### 1. `@login` (2026-01-31)

<comment body>
```

## Constraints

- Do not write to GitHub.
- Use version control only for read-only inspection.

## Stop conditions

- GitHub MCP server tools are unavailable or fail.
- The URL is not a GitHub pull request URL.
