---
title: "CLI を作る中でわかった deno のうれしさ"
emoji: "✨"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["deno", "CLI"]
published: false
---

# はじめに

![](https://i.gyazo.com/c44129cb91063209007873b808e0b0c3.gif)

https://github.com/ganyariya/derain

deno のアイコンである恐竜が雨に打たれるだけの CLI `derain` を作りました。
上記の GitHub リンクからお手軽に試せます。

色々と参考にさせていただいたのは、以下の記事です（感謝でいっぱいです...）。

https://zenn.dev/kawarimidoll/articles/5559a185156bf4

この記事では、CLI をつくるなかでわかった deno のうれしさについて書こうと思います。

## 背景

Node.js は 3 年前、TypeScript は半年前ほどから触っています。
ただ、これまでは競技プログラミングやゲーム開発などをメインに行っていたため、あまり Node.js / TypeScript の経験はありません。

# Deno のうれしさ

## デフォルトで TypeScript が動く

もっともうれしいと感じたのは、この点かなと思います。

Node.js で TypeScript を動かすにはいろいろと入れなければいけません。
何も入れなくてもデフォルトで TypeScript が動くことにただただ感動しました...。
キャンプ場にキャンプ一式が用意されているぐらい嬉しいですね（伝わるかな）。

## 非同期処理が書きやすい

Node.js は 2009 年に作られたものです。
`Promise` ではなく `callback` が設計当時に採用されました。
そのため、歴史とともに少しずつ非同期処理が書きやすくなってきたものの、その負債が垣間見えてしまいます。

deno では、この非同期処理を Promise async await でキレイにかけます。
とくに、トップレベルで await が動くのも便利で嬉しいですね。

以下のコードは Node.js では動きません。
一度、 async の関数でラップする必要があります。

```ts
const neko = await nyann();
```

## ファイルがいい感じに実行できる

以下のコマンド 2 つは、GitHub 上においてあるファイルを直接ローカルにダウンロードして実行できます。
また、依存するファイルを自動で依存関係を解決してダウンロードしてくれます。

```shell
deno install --allow-run --force --name derain https://github.com/ganyariya/derain/raw/v1.0.3/cli.ts
deno run --allow-run https://github.com/ganyariya/derain/raw/v1.0.3/example/rainded_deno.ts
```

Go と同じように直接 URL を指定するため、このようなシンプルな実行が可能になっているだと思います。
ローカルだけでなくリモートも気軽に実行できるのがとてもうれしいですね。

```ts
import { sleep } from "https://deno.land/x/sleep/mod.ts";
import { Command } from "https://deno.land/x/cliffy@v0.19.2/command/mod.ts";
```

## deno とともに

ganyariya の個人的嗜好として、まだコミュニティが大きくないものを好きだったりします。
たとえば、日本では惜しくもあまりメジャーでない Nim も好きで、たまに競技プログラミングで使っています（初心者です）。

deno も 2018 に発表され、非常に新しくこれからもっと大きくなっていくのだと思います。
新参者ですが、deno を見守って自分も OSS Contribute できればと思います。

## deno の恐竜がかわいい

かわいいだけでやる気が出ます。
ganyariya は思った以上に単純でした。

![](https://camo.githubusercontent.com/9e2f7b04a40d3613e2398cae66d73e953d73a4a3800bfc66d7b04ab869c0eda4/68747470733a2f2f64656e6f6c69622e6769746875622e696f2f686967682d7265732d64656e6f2d6c6f676f2f64656e6f5f68725f636972636c652e706e67)

# さいごに

まだまだ deno 初心者ですが、少しずつ deno と仲良くなって OSS 開発していきたいです。
