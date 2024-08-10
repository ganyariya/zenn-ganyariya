---
title: "Neovim (lazy.nvim) で GitHub Copilot と Codeium を環境変数によって使い分ける"
emoji: "🎉"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["neovim", "lazy.nvim"]
published: true
---

# 概要

## この記事で行うこと

Neovim(lazy.nvim) を使っているときに、環境変数で AI Assistant である GitHub Copilot と Codeium を使い分ける方法についてまとめます。

## 対象読者像

- 個人では GitHub Copilot を契約していないが、会社では GitHub Copilot を使っている人
- Neovim を使っている人

## 背景

2024/07 から Neovim (lazy.nvim) を使い始めました。
ここで、AI コーディングツールを導入したときに以下の問題が発生しました。

- 会社では GitHub Copilot を使いたいが、個人では契約していないので個人開発では無料の Codeium を使いたい
- AI コーディングツールプラグインを使う場合、ちゃんと該当プラグインで `:XXX Auth` コマンドによって認証する必要がある
  - `:Copilot Auth` を成功させないと、文字を入力するたびに「認証してください」というプロンプトが出て何も入力できない

とくに、`:Copilot(Codium) Auth` をしない限りずっとプロンプトが出てくるのがとてもストレスです。

そのため、個人か会社かをきちんと判定し、その環境にあった AI コーディングプラグインを必ず Auth して利用するにしました。

# 行ったこと

lazy.nvim のプラグイン読み込み時に `vim.env.NEOVIM_GITHUB_COPILOT` で環境変数を取り出しその内容が `1` かどうかで判定するようにしました。
もし 1 であれば NEOVIM_GITHUB_COPILOT が利用できる環境である、としてそちらを使うようにします。

https://github.com/ganyariya/dotfiles/blob/3d3145bd8b9f35c39bb75d262d6493b2da71f7d4/dot_config/nvim/lua/ganyariya/plugins/ai-coding-assistant.lua#L1-L14

```lua
local is_copilot_enabled = vim.env.NEOVIM_GITHUB_COPILOT == "1"

if is_copilot_enabled then
  return {
    "github/copilot.vim",
    lazy = false,
  }
else
  return {
    "Exafunction/codeium.vim",
    event = "BufEnter",
  }
end
```

環境変数 `NEOVIM_GITHUB_COPILOT` 自体は zsh 起動時で設定するようにしています。
`~/.config/zsh/zsh_neovim_github_copilot` が存在し、かつ中身が `1` であれば環境変数を設定するようにしています。
これによって、環境変数によって利用するプラグインを変更できるようになりました。

https://github.com/ganyariya/dotfiles/blob/3d3145bd8b9f35c39bb75d262d6493b2da71f7d4/dot_zprofile#L22-L29
