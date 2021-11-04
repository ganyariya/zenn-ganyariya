---
title: "Deno で VSCode files.exclude を追加する CLI をつくった"
emoji: "🦕"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["deno", "cli", "vscode"]
published: true
---

# はじめに

https://github.com/ganyariya/vsexclude

VSCode の `files.exclude` を追加する CLI `vsexclude` を Deno で書きました。
<!-- textlint-disable -->
**🦕🦕🦕 新しい言語のテンプレートを追加するなど、たくさんの PR まってます 🦕🦕🦕**
<!-- textlint-enable -->

![](https://storage.googleapis.com/zenn-user-upload/9e6ef199f4454e8539664122.png)

今回は、vsexclude 制作をしたときの気持ちと備忘録です。

# VSCode files.exclude

VSCode の `files.exclude` は、VSCode のサイドバーに表示したくないものを非表示にできる機能です。
以下のように、`.vscode/settings.json` に設定します。
これによって、`venv` などのプログラミング言語が生成するキャッシュファイル、設定ファイルなどを非表示にできます。

```json
{
    "files.exclude": {
        "**/*venv": true,
        "**/*develo-eggs": true,
        "**/*eggs": true,
        "**/*wheels": true
    }
}
```

# gitignore

このような管理したくないファイルを扱う代表例に `gitignore` があります。
git で管理したくないファイルを `.gitignore` ファイルに書くことで、 git から除外します。

下記の CLI は、[`gitignore.io`](https://www.toptal.com/developers/gitignore) から代表的な gitignore ファイルを引っ張ってきます。
https://github.com/aswinkarthik/gitignore.cli#readme

このように、gitignore に関しては代表的な言語の設定例を持ってこられるツールがありますが、
VSCode にはなかったため vsexclude という CLI を作りました。

# 仕組み & 使い方

https://github.com/ganyariya/vsexclude/tree/main/templates

仕組みはとてもシンプルです。
`vsexclude` GitHub の `templates` ディレクトリに、言語ごとの `files.exclude` 設定ファイルを PR で追加します。
あとは `vsexclude add lang` をもちいて、対応する言語のファイルを GitHub 上から引っ張ってきて `settings.json/files.exclude` に追加します。

GitHub 上から対応する言語を引っ張ってくる処理は `fetch` で実装しています。
Client の js っぽく書けるのは便利ですね。

# Deno の環境構築

Deno で毎回行う環境構築があるのでまとめておきます。

## VSCode

VSCode の Deno 拡張機能を使って、以下の設定ファイルを追加します。
`suggest.imports.hosts` を書くことで import 文で補完が効くようになります。

```json
{
    "deno.enable": true,
    "deno.lint": true,
    "deno.unstable": true,
    "deno.suggest.imports.hosts": {
        "https://deno.land": true
    }
}
```

## mod.ts

`index.js` や `index.ts` みたいな認識です。
呼び出しエントリーポイントを mod.ts にまとめます。

自分が CLI をつくるときは、`CLI` の呼び出し処理を `cli.ts` に書いて、肝心の処理は `mod.ts` に書いています。
こうすることで、別ライブラリに対して、純粋な機能のみを `mod.ts` として提供できます。

## deps.ts

`deps.ts` に関係する依存ファイルを以下のように書くことが多いです。
これは、セマンティックバージョニングの管理を一括にまとめたいためです。

```ts
export { Command } from "https://deno.land/x/cliffy@v0.19.6/command/mod.ts";
export * as fs from "https://deno.land/std/fs/mod.ts";
```

最近だと `import-maps` で管理する方法もあるみたいです。

https://dev.classmethod.jp/articles/deno-package/

## denon

タスクランナー & `nodemon` として `denon` を追加します。

https://deno.land/x/denon@2.4.9

`scripts.config.ts` に設定ファイルを書くことでコマンドを実行できます。

https://github.com/ganyariya/vsexclude/blob/main/scripts.config.ts

## テスト

テストは、`tests/` ディレクトリに分けて書いています。
また、テストのファイル名は `original.test.ts` の拡張子で個人的に書いています。

いろんな書き方が Deno はできるため、詳しく調べてみるといいかもです。

## GitHub Actions

Deno 公式で `setupAction` が提供されています。
そのため、`deno test` を GitHub Actions に書くだけでいい感じになります。

https://github.com/ganyariya/vsexclude/blob/main/.github/workflows/test.yaml

# 最後に

<!-- textlint-disable -->
**🦕🦕🦕 新しい言語のテンプレートを追加するなど、たくさんの PR まってます 🦕🦕🦕**
<!-- textlint-enable -->
