# Model Profiles

Model profiles control which Claude model each GSD agent uses. This allows balancing quality vs token spend, or inheriting the currently selected session model.

## Profile Definitions

| Agent | `quality` | `balanced` | `budget` | `inherit` |
|-------|-----------|------------|----------|-----------|
| gsd-planner | github-copilot/claude-opus-4.6 | github-copilot/claude-opus-4.6 | fuel_ix/claude-sonnet-4-6 | inherit |
| gsd-roadmapper | github-copilot/claude-opus-4.6 | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-sonnet-4-6 | inherit |
| gsd-executor | github-copilot/claude-opus-4.6 | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-sonnet-4-6 | inherit |
| gsd-phase-researcher | github-copilot/claude-opus-4.6 | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-haiku-4-5 | inherit |
| gsd-project-researcher | github-copilot/claude-opus-4.6 | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-haiku-4-5 | inherit |
| gsd-research-synthesizer | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-haiku-4-5 | inherit |
| gsd-debugger | github-copilot/claude-opus-4.6 | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-sonnet-4-6 | inherit |
| gsd-codebase-mapper | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-haiku-4-5 | fuel_ix/claude-haiku-4-5 | inherit |
| gsd-verifier | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-haiku-4-5 | inherit |
| gsd-plan-checker | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-haiku-4-5 | inherit |
| gsd-integration-checker | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-haiku-4-5 | inherit |
| gsd-nyquist-auditor | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-sonnet-4-6 | fuel_ix/claude-haiku-4-5 | inherit |

## Profile Philosophy

**quality** - Maximum reasoning power
- Opus for all decision-making agents
- Sonnet for read-only verification
- Use when: quota available, critical architecture work

**balanced** (default) - Smart allocation
- Opus only for planning (where architecture decisions happen)
- Sonnet for execution and research (follows explicit instructions)
- Sonnet for verification (needs reasoning, not just pattern matching)
- Use when: normal development, good balance of quality and cost

**budget** - Minimal Opus usage
- Sonnet for anything that writes code
- Haiku for research and verification
- Use when: conserving quota, high-volume work, less critical phases

**inherit** - Follow the current session model
- All agents resolve to `inherit`
- Best when you switch models interactively (for example OpenCode `/model`)
- Use when: you want GSD to follow your currently selected runtime model

## Resolution Logic

Orchestrators resolve model before spawning:

```
1. Read .planning/config.json
2. Check model_overrides for agent-specific override
3. If no override, look up agent in profile table
4. Pass model parameter to Task call
```

## Per-Agent Overrides

Override specific agents without changing the entire profile:

```json
{
  "model_profile": "balanced",
  "model_overrides": {
    "gsd-executor": "github-copilot/claude-opus-4.6",
    "gsd-planner": "fuel_ix/claude-haiku-4-5"
  }
}
```

Overrides take precedence over the profile. Valid values: any full model ID (e.g. `github-copilot/claude-opus-4.6`, `fuel_ix/claude-sonnet-4-6`, `fuel_ix/claude-haiku-4-5`) or `inherit`.

## Switching Profiles

Runtime: `/gsd-set-profile <profile>`

Per-project default: Set in `.planning/config.json`:
```json
{
  "model_profile": "balanced"
}
```

## Design Rationale

**Why Opus for gsd-planner?**
Planning involves architecture decisions, goal decomposition, and task design. This is where model quality has the highest impact.

**Why Sonnet for gsd-executor?**
Executors follow explicit PLAN.md instructions. The plan already contains the reasoning; execution is implementation.

**Why Sonnet (not Haiku) for verifiers in balanced?**
Verification requires goal-backward reasoning - checking if code *delivers* what the phase promised, not just pattern matching. Sonnet handles this well; Haiku may miss subtle gaps.

**Why Haiku for gsd-codebase-mapper?**
Read-only exploration and pattern extraction. No reasoning required, just structured output from file contents.

**Why full model IDs instead of tier aliases?**
OpenCode requires provider-prefixed model IDs (e.g. `github-copilot/claude-opus-4.6`) rather than generic aliases like `"opus"`. The quality tier maps to `github-copilot/claude-opus-4.6` (via GitHub Copilot), balanced to `fuel_ix/claude-sonnet-4-6`, and budget to `fuel_ix/claude-haiku-4-5`.

**Why `inherit` profile?**
Some runtimes (including OpenCode) let users switch models at runtime (`/model`). The `inherit` profile keeps all GSD subagents aligned to that live selection.
