---
title: "競技プログラミングの環境を VSCode devcontainer で作成する"
emoji: "🌊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["devcontainer", "競技プログラミング", "vscode"]
published: true
---

# はじめに

最近は競技プログラミングよりも開発ならびに枯れた技術の勉強に熱心な ganyariya です。

これまで競技プログラミングを行うときは ganyariya の macbook 上で直接実行していました。
その結果、 macbook をクリーニインストールしたり macbook air (m1) へ移行するたびに、 gcc や clang などの設定を調べながら行う必要がありました。
(dotfiles は用意していますが、 gcc のパス設定などは自動化していない)

今後もなにか別の macbook へ移行するたびに gcc のパス設定などを行うのは面倒です。
そのため、 VSCode の devcontainer を利用することで、どの OS でも同じ競技プログラミングの環境を用意しようと思います。

devcontainer を設定したリポジトリ
https://github.com/ganyariya/competitive

# 前提

## 用語

ganayriya の macbook air pc 自体を `ローカル or ホスト` と呼ぶことにします。
Docker 上で起動される devcontainer  コンテナを `リモート or コンテナ` と呼ぶことにします。

## 機能

現在用意している言語は自分が利用している go c++ python です。

devcontainer コンテナ上で実行できる操作は以下のとおりです。

- `Code Runner` 拡張機能をもちいて `Ctrl + Option + N` でファイル実行できる

![](https://camo.githubusercontent.com/cfaf62116b9cd14d20a9e6847a727880cb1e6ac2e070d3f7e3ea16df3e543c81/68747470733a2f2f692e6779617a6f2e636f6d2f36333064306332653561376337363462373337373734666166636432626539342e676966)

- Debugger を起動して Breakpoint を設定してデバッグできる

![](https://camo.githubusercontent.com/19a500c112a6e91ce707733c4e050c4da721f07cc9a49f566300a8002f89dd90/68747470733a2f2f692e6779617a6f2e636f6d2f38353532353465303761643161373630383631386264663666623166363236642e676966)

# devcontainer

devcontainer については以下が参考になります。

https://code.visualstudio.com/docs/devcontainers/containers

https://zenn.dev/bells17/articles/remote-ssh-devcontainer

この記事では具体的な設定のみ説明します。


## devcontainer.json

https://github.com/ganyariya/competitive/blob/main/.devcontainer/devcontainer.json

`dockerfile: Dockerfile` と指定することによって、 `.devcontainer/Dockerfile` をビルドしコンテナとして起動します。

`features` は公式が提供している自己完結型ユニットです。
難しい表現がされていますが、go と python が実行できる環境を追加でインストールしています。
(c++ 自体は Dockerfile で指定している `base:jammy` に gcc がすでに含まれています。)

> Development container "Features" are self-contained, shareable units of installation code and dev container configuration. The name comes from the idea that referencing one of them allows you to quickly and easily add more tooling, runtime, or library "Features" into your development container for use by you or your collaborators.

`customizations.vscode.extensions` でコンテナを起動した際に、追加でインストールされる vscode extension を指定しています。

## Dockerfile

https://github.com/ganyariya/competitive/blob/main/.devcontainer/Dockerfile

`base:jammy` に `gdb` をインストールしているだけです。
c++ のデバッグ用に gdb が必要です。

# タスク・デバッグの設定

devcontainer の設定はこれだけです（簡単ですね）。
しかし、デバッグなどを行うために設定すべき内容が多いので、これらもあわせてまとめておきます。


## c_cpp_properties.json

https://github.com/ganyariya/competitive/blob/main/.vscode/c_cpp_properties.json

https://code.visualstudio.com/docs/cpp/c-cpp-properties-schema-reference

VSCode の `C/C++` 拡張機能が利用する Intellisense 用の設定ファイルです。
AtCoder が c++17 を利用できるので、 c++17 を指定しています。

## tasks.json

https://github.com/ganyariya/competitive/blob/main/.vscode/tasks.json

c++ で**デバッグ**するために、デバッグ情報を含んだバイナリ `main` をビルドするタスクです。

通常、ファイルの実行自体は `main.cpp` を開いた状態で `Ctrl + Option + N` で Code Runner を利用しています。

一方で、デバッグしたい際は上記の `tasks.json` の `GCC Build` タスクを、後述する `launch.json` から呼び出しています。
つまり、自分で `GCC Build` を直接呼び出すことはなく、普段の実行はあくまでも Code Runner を利用しています。

`args` で `-g`, `-O0` を指定することによって、デバッガに必要な情報を含めています。

## launch.json

https://github.com/ganyariya/competitive/blob/main/.vscode/launch.json

c++, go, python をデバッグするためのファイルです。

c++ においては `preLaunchTask` で `GCC Build` タスクを先に実行しています。
これによって、デバッグ情報を含むバイナリを先に吐き出しておけます。
このバイナリに対して gdb を実行します。

gdb を使うこと自体は `type: cppgdb` で指定しています。

## settings.json

https://github.com/ganyariya/competitive/blob/main/.vscode/settings.json

Code Runner で実行するコマンドを設定しています。
<!-- textlint-disable -->
たとえば、 c++ の場合は `"cd $dir && g++ -std=c++17 -I . -g $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt"` が `Ctrl + Option + N` で実行されます。
<!-- textlint-enable -->

また、 `files.exclude` でサイドバーに表示したくない内容を記載しています。
c++ でビルドしたバイナリは `main` という名前で吐かれており、これをサイドバーに表示したくないのでこの設定にしています。

## cpp/.clang-format

https://github.com/ganyariya/competitive/blob/main/cpp/.clang-format

c++ の format を指定しています。
`C/C++` 拡張機能に含まれている `clang-format` が `.clang-format` を読み込んでいい感じにフォーマットしてくれます。

長いものには巻かれていたいので、 Google を指定しています。
（`競プロer` に多い、横に長く書くスタイル指定だった気がします。）

# 最後に

devcontainer を設定することで、他の OS ならびに環境でもより楽に環境構築できるようになりました。
メモリや CPU を多く消費するという欠点はありますが、非常に便利なので個人開発でもどんどん使っていきたいですね。

ここまで書いてみると c++ に関する設定が多くて大変ですね。
やはり go のように公式がいいかんじにすべてをサポートしてくれる言語がいいですね...。

