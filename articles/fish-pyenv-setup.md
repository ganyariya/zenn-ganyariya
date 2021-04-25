---
title: "Mac+fishでpyenvのpathを通す"
emoji: "📌"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['fish', 'pyenv', 'python']
published: false
---

# はじめに

この前、ひさしぶりに macbook pro をクリーンインストールしました。
しかし、 pyenv の環境がうまく動作せず mac の system 自体に入っている python2 が動作する状態に陥りました。

それの解消法について備忘録としてまとめます。

## 環境

- mac big sur
- fish

brew で pyenv をインストールしています。

# 対処法

`.config/fish/config.fish` に環境変数が通っていないことが原因でした。
fish シェルは、シェルが立ち上がると `config.fish` が読み込まれます。
そのため、 `config.fish` に set コマンドを書いて変数を登録すればよいです。

以下を config.fish に追加します。

```bash
set -x PYENV_ROOT $HOME/.pyenv
set -x PATH  $PYENV_ROOT/bin $PATH
pyenv init - | source
```

`set -x` コマンドで `~/.pyenv` を PATH に追加します。
`-x` オプションは、環境変数として登録するものです。（これがついていないと、 fish シェルから fork されたプロセスに変数が引き継がれないはずです。）

`pyenv init -` は、 `.pyenv/.shims`を PATH に追加して、 global や local の pyenv でインストールされたパッケージを登録しているようです。
そのため、これがないと動作しません。
そして、その内容を source コマンドで実行しています。
なぜならば、 `pyenv init -` は文字列を返すコマンドであるためです。

https://akamist.com/blog/archives/2610

