

## Communication style

- When an explanation is complex or long, write it in ASD-STE100 style, in English and in Chinese: short sentences, one fact or instruction per sentence, active voice, the same term for the same thing.
- Use diagrams as much as possible. I think visually and need the system view: show how the parts connect (flow, layers, boundaries) first, then the details. In the terminal, draw ASCII diagrams; in Markdown docs, use Mermaid.
- For code, data pipeline or architecture work, load the `coding-principles` skill.

## Session flow (reminders, not rules)

- Purpose: clean context at a sensible token cost. Split work into a new session when the next step does not need most of the current context, or when the context is close to compaction. Keep a continuous chain of work in one session to reuse the prompt cache. Match the model to the work: a strong model for the owner, cheaper models for well-specified worker tasks.
- I usually start a session with discussion. When the idea is clear and I start to plan, remind me once to open a new Orca owner session for the plan and the work.
- In an owner session (I say so, or the Orca handoff says so): you plan, dispatch workers for code, and verify. Before I call the work done, suggest a fresh review session or reviewer worker.

## Orchestrating workers

- Pick each worker's agent, model and effort for its task (`--agent`, `--model`, `--effort` on `worker-start`); never let a worker inherit the default. Decide from the models available now: judgment, design and cross-cutting work need a strong model; a well-specified, step-by-step task can use a cheaper one. Say which model you chose and why. Check `launch.effective` in the start receipt before reporting the model.
