local M = {}

local function stem(name)
  local base, ext = name:match("^(.*)%.([^./]+)$")
  if base and base ~= "" and ext and not base:match("^%.$") then
    return base
  end
  return name
end

local state = ya.sync(function()
  local hovered = cx.active.current.hovered
  local selected = {}

  for _, url in pairs(cx.active.selected) do
    selected[#selected + 1] = tostring(url)
  end

  return {
    cwd = tostring(cx.active.current.cwd),
    hovered_url = hovered and tostring(hovered.url) or nil,
    hovered_name = hovered and hovered.name or nil,
    selected = selected,
  }
end)

local function selected_or_hovered(st)
  if #st.selected > 0 then
    return table.concat(st.selected, "\n")
  elseif st.hovered_url then
    return st.hovered_url
  else
    return st.cwd
  end
end

local function resolve_text(mode, st)
  if mode == "path" then
    return st.hovered_url or st.cwd
  elseif mode == "dirname" then
    return st.cwd
  elseif mode == "filename" then
    return st.hovered_name or ""
  elseif mode == "name_without_ext" then
    return st.hovered_name and stem(st.hovered_name) or ""
  elseif mode == "selected" then
    return selected_or_hovered(st)
  end
end

local function copy_to_clipboard(text)
  local child, err = Command((os.getenv("HOME") or "") .. "/.local/bin/yazi-copy-text")
    :arg(text)
    :stdout(Command.NULL)
    :stderr(Command.PIPED)
    :spawn()

  if not child then
    return false, Err("Failed to start clipboard helper: %s", err)
  end

  local output, wait_err = child:wait_with_output()
  if not output then
    return false, Err("Failed to wait for clipboard helper: %s", wait_err)
  elseif not output.status.success then
    local stderr = output.stderr or ""
    stderr = stderr:gsub("%s+$", "")
    return false, Err("Clipboard helper exited with code %s%s", output.status.code, stderr ~= "" and (": " .. stderr) or "")
  end

  return true
end

function M:entry(job)
  local mode = job.args[1] or "selected"
  local st = state()
  local text = resolve_text(mode, st)

  if text == nil or text == "" then
    return ya.notify { title = "Clipboard", content = "Nothing to copy", timeout = 2, level = "warn" }
  end

  local ok, err = copy_to_clipboard(text)
  if not ok then
    return ya.notify { title = "Clipboard", content = tostring(err), timeout = 5, level = "error" }
  end
end

return M
