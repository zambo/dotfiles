# Model Profile Resolution

Resolve model profile once at the start of orchestration, then use it for all Task spawns.

## Resolution Pattern

```bash
MODEL_PROFILE=$(cat .planning/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "balanced")
```

Default: `balanced` if not set or config missing.

## Lookup Table

@/Users/henriquerodrigues/.config/opencode/get-shit-done/references/model-profiles.md

Look up the agent in the table for the resolved profile. Pass the model parameter to Task calls:

```
Task(
  prompt="...",
  subagent_type="gsd-planner",
  model="{resolved_model}"  # "inherit", "fuel_ix/claude-sonnet-4-6", "fuel_ix/claude-haiku-4-5", or "github-copilot/claude-opus-4.6"
)
```

**Note:** Quality-tier agents resolve to `"github-copilot/claude-opus-4.6"`. Balanced-tier agents resolve to `"fuel_ix/claude-sonnet-4-6"`. Budget-tier agents resolve to `"fuel_ix/claude-haiku-4-5"`. The `inherit` profile causes all agents to resolve to `"inherit"`, using the parent session's model.

If `model_profile` is `"inherit"`, all agents resolve to `"inherit"` (useful for OpenCode `/model`).

## Usage

1. Resolve once at orchestration start
2. Store the profile value
3. Look up each agent's model from the table when spawning
  4. Pass model parameter to each Task call (values: `"inherit"`, `"fuel_ix/claude-sonnet-4-6"`, `"fuel_ix/claude-haiku-4-5"`, `"github-copilot/claude-opus-4.6"`)
