# self_config

跨服务器同步的个人终端配置：tmux、yazi、Neovim，以及基于 OSC 52 的剪切板打通链路（kitty/ghostty → SSH → tmux → 远端应用）。

## 内容

| 仓库路径 | 安装位置 |
|---|---|
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `yazi/.config/yazi/` | `~/.config/yazi/` |
| `nvim/.config/nvim/` | `~/.config/nvim/` |
| `bin/.local/bin/yazi-copy-text` | `~/.local/bin/yazi-copy-text` |

## 安装

```bash
git clone https://github.com/OsborneWang/self_config.git ~/self_config
~/self_config/install.sh
```

`install.sh` 是幂等的：已存在的同名文件/目录会被移动到 `~/.self_config-backup/<时间戳>/` 后再建符号链接（可通过 `SELF_CONFIG_BACKUP_ROOT` 覆盖备份目录）。

安装完成后：

```bash
tmux source-file ~/.tmux.conf   # 重载 tmux 配置
nvim --headless "+Lazy! sync" +qa   # 首次安装/同步 nvim 插件
```

## 依赖

- tmux >= 3.3（`allow-passthrough` 需要；本配置在 3.6 验证）
- Neovim >= 0.9 + git（LazyVim 自举，`lazy-lock.json` 锁定插件版本）
- yazi（`y` 函数需在 shell 中定义，见下）
- 可选：`glow`（yazi Markdown 预览）、`lazygit`（yazi 内 `gl` 快捷键）

## 剪切板链路（OSC 52）

本地终端（kitty/ghostty）→ SSH → 远端 tmux，全程不依赖远端 X11/系统剪切板：

- **tmux**：`set-clipboard on` 转发 OSC 52；`allow-passthrough on`；`terminal-features` 为 `xterm-kitty`/`ghostty` 开启 RGB 与 clipboard
- **nvim**：`lua/config/options.lua` 在 tmux 内使用 `vim.g.clipboard = "tmux"`，纯 SSH 时降级为 `osc52`，均配合 `clipboard=unnamedplus`
- **yazi**：`clipboard-sync.yazi` 插件调用 `yazi-copy-text` —— tmux 内写入 tmux buffer（`tmux set-buffer -w`），否则直接输出 OSC 52 序列

### 远端验证

```bash
# nvim 应输出 tmux
nvim --headless '+lua io.write(tostring(vim.g.clipboard))' +qa

# yazi 内按 cc 后应显示文件名
tmux show-buffer
```

粘回本地终端由 kitty/ghostty 侧处理（需终端允许 OSC 52 写入）。

### kitty terminfo

若 kitty SSH 连接后报 `missing or unsuitable terminal: xterm-kitty`，在远端执行：

```bash
infocmp xterm-kitty >/dev/null 2>&1 || tic -x ~/.terminfo/kitty.terminfo
```

（或把 `xterm-kitty` terminfo 放入 `terminfo/` 目录，`install.sh` 会自动 `tic` 安装。）

## shell 集成

yazi 的 `y` 包装函数（退出后 cd 到浏览目录），加入 `~/.zshrc`：

```zsh
function y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
  command yazi --cwd-file="$tmp" "$@"
  cwd="$(command cat -- "$tmp")"
  command rm -f -- "$tmp"
  if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
}
```
