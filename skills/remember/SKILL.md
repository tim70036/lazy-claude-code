---
name: remember
description: Persist a user-introduced fact, preference, procedure, or decision into the Graphiti knowledge graph. TRIGGER strictly when the user (1) explicitly asks to remember/save with "remember", "save this", "/remember", or "#kb"; OR (2) authoritatively states a durable personal preference, rule, procedure, or domain fact that a future assistant session could not derive from the codebase, git history, training data, or a web search. SKIP for ephemeral task state, generic explanations, code-derivable info, debugging steps, or anything you generated and the user merely accepted.
---

# Capture user knowledge to Graphiti

Make Graphiti the persistent memory of *the user's own viewpoint* — their preferences, decisions, procedures, and domain facts — so any future assistant session (across whatever tool the user is in) can recall them.

## The signal test

Before capturing anything, answer all four. **One "no" = skip.**

1. **Originated from the user.** Did the *user* introduce this, not the assistant? Assistant-generated content the user merely accepted is noise. The user's own statements, decisions, and corrections are signal.
2. **Non-derivable.** Could a fresh assistant session get this from the repo, git history, project docs, web search, or training data? If yes — skip; no point storing what's already retrievable.
3. **Durable.** Will this still matter in 3 months? Ephemeral task state, in-progress work, today's bugs → no. Preferences, identity facts, recurring procedures, lasting decisions → yes.
4. **Falsifiable & specific.** Can you state the claim concretely enough that it could be contradicted later? "Tim prefers FastAPI for new APIs because…" → yes. "Tim is good at backend" → no, too vague to act on.

## What to capture / what to skip

**Capture:**
- **Preferences** with reasoning ("I always do X over Y because…")
- **Procedures** — multi-step routines the user follows
- **Decisions** with reasoning — architectural or process choices and *why*
- **Domain facts** — team setup, infra ownership, deprecated systems, key URLs/IDs
- **Lessons learned** — "last time we did X it broke Y" corrections, with a *because*
- **Identity facts** — role, team, environment that frames future work

**Skip:**
- Anything you wrote or proposed, even if the user accepted it ("thanks", "looks good")
- Today's task state, current changes, in-progress work — that belongs in plans/tasks
- Generic technical knowledge ("Python uses indentation")
- Bug fixes — the fix is in git; only the *lesson* may be a preference
- Status updates ("I'm working on…")
- Anything you'd write a code comment for — write the comment instead

## How to capture

Each memory is **atomic**: one claim per `add_memory` call. If a turn contains multiple captureable items, make multiple calls.

### 1. Search first, always

Call `mcp__graphiti__search_nodes` with 2–3 keywords from the candidate.
- **Match exists & unchanged →** tell the user it's already known. Do not re-add.
- **Match exists but superseded →** capture as an update. Episode body must say `Supersedes: <prior claim>`.
- **No match →** proceed.

### 2. Classify into exactly one type

| Type | Use for |
|---|---|
| `pref` | A choice/judgment the user applies repeatedly |
| `proc` | A multi-step procedure the user follows |
| `fact` | A non-obvious truth about the user's world (team, infra, project) |
| `decision` | A specific decision with reasoning, time-bounded |
| `ref` | A pointer to where authoritative info lives (URLs, dashboards, repos) |

### 3. Episode body — mandatory three-line structure

```
<claim — one sentence, lead with the fact in plain language>
Why: <the reason the user gave, or the constraint that makes this rule load-bearing>
How to apply: <when/where this should fire — the trigger conditions for future agents>
```

If you cannot write a real `Why:` — not "the user said so" but an actual reason — the thing isn't worth saving. Skip.

### 4. Required metadata

- `name`: `<type>-<kebab-case-claim>`, ≤60 chars. Examples: `pref-no-direct-kubectl-on-prod`, `proc-pg-credential-rotation`.
- `source`: `"message"`
- `source_description`: `"Captured on <YYYY-MM-DD>"` — use the actual date.
- `group_id`: basename of `cwd` if it's clearly a project root; otherwise `"personal"`. Identity-level facts (role, preferences that apply everywhere) → always `"personal"`.

### 5. Confirmation discipline

- **User explicitly invoked** (`/remember`, `#kb`, or asked to save): proceed without asking.
- **Auto-triggered** (you noticed something captureable on your own): **state what you intend to capture and ask "save this?" before calling `add_memory`.** Silent guessing pollutes the graph.

### 6. After capture

Reply with exactly one line: `Saved: <name> (group: <group_id>)`. No commentary.

## Examples

**High-signal capture.** User: *"We never deploy on Fridays anymore — last time we did, on-call had to roll back at 11pm and we agreed it wasn't worth the risk."*
→ Type: `pref`. Body:
```
Tim's team does not deploy to production on Fridays.
Why: a Friday deploy required an 11pm rollback by on-call; team agreed late-week risk outweighs velocity gain.
How to apply: push back when asked to schedule a production deploy on a Friday; suggest Monday-Thursday.
```

**Low-signal — do not capture:**
- "fix the typo in line 42" → ephemeral, code change.
- "thanks, that's exactly what I needed" → assistant-generated content; user just accepted.
- "I'm using Postgres for this project" → derivable from the repo.
- "this is taking forever" → status / affect.

**Borderline — confirm first.** User mentions in passing: *"yeah, I usually prefer ruff over black because the speed difference matters at our codebase size."*
→ Captureable but offhand. Ask: *"That sounds like a durable preference — save as `pref-prefer-ruff-over-black`?"* Capture only on confirmation.

## Anti-patterns

- **Verbose captures.** `episode_body` > 5 sentences → you're transcribing, not capturing. Compress or split.
- **Cargo-cult Why.** "Why: because the user prefers it" is not a reason. The real `Why` is the user's *reasoning* (audit policy, past incident, performance constraint).
- **Compound claims.** "Tim prefers X and Y and also Z" → three memories.
- **Forward references.** "Apply when we set up the new service" — what new service? Be concrete or skip.
- **Re-capturing your own work.** Generating advice and then saving it as a memory is a hall of mirrors. Only the user's deliberate *commitment* to it ("yes, I'll always do that going forward") qualifies.

## Closing principle

**Memory is read more than it's written.** Every entry will be retrieved many times by future agents trying to act on it. Write so that future agents can act with confidence. Vague memories get retrieved at the wrong times and erode trust in the whole graph.
