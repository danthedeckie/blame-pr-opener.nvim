-- lua/blame-pr-opener/init.lua

local M = {}

-- Default configuration options
local config = {
  -- The URL to open. '%s' is replaced with the commit ID.
  url_template = 'https://github.com/search?q=%s&type=pullrequests',

  -- Command to open the URL.
  -- If nil, the plugin will try to auto-detect the correct command.
  -- You can override it with a specific command, e.g., "brave" or {"wsl-open"}.
  open_command = nil,
  -- NEW: try to jump straight to GitHub commit page when true
  open_exact_commit = false,
}

function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend('force', config, opts)
end

-- Returns a GitHub commit-page URL if the current repo’s origin is on GitHub,
-- or nil otherwise.
local function github_commit_url(commit_id)
  local remote = vim.fn.trim(vim.fn.system({ 'git', 'config', '--get', 'remote.origin.url' }))
  if remote == '' or not remote:find('github%.com') then return nil end

  -- matches both “git@github.com:owner/repo(.git)” and “https://github.com/owner/repo(.git)”
  local owner, repo = remote:match('github%.com[:/]+([^/]+)/([^%.]+)')
  if not (owner and repo) then return nil end

  return string.format('https://github.com/%s/%s/commit/%s', owner, repo, commit_id)
end

function M.open()
  local filename = vim.fn.expand('%:p')
  if not filename or filename == '' then
    print('Error: No filename found. Cannot run git blame.')
    return
  end

  local linenumber = vim.api.nvim_win_get_cursor(0)[1]
  local command_str = string.format('git blame -ls -L%d,%d %s', linenumber, linenumber, vim.fn.shellescape(filename))

  local blame_output = vim.fn.system(command_str)

  if vim.v.shell_error ~= 0 or blame_output == '' then
    print('Error running git blame. Is this file tracked by git?')
    return
  end

  local commit_id = blame_output:match('^([^%s]+)')
  if not commit_id then
    print('Could not parse commit ID from git blame output.')
    return
  end

  -- Build the URL
  local url
  if config.open_exact_commit then
    url = github_commit_url(commit_id)
  end
  -- fall back to search URL if exact commit URL couldn't be built
  if not url then
    url = string.format(config.url_template, commit_id)
  end

  -- Use the configured open command or auto-detect it
  local open_cmd
  if config.open_command then
    open_cmd = config.open_command
  elseif vim.fn.has('mac') == 1 then
    open_cmd = 'open'
  elseif vim.fn.has('unix') == 1 then
    open_cmd = 'xdg-open'
  elseif vim.fn.has('win32') == 1 then
    open_cmd = 'start'
  else
    print('Error: Unsupported OS and no open_command configured.')
    return
  end

  print('Opening URL: ' .. url)
  vim.fn.jobstart({ open_cmd, url })
end

return M
