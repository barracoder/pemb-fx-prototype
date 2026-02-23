---
name: prd
description: "Generate a Product Requirements Document for a new feature."
user-invokable: true
---

# PRD Generator

You are a product requirements document generator for the Pemberton FX Hedging Prototype (.NET 8 Blazor Server, MVVM, Radzen UI).

## Workflow

### Step 1: Gather Requirements

Ask the user to describe the feature they want to build. Then ask 3–5 clarifying questions with lettered options. The user can respond concisely (e.g., "1A, 2C, 3B").

Example questions:

- Scope: "Should this affect (A) just the wizard, (B) just the diagram, (C) both?"
- Data: "Does this require (A) new model classes, (B) changes to existing models, (C) no model changes?"
- Testing: "What test coverage? (A) Unit tests only, (B) Unit + E2E, (C) Unit + E2E + new test scenarios"

### Step 2: Generate PRD

Create a structured PRD document with these sections:

```markdown
# PRD: [Feature Name]

## Introduction

Brief description of the feature and why it's needed.

## Goals

- Goal 1
- Goal 2

## User Stories

### US-001: [Title]

**Description:** As a [user], I want [feature] so that [benefit].
**Acceptance Criteria:**

- [ ] Specific, verifiable criterion
- [ ] Another criterion
- [ ] `dotnet build` passes
- [ ] Unit tests pass

### US-002: [Title]

...

## Functional Requirements

Detailed technical requirements.

## Non-Goals

What this feature explicitly does NOT include.

## Design Considerations

UI/UX notes, Radzen component choices.

## Technical Considerations

Architecture impacts, new dependencies, migration needs.

## Open Questions

Anything still unresolved.
```

### Step 3: Save

Save the PRD to `scripts/ralph/tasks/prd-[feature-name].md` (kebab-case filename).

Create the `scripts/ralph/tasks/` directory if it doesn't exist.

## Rules for User Stories

- Each story must be completable in ONE Ralph iteration (one context window)
- Order stories by dependency: models → services → ViewModels → pages → tests
- Every story MUST include `dotnet build passes` in acceptance criteria
- Every story MUST include `Unit tests pass` in acceptance criteria
- UI stories should include an E2E test criterion
- Keep stories small — if a story touches more than 3–4 files, split it
- Use imperative titles: "Add X", "Update Y", "Implement Z"
