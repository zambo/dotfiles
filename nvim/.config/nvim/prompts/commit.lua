return {
  diff = function(args)
    -- Strategy: Get the full diff but exclude large binary/repetitive dirs
    -- First try with minimal context
    local diff = vim.system({ "git", "diff", "--no-ext-diff", "--staged", "-U1" }, { text = true }):wait().stdout
    
    -- Count newlines
    local newline_count = 0
    for _ in diff:gmatch("\n") do
      newline_count = newline_count + 1
    end
    
    -- If still too large, get stat and then key file diffs
    if newline_count > 8000 then
      -- Show stat for overview
      local stat = vim.system({ "git", "diff", "--no-ext-diff", "--staged", "--stat" }, { text = true }):wait().stdout
      
      -- Get diffs for important files (non-fish shell files)
      local important_diff = vim.system(
        { "git", "diff", "--no-ext-diff", "--staged", "-U0", "--", 
          "nvim/", "direnv/", "git/", "lefthook.yml" }, 
        { text = true }
      ):wait().stdout
      
      if important_diff and important_diff ~= "" then
        return "FILE SUMMARY:\n" .. stat .. "\n\n--- KEY CHANGES ---\n" .. important_diff
      else
        return "FILE SUMMARY:\n" .. stat
      end
    end
    
    -- Escape % for Lua gsub safety
    return (diff:gsub("%%", "%%%%"))
  end,
}
