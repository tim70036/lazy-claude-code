---
name: coding-principles
description: Load before designing or writing code, data pipelines, schemas, APIs or repo docs. Holds the owner's design defaults, code standards and documentation rules.
---

# Design defaults

- Start from the business questions. Describe the final state (what exists and which question each part answers), not the process.
- Before building, define done as checks the owner can run (queries, test questions).
- Extend existing structures. Do not change the meaning of an existing field. Add only what a question needs.
- Prefer the smaller change. Keep nothing "for later": no unused fields, docs or code (YAGNI).
- Explicit over implicit: no magic, clear dependencies, no hidden side effects.
- Fail fast and loud: no silent failure; keep the error context.
- Treat a contract with another team as the source of truth. Confirm each field with a real example and the step where its value is computed.
- For architecture design, use ~/.claude/skills/architecture-principle.md as a reference. Select only the principles that apply to the decision.

# Code standards

- Readability first. Self-documenting code; add a comment only for a non-obvious constraint.
- Type safety, also in dynamic languages.
- Use a logger, not print or console.log. Exception: print is the documented best practice of the platform for that output.
- Do not give a default value to a required parameter or config value. The caller must set it.
- No emoji in code or documentation.

# Documentation

- Repo docs hold only durable knowledge for future development:
  - how to set up and run the code,
  - the reason behind each design, so a developer can make the right decision,
  - conventions to follow.
- No progress, release state, next steps or estimates in repo docs.
- Concise and easy to read. No duplicate content across sections.
- No details that change often, such as exact file paths or feature names, unless the doc is about them.
