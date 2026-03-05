---
allowed-tools: Bash(cm merge:*), Bash(cm find:*), Bash(cm changeset:*), Bash(cm wi:*)
description: Server-side merge to target branch + consolidate sub-branch comments (서버 사이드 병합 + 코멘트 정리)
argument-hint: "<target-branch-path>"
---

## Context

- Workspace info: !`cm wi 2>/dev/null`

## Your task

Merge the current branch into a target branch using server-side merge (no workspace switch), then collect and consolidate all sub-branch comments into the resulting merge changeset.

### Arguments

- If `$ARGUMENTS` contains a branch path (e.g., `/main/release`), use that as the **target branch**.
- If `$ARGUMENTS` is empty, ask the user: "어떤 브랜치로 병합할까요? (예: /main/release)"

The **source branch** is always the current workspace branch (parsed from workspace info above).

### Step 1: Confirm merge direction

Show the user the merge direction and ask for confirmation:
- **소스 (현재):** `{source_branch}`
- **대상:** `{target_branch}`
- "위 방향으로 서버 사이드 병합을 진행합니다. 계속할까요?"

### Step 2: Execute server-side merge

Run the merge without switching branches:
```
cm merge br:{source_branch} --to=br:{target_branch} --merge
```

- If the merge succeeds, proceed to Step 3.
- If the merge fails due to conflicts, show the error and stop. Inform the user: "충돌이 발생했습니다. PlasticSCM GUI에서 충돌을 해결하거나, 워크스페이스를 대상 브랜치로 전환하여 수동 병합해 주세요."
- If there is nothing to merge, inform the user and stop.

### Step 3: List changesets on the target branch

```
cm find changeset "where branch='{target_branch}'" --format="{changesetid}|{date}|{comment}" --nototal
```

Take the last two lines: latest (last) and previous (second-to-last).
If there are fewer than 2 changesets, the merge created the first changeset — use only the latest and skip comment collection.

### Step 4: Find all merges into the target branch

```
cm find merge "where dstbranch='{target_branch}'" --format="{dstchangeset}|{srcchangeset}|{srcbranch}" --nototal
```

Identify merges where `dstchangeset == latest` (these are the new merges since previous).

### Step 5: Collect sub-branch comments

For each merge source, find the previous merge from the same source branch to determine the changeset range. Then query sub-branch changesets in that range:
```
cm find changeset "where branch='{srcbranch}' and changesetid > {prevSrcCS} and changesetid <= {srcCS}" --format="{changesetid}|{comment}" --nototal
```

**Recursively check sub-branches** (max 3 levels deep). For each source branch in the range, check if it received merges from deeper sub-branches:
```
cm find merge "where dstbranch='{srcbranch}' and dstchangeset > {prevSrcCS} and dstchangeset <= {srcCS}" --format="{srcchangeset}|{srcbranch}|{srccomment}" --nototal
```

For each deeper sub-branch found, collect its changesets' comments.

### Step 6: Format and confirm

- Group by sub-branch (use the last segment of the branch path as the header)
- Format: `[BranchShortName]` header + `- comment` list
- Skip empty comments and remove duplicates
- Example:
  ```
  [feature-login]
  - Added OAuth2 login flow
  - Fixed token refresh logic

  [hotfix-ui]
  - Resolved layout overflow on mobile
  - Updated button styles
  ```
- Show the formatted comment to the user and ask for confirmation before applying.

### Step 7: Apply comment

Once confirmed:
```
cm changeset editcomment cs:{latest} "{combined_comment}"
```

Then verify:
```
cm find changeset "where changesetid={latest}" --format="{changesetid}|{date}|{comment}" --nototal
```

If no comments were found (all empty), inform the user and apply a default comment like "Merged {source_branch} into {target_branch}".

Do not use any other tools. Do not send any other text or messages besides these tool calls.
