-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.env.TMUX and vim.fn.executable("tmux") == 1 then
  -- Use tmux's clipboard bridge inside remote tmux sessions.
  vim.g.clipboard = "tmux"
  vim.opt.clipboard = "unnamedplus"
elseif vim.env.SSH_CONNECTION then
  -- Outside tmux, force OSC52 instead of remote X11 tools.
  vim.g.clipboard = "osc52"
  vim.opt.clipboard = "unnamedplus"
end
