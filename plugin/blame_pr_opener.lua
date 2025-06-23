-- plugin/blame_pr_opener.lua

vim.api.nvim_create_user_command(
  -- Command name
  'OpenGitBlamePR',
  -- Command function: calls the 'open' function from our module
  function()
    require('blame-pr-opener').open()
  end,
  -- Command attributes
  {
    nargs = 0,
    desc = 'Finds the commit for the current line and opens a PR search URL',
  }
)
