---
title: "LaTeXでgit更新の差分をPDFにする"
emoji: "😊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["latex", "git"]
published: true
---

# はじめに

$\LaTeX$ の原稿を修正したときに，修正内容の差分を分かりやすく PDF にして確認したい場合があります。
とくに、先生に原稿をチェックしていただくときに、差分が直感的に分かりやすいようにしたいです。

このような原稿の差分をチェックする$\LaTeX$のコマンドに `latexdiff` ならびに `latexdiff-vc` があります。

`latexdiff-vc` は `latexdiff` コマンドをオーバーラップしたものになります。
差分を分かりやすく表示する `latexdiff` コマンドに対して、 git などのバージョン管理と連携させるのが `latexdiff-vc` コマンドとなります。

このご時世、$\LaTeX$を書くときは基本的に git などのバージョン管理システムを利用していると思われるため、 `latexdiff-vc` を利用することにします。

# latexdiff-vc

latexdiff-vc は `Tex Live` を導入するとデフォルトで入っているコマンドです。

以下のように使うことができます。

```bash
latexdiff-vc -e utf8 --git --flatten --force -r 286bfd7 main.tex
```

特徴的なオプションとして、`--flatten`があります。
`input{}`などを利用して $\TeX$ファイルを分割して書いている場合は、 flatten を指定する必要があります。

`-r` は修正前の過去のコミット ID を指定します。
ブランチ名なども指定可能です。

このようにコマンドを打つと、 `main-diff286bfd7.tex` ファイルが生成されます。
あとは、このファイルを pdf にすれば差分が青と赤で表示されます。

[![Image from Gyazo](https://i.gyazo.com/5ee18db930ae87ea2c9c69576e571465.png)](https://gyazo.com/5ee18db930ae87ea2c9c69576e571465)
