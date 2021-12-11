---
title: "deno + aleph.js で OBS 上に glitch-text を表示するためのサイトをつくった"
emoji: "🎉"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["deno", "aleph", "OBS", "react"]
published: false
---

# Advent

この記事は Deno Advent Calendar の 14 日目の記事です。

https://qiita.com/advent-calendar/2021/deno

# はじめに

タイトルのとおり deno + aleph.js で以下のような開発をしました。

- glitch text を計算する React Custom Hooks を作る
- OBS 上で glitch text を表示するためのサイトを上記の hooks を使ってつくる

作成した React Hooks は以下の GitHub です。

https://github.com/ganyariya/text_glitch

![Text Glitch](https://i.gyazo.com/0bf223e7108e46101d5114348b296b28.gif)

また、 OBS 上でテキストを表示するためのサイトは以下です。

https://obs-text-glitch.vercel.app/

上記サイトを OBS のブラウザで読み込んで、クロマキーフィルタをかけると以下のように配信できます。
かわいい & かっこいいですね。
これでオンライン会議などで一目置かれる存在になれること間違いなしです（画面がうるさいので）。

![](https://storage.googleapis.com/zenn-user-upload/059a01420e30-20211211.gif)


