---
name: push-review
description: Post a local code review to a GitHub pull request as inline review comments.
disable-model-invocation: true
---

## Main Objective

Post every finding of a local review file as an inline comment on a GitHub pull request. Submit them as one review with no summary and no verdict.

## Inputs

- **Pull request URL (required).** `https://github.com/<owner>/<repo>/pull/<number>`, optionally followed by a subpath such as `/files`.
- **Review file (optional).** A path to a review in any format. If not supplied, search the current working directory, not its subdirectories, for `.md`, `.txt`, and `.html` files whose name contains `review`, ignoring case. Use the single match. If several match, ask me which one to use.

## Workflow

1. Check GitHub access. Confirm that GitHub MCP server tools are available, then fetch the authenticated user. Stop if the tools are missing or the call fails.
2. Resolve the inputs. Parse owner, repository, and number from the URL. Read the review file in full; for HTML, read its text content. Identify each finding separately with its sites: file, lines, and quoted code.
3. Load the pull request: head commit SHA, changed files with their diff hunks, existing reviews, and existing review threads. Stop without changing anything if a pending review by the authenticated user already exists.
4. Anchor each finding. For each site:
    - Locate the cited code in the file at the head commit. Review line numbers may be stale; relocate by the quoted code. Skip the site if the quoted code is not found. Use the cited lines as given when the site quotes no code.
    - Use a line comment on the `RIGHT` side when every cited line lies inside one diff hunk. For a range, set the start line and the end line.
    - Otherwise, use a file-level comment when the file is in the pull request. Name the lines in the body.
    - Skip the site when the file is not in the pull request.
    - Give a finding with no code site a file-level comment on the file it names, if that file is in the pull request. Skip it otherwise.
5. Deduplicate. Post the full comment on the first anchored site of a finding. On each other site, post `Same issue as the comment on <path>:<line>.` Skip any comment already present at the same anchor from the authenticated user.
6. Post. Create one pending review on the head commit and add every comment to it. If a line comment is rejected, retry it as a file-level comment; skip it if that also fails. Submit the review with event `COMMENT` and an empty body. Never approve or request changes.
7. Confirm in chat: the number of comments posted, the review link, and each skipped finding with its reason.

## Comment style

Every full comment uses this fixed format:

```md
**<Label>:** <What is wrong at this code, in 1–2 sentences.>

<Fix, in one sentence, only when the review states one.>
```

- `<Label>` is the review's category for the finding: `Intent`, `Out of scope`, `Convention`, `Constraint`, `Correctness`, `Quality`, or `Tests`. If the review has no category, pick the closest one from this set.
- On a line comment, write the fix as a `suggestion` block instead of a sentence when it is an exact replacement of the commented lines. File-level comments state the fix as a sentence.
- Address the code at the anchor directly. Wrap identifiers, paths, and code in backticks.
- Do not include headings, tables, issue numbers, the review's title or section names, the anchored line numbers, praise, hedging, or references to the review file.
- Keep the finding's language and meaning. Add no findings, severities, or claims absent from the review.

## Constraints

- Post only inline review comments: line or file-level. Post no review summary, no general conversation comment, and no reply to existing threads.
- Do not modify the review file or local code.
- Use version control only for read-only inspection.

## Stop conditions

- GitHub MCP server tools are unavailable or fail.
- The URL is not a GitHub pull request URL.
- A pending review by the authenticated user already exists on the pull request.
- No review file is found, or it is unreadable or empty. Report it to me.
- No finding can be anchored. Create no review.
