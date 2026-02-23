---
name: ralph
description: "Convert a PRD to prd.json for the Ralph autonomous agent loop."
user-invokable: true
---

# PRD to prd.json Converter

You convert markdown PRDs into the `scripts/ralph/prd.json` format for autonomous execution.

## Workflow

### Step 1: Find the PRD

Ask the user which PRD to convert. Check `scripts/ralph/tasks/` for available PRDs. If only one exists, confirm it.

### Step 2: Archive Existing prd.json

If `scripts/ralph/prd.json` already exists and has a different `branchName`, archive it:
1. Read the existing `branchName`
2. Create `scripts/ralph/archive/[date]-[branchName]/`
3. Copy `prd.json` and `progress.txt` into the archive
4. Reset `progress.txt` to the empty template

### Step 3: Convert

Read the PRD and generate `scripts/ralph/prd.json` with this structure:

```json
{
  "project": "Pemberton FX Hedging Prototype",
  "branchName": "ralph/[feature-name-kebab-case]",
  "description": "[Feature description from PRD]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "[Full story description]",
      "acceptanceCriteria": [
        "Specific criterion from PRD",
        "dotnet build passes",
        "Unit tests pass",
        "E2E tests pass"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Step 4: Verify & Confirm

Print a summary table:

| ID | Title | Priority | AC Count |
|----|-------|----------|----------|

Ask the user to confirm before writing.

### Step 5: Launch Ralph (Optional)

After writing `prd.json`, ask the user: **"Launch Ralph now?"**

If yes, run the Docker container:

```bash
./scripts/ralph/docker-run.sh --prd scripts/ralph/prd.json
```

Offer relevant flags based on context:
- `--no-push` if the user hasn't mentioned pushing
- `--max-iterations <n>` if the user has a preference
- `--rebuild-base` if this is the first run or the base image may be stale

This reduces the workflow from 3 steps (convert PRD, build image, run container) to a single skill invocation.

## Conversion Rules

1. **IDs** are sequential: US-001, US-002, etc.
2. **Priority** reflects dependency order (1 = first to implement):
   - Models and data classes first
   - Services and business logic second
   - ViewModels third
   - Pages and UI components fourth
   - Integration/E2E tests last
3. All stories start with `passes: false` and empty `notes`
4. **`branchName`** is `ralph/` + feature name in kebab-case
5. Every story MUST include `dotnet build passes` in acceptance criteria
6. Every story MUST include `Unit tests pass` in acceptance criteria
7. Every story MUST include `E2E tests pass` in acceptance criteria

## The Number One Rule

> Each story must be completable in ONE Ralph iteration (one context window).

Stories that change application code must include writing unit tests AND E2E tests as part of the implementation. Test authorship is not a separate story — it's part of completing each story.

If a PRD story is too large, split it. Signs it's too large:
- Touches more than 4 files
- Requires both backend and frontend changes
- Has more than 5 acceptance criteria
- Description is longer than 3 sentences
