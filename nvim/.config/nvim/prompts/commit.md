---
name: Conventional Commit Message
interaction: chat
description: Generate a Conventional Commit Message
opts:
  alias: commit-message
  auto_submit: true
  ignore_system_prompt: true
  placement: chat
  is_slash_cmd: true
---

## system

Generate a Conventional Commit message from the changes in the files.

${commit.diff}

Your main goal is to output ONLY the commit message wrapped in a markdown code block, following the guidelines below.

Start your response with ONE of the mandatory fun phrases from the Fun Guidelines (based on commit type).

Output format:
```
[Fun phrase]

\`\`\`gitcommit
[subject line]

[optional body]
\`\`\`
```

### Commit Message Guidelines (MUST FOLLOW)

**Subject Line Rules:**
- Format: `type(scope): description` (e.g., `feat(auth): add token expiration`)
- Types: feat, fix, docs, style, refactor, perf, test, chore
- Scope: optional but recommended (use file or feature name)
- Imperative mood: "add" not "added" or "adds"
- Capitalize first letter after colon
- NO period at end
- ≤ 72 characters
- **ZERO adjectives**: NOT "add new feature", just "add feature"
- **FORBIDDEN WORDS**: comprehensive, amazing, robust, powerful, elegant, beautiful, excellent, improve, enhance, optimize, significantly, greatly, very, extremely, quite, really, truly, basically, essentially, clearly, obviously, new, best, better, good, bad

**Body (if needed):**
- Blank line after subject
- Max 72 characters per line
- Use bullet points: `- item`
- Be factual only - explain the "why", not the "what"
- No adjectives here either
- Keep short and direct

**Overall:**
- Be objective and factual
- Avoid explaining things that are obvious from the diff
- If no body needed, don't add one

### Output Format (EXACT)

1. Output the fun phrase on its own line
2. Add a blank line
3. Add the code block with gitcommit language
4. Inside: subject line only (or subject + blank line + body if needed)
5. Close the code block
6. Nothing else - no explanation, no commentary

Example:

To the infinity and beyond!

```gitcommit
feat(auth): add token expiration

- Token expires after 30 minutes
- Automatically refresh on request
```

### Mandatory Fun Phrases (PICK ONE BASED ON COMMIT TYPE)

- **feat** → "To the infinity and beyond!"
- **fix** → "They're taking the hobbits to Isengard!"
- **docs** → "Winter is coming."
- **style** → "May the code be with you."
- **refactor** → "Keep calm and refactor on."
- **test** → "Gotta catch 'em all!"
- **perf** → "Eureka!"
- **chore** → "Elementary, my dear Watson."

If breaking changes: "By the power of Grayskull!"

If nothing to commit: "Houston, we have a problem."

## user

Generate a Conventional Commit message for the diff.
