---
title: "Deno + Aleph.js で OBS 上に Glitch Text を表示するためのライブラリとサイトをつくった"
emoji: "🦕"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["deno", "aleph", "OBS", "react"]
published: true
---

# Advent

この記事は Deno Advent Calendar の 14 日目の記事です。

https://qiita.com/advent-calendar/2021/deno

# はじめに

Advent Calender 用に、 Deno + aleph.js で以下のような開発をしました。

- Glitch Text を計算する React Custom Hooks を作る
- OBS 上で Glitch Text を表示するためのサイトを上記の hooks を使ってつくる

作成した React Hooks は以下の GitHub です。

https://github.com/ganyariya/text_glitch

![Text Glitch](https://i.gyazo.com/0bf223e7108e46101d5114348b296b28.gif)

また、 OBS 上でテキストを表示するためのサイトは以下です。

https://obs-text-glitch.vercel.app/

上記サイトを OBS のブラウザで読み込んで、クロマキーフィルタをかけると以下のように配信できます。
かわいい & かっこいいですね。
これでオンライン会議などで一目置かれる存在になれること間違いなしです（画面がうるさいので）。

![](https://storage.googleapis.com/zenn-user-upload/059a01420e30-20211211.gif)

# Text Glitch Lib

https://github.com/ganyariya/text_glitch

Text Glitch Library は Deno + Aleph.js + React で構成されていますが、
**実体はただの React Component (Custom Hook)** です。
かつ `tsx` がそのまま使われています。（つまり、 tsx のまま利用できます。）

というのも、普通の Node.js の React Library では、 js / jsx に Babel などでトランスコンパイルして npm で公開する必要があります。
eslint や prettier, webpack, babel など多くの設定が必要です。

一方、 Deno では、 node.js のように node_modules をプロジェクトごとに利用するということはしません。
Deno ランタイムを実行するときに、依存するスクリプトをすべてダウンロード・解決し実行します。
このとき、 Deno は TypeScript を直接解決してくれるためいちいち JavaScript にコンパイルしておく必要がありません。

## React & Aleph.js

Deno では、直接 `jsx`, `tsx` 拡張子を利用できます。
ソースコード内で、 React, ReactDOM のファイルを import すれば、 renderToString で React Component をサーバーサイドレンダリングできます。
便利です。

https://deno.com/deploy/docs/using-jsx

https://deno-ja.vercel.app/manual@v1.8.3/typescript/overview

https://hashrock.hatenablog.com/entry/2019/10/09/235615

ただ、実際に React を直接設定するのは大変なので、 Deno における Next.js の立ち位置である Aleph.js を使うと良いです。
あとはこの Aleph.js プロジェクトで直接 Text Glitch の tsx Custom Hooks を import すれば、面倒なコンパイルの必要なくコンポーネントを利用できます。

https://alephjs.org/

## 問題点

当然ですが、 Aleph.js などの Deno からの利用を前提としているので Node.js から Text Glitch は使えません。
まだまだ Node.js ランタイムのシェアのほうが大きいですし、いろんな環境を想定するとあらかじめトランスコンパイルするほうが親切ですね。
Node.js 向けにコンパイルする方法を調べて npm パッケージを作る練習もしてみたいです。

# OBS

![](https://storage.googleapis.com/zenn-user-upload/059a01420e30-20211211.gif)

今回本当にやりたかったのは、上記のように OBS 上でチカチカしているテキストを作ることでした。
（そのため、最初はなにか既存のテキストライブラリを使って作ろうとしてました。）

OBS で `ブラウザ` アイテムを作成し、以下の URL を指定しクロマキーで抜くとテキストを表示できます。
ご興味ある人は使ってみてください。


# 最後に

Advent 用にあたふた作ってたので、だいぶとっちらかってしまっていますね...（ごめんなさい）。

しかし、 React / React Custom Hooks の理解が進んだり、 Aleph.js を触れたので良い経験だったかなと思います。

# 謝辞

<!-- textlint-disable -->

以下のライブラリを非常に参考にさせていただきました。
ありがとうございました！

https://github.com/crazko/use-dencrypt-effect