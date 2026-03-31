/**
 * Mapping of GSD agent to model for each profile.
 *
 * Should be in sync with the profiles table in `get-shit-done/references/model-profiles.md`. But
 * possibly worth making this the single source of truth at some point, and removing the markdown
 * reference table in favor of programmatically determining the model to use for an agent (which
 * would be faster, use fewer tokens, and be less error-prone).
 */
const MODEL_PROFILES = {
  'gsd-planner':             { quality: 'github-copilot/claude-opus-4.6', balanced: 'github-copilot/claude-opus-4.6', budget: 'fuel_ix/claude-sonnet-4-6' },
  'gsd-roadmapper':          { quality: 'github-copilot/claude-opus-4.6', balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-sonnet-4-6' },
  'gsd-executor':            { quality: 'github-copilot/claude-opus-4.6', balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-sonnet-4-6' },
  'gsd-phase-researcher':    { quality: 'github-copilot/claude-opus-4.6', balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-haiku-4-5' },
  'gsd-project-researcher':  { quality: 'github-copilot/claude-opus-4.6', balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-haiku-4-5' },
  'gsd-research-synthesizer':{ quality: 'fuel_ix/claude-sonnet-4-6',      balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-haiku-4-5' },
  'gsd-debugger':            { quality: 'github-copilot/claude-opus-4.6', balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-sonnet-4-6' },
  'gsd-codebase-mapper':     { quality: 'fuel_ix/claude-sonnet-4-6',      balanced: 'fuel_ix/claude-haiku-4-5',       budget: 'fuel_ix/claude-haiku-4-5' },
  'gsd-verifier':            { quality: 'fuel_ix/claude-sonnet-4-6',      balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-haiku-4-5' },
  'gsd-plan-checker':        { quality: 'fuel_ix/claude-sonnet-4-6',      balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-haiku-4-5' },
  'gsd-integration-checker': { quality: 'fuel_ix/claude-sonnet-4-6',      balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-haiku-4-5' },
  'gsd-nyquist-auditor':     { quality: 'fuel_ix/claude-sonnet-4-6',      balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-haiku-4-5' },
  'gsd-ui-researcher':       { quality: 'github-copilot/claude-opus-4.6', balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-haiku-4-5' },
  'gsd-ui-checker':          { quality: 'fuel_ix/claude-sonnet-4-6',      balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-haiku-4-5' },
  'gsd-ui-auditor':          { quality: 'fuel_ix/claude-sonnet-4-6',      balanced: 'fuel_ix/claude-sonnet-4-6',      budget: 'fuel_ix/claude-haiku-4-5' },
};
const VALID_PROFILES = Object.keys(MODEL_PROFILES['gsd-planner']);

/**
 * Formats the agent-to-model mapping as a human-readable table (in string format).
 *
 * @param {Object<string, string>} agentToModelMap - A mapping from agent to model
 * @returns {string} A formatted table string
 */
function formatAgentToModelMapAsTable(agentToModelMap) {
  const agentWidth = Math.max('Agent'.length, ...Object.keys(agentToModelMap).map((a) => a.length));
  const modelWidth = Math.max(
    'Model'.length,
    ...Object.values(agentToModelMap).map((m) => m.length)
  );
  const sep = '─'.repeat(agentWidth + 2) + '┼' + '─'.repeat(modelWidth + 2);
  const header = ' ' + 'Agent'.padEnd(agentWidth) + ' │ ' + 'Model'.padEnd(modelWidth);
  let agentToModelTable = header + '\n' + sep + '\n';
  for (const [agent, model] of Object.entries(agentToModelMap)) {
    agentToModelTable += ' ' + agent.padEnd(agentWidth) + ' │ ' + model.padEnd(modelWidth) + '\n';
  }
  return agentToModelTable;
}

/**
 * Returns a mapping from agent to model for the given model profile.
 *
 * @param {string} normalizedProfile - The normalized (lowercase and trimmed) profile name
 * @returns {Object<string, string>} A mapping from agent to model for the given profile
 */
function getAgentToModelMapForProfile(normalizedProfile) {
  const agentToModelMap = {};
  for (const [agent, profileToModelMap] of Object.entries(MODEL_PROFILES)) {
    agentToModelMap[agent] = profileToModelMap[normalizedProfile];
  }
  return agentToModelMap;
}

module.exports = {
  MODEL_PROFILES,
  VALID_PROFILES,
  formatAgentToModelMapAsTable,
  getAgentToModelMapForProfile,
};
