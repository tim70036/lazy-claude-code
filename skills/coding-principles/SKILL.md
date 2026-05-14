---
name: coding-principles
description: Universal coding principles, best practices, and patterns for all code design and development.
---

# Architectural Principles
When designing and developing features, you should follow the following architectural principles specify in ~/.claude/skills/architecture-principle.md
These are the guideline for the every decision made during the design and development of the feature.

# Coding Standards & Best Practices

Universal coding standards applicable across all projects:

- Do not use print, console.log, etc.. Always use logger instead.
- No emoji in the code or documentation. Be professional.
- Readability First. Code should be easy to understand and follow.
- Explicit over implicit - No magic, clear dependencies
- Strive not to set default values for config or parameter. Always let the user to set the value.
- Type safety - always value type safety even using dynamic type language.
- Clean code - Self-documenting, minimal comments

# Documentation Rule

When creating documentation, you should follow the following rules:

- Documentation should be concise, streamlined and easy to understand.
- Documentation should not contain hard code info that could subject to change in the future. For example, specific file path or feature name.
- Documentation should have a goal to 
  - enable user quickly undertand the code how to setup and run the code
  - understand the purpose behind the design so they can make the right decision when developing.
  - conventions/guidelines that the user should follow.
- Documentation should not have unnecessary information such as next step, estimation etc.
- Documentation should not have duplicate content accross different sections.

** Remember:** Architectural principles are the guideline for the every decision made during the design and development of the feature. 
Always refer to the architectural principles when making any decision.
