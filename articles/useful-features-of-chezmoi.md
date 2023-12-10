---
title: "chezmoi で dotfiles を管理するときに便利な機能についてまとめる"
emoji: "🙌"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["dotfiles", "chezmoi"]
published: true
---

# はじめに

これまで ganyariya は自分流のシェルスクリプトで dotfiles を運用していました。
しかし、設定ファイルを継ぎ足しで修正していった結果、使用していない設定も増えて汚れた状態になってしまいました。

https://qiita.com/ganyariya/items/d9adffc6535dfca6784b
https://github.com/ganyariya/dotfiles_old

そのため、 dotfiles を `chezmoi` という dotfiles 管理ツールを利用して、ゼロから作り直すことにしました。
この記事では dotfiles を chezmoi をもちいて置き換えるうえで、便利だなと思った機能についてまとめます。

## できあがった dotfiles

https://github.com/ganyariya/dotfiles

debian image における chezmoi apply の実行です。
apt でインストールできる neovim が古く build で実行ファイルを作成しており時間がかかっています。
しかし neovim 以外は 1 分程度でセットアップが完了しており、 今後のクラウド linux vm でも活用できそうです。

[![asciicast](https://asciinema.org/a/NNVJbxIzed74mtGt3UXJ1UZpc.svg)](https://asciinema.org/a/NNVJbxIzed74mtGt3UXJ1UZpc)

## この記事で取り扱う・取り扱わないこと

chezmoi の概要や chezmoi の基本構成などについては書きません。
公式サイトや以下の記事を参考にしてください。

https://www.chezmoi.io/

https://zenn.dev/johnmanjiro13/articles/d14825f4ef3184

https://zenn.dev/ryo_kawamata/articles/introduce-chezmoi

https://www.mizdra.net/entry/2022/02/22/022109

https://deflis.hatenablog.com/entry/hatena-advent-calendar-2022-chezmoi-dotfiles

かわりに chezmoi で dotfiles を取り扱ううえでこの機能便利だなと思った、検索しづらい・見つけづらい機能についてまとめようと思います。

# .chezmoiignore

https://www.chezmoi.io/reference/special-files-and-directories/chezmoiignore/

chezmoi で管理したくないファイルやディレクトリを指定できます。

自分の場合 `.config/tmux/tmux.conf` 以外は chezmoi で管理しない設定をしています。
これによって `chezmoi add .config/tmux` を実行しても `tmux.conf` のみ dotfiles ディレクトリで変更が追跡されます。

```bash
# tmux
.config/tmux/*
!.config/tmux/tmux.conf
```

# .chezmoiexternal.toml

https://www.chezmoi.io/reference/special-files-and-directories/chezmoiexternal-format/

dotfiles 管理外である、外部リポジトリや外部パッケージを自動的に引っ張ってこれます。
つまり、 `chezmoi apply` を実行したときに外部リポジトリなどを chezmoi が勝手にダウンロードして適切なパスに置いてくれます。

自分の場合は以下 2 つを現在 chezmoiexternal で管理しています。

- tmux のプラグインマネージャである tpm 
- neovim のフレームワークである AstroNvim

たとえば nvim の場合、 `.config/nvim` パスに depth=1 かつ main ブランチの AstroNvim リポジトリを持ってこれます。

```toml
[".tmux/plugins/tpm"]
type = "archive"
url = "https://github.com/tmux-plugins/tpm/archive/master.tar.gz"
exact = true
stripComponents = 1
refreshPeriod = "168h"

[".config/nvim"]
type = "git-repo"
url = "https://github.com/AstroNvim/AstroNvim"
refreshPeriod = "24h"
clone.args = ["--depth", "1", "-b", "main"]
```

`ganyariya/dotfiles` で直接 AstroNvim のリポジトリを submodule として管理するということも考えました。
(`ganyariya/dotfiles/dot_config/nvim` に submodule として登録する)

しかし、 dotfiles リポジトリで chezmoi apply を実行すると、 submodule に含まれる `.` 拡張子が sync されませんでした。
つまり、 AstroNvim リポジトリ内の `.` から始まるファイルが sync されず、 `~/.config/nvim` に含まれませんでした。

そのため chezmoi で外部リポジトリや外部パッケージを扱う際は `.chezmoiexternal.toml` を利用したほうが良いかなと思います。

# ユーザスクリプト

dotfiles で実現したい機能として以下 2 種類があると思います。

1. `.zshrc` や `.gitconfig` などの設定ファイルを他環境でも手軽に利用する
2. `ripgrep` や `curl` `tmux` など、自分が利用するコマンド・パッケージを用意する（環境構築）

1 の設定ファイルを他環境でも手軽に利用するについては、 `chezmoi add .zshrc` などをすれば自動的に配置されるため工夫がいりません。
しかし、`ripgrep` `curl` など自分が利用したいコマンド・パッケージの環境構築は自動では行えません。
なにかしらのパッケージマネージャを利用して、これら依存パッケージをインストールする必要があります。

chezmoi ではこの「依存パッケージの自動インストール」の実現方法として、 `User Script`（ユーザスクリプト）があります。

https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/

https://github.com/ganyariya/dotfiles/tree/main/startup/mac

chezmoi では `dotfiles` リポジトリにおける任意のディレクトリにおいて `run_once_` から始まるテキストファイルを `ユーザスクリプト` として認識します。
そして、 `chezmoi apply --init` 時にそれらユーザスクリプトを自動的に実行し、「実行したこと」も state として保存します。
そのため、 環境構築のために一度だけパッケージをインストールできます。

たとえば自分の場合、 Mac HomeBrew によるコマンドのインストールをユーザスクリプトで実現しています。
`chezmoi apply` を実行すれば自動的に `.Brewfile` を読み込んで ripgrep tmux などをよしなに導入してくれます。

https://github.com/ganyariya/dotfiles/blob/f2c49ce8f0492e5ef455745190feff173bc8dd11/startup/mac/run_once_01_install_brew.sh.tmpl#L1-L9

# ユーザスクリプトの配置

ユーザスクリプトの配置について自分の場合、完全に OS (Distribution) ごとにセットアップスクリプトを分岐することにしました。

これは 1 つのユーザスクリプトのなかで、 mac, linux, windows の環境を構築するのはしんどいためです。
また、 OS (Distribution) ごとに設定したい項目も異なるため完全に分離しています。

各環境で利用したいスクリプトを分けるために `.tmpl` を利用しており、 一致する OS の場合のみユーザスクリプトを実行するようにしています。
以下の場合 mac (darwin) のみで実行され、 debian ではスキップされます。

```bash
#!/bin/bash

{{ if eq .chezmoi.os "darwin" }}

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew bundle --file="$HOME/.Brewfile"

{{ end }}
```

tmpl については以下を参照ください。
https://www.chezmoi.io/user-guide/templating/#creating-a-template-file

# ユーザスクリプトの実行順序

ユーザスクリプトは辞書順で実行されるそうです。
そのため、実行したいユーザスクリプト順で 01, 02, 03 と prefix をつけるようにしています。

![](https://storage.googleapis.com/zenn-user-upload/283bcb2d96e1-20231210.png)

# 最後に

chezmoi を導入することによって、ワンライナーで環境を構築できるようになりました。
（mac ではまだ試せていませんがおそらくできるはず...）

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/bin init --apply ganyariya

apt update && \
  apt install -y curl git zsh && \
  chsh -s /usr/bin/zsh && \
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/bin init --apply ganyariya
```

chezmoi によってより気楽に dotfiles が運用でき環境差分を吸収できるようになったため、便利コマンドや alias をどんどん設定していこうと思います。
