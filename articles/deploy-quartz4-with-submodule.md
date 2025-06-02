---
title: "[ユースケース] Obsidian Vault と Quartz を分離した状態で Cloudflare Pages にデプロイする"
emoji: "🍣"
type: "tech"
topics: ["obsidian", "quartz", "cloudflarepages", "githubactions"]
published: true
---

# はじめに

https://note.ganyariya.dev/

https://quartz.jzhao.xyz/

Obsidian で書いた Markdown を [Quartz](https://quartz.jzhao.xyz/) （静的サイトジェネレータ）で Cloudflare Pages へデプロイしています。

この記事では 1 つのユースケースとして、上記の構成についてまとめます。

# 扱うことと扱わないこと

- 扱うこと
  - 今回のユースケースにおける全体構成
  - GitHub Actions の設定
- 扱わないこと
  - Quartz の概要
  - Obsidian の概要

# この記事を書こうとおもった背景

Obsidian Vault を Quartz でデプロイするにあたって、ブログ記事をいろいろと調べました。
しかし、 Obsidian と Quartz を submodule をつかって分離しながらデプロイする、という自分にとって丁度よい記事がみつかりませんでした。

そのため、 Obsidian と Quartz を submodule をつかって分離する一例としてこの記事を残しています。

# 全体構成

## Obsidian Vault と Quartz を別リポジトリにする

# GitHub Actions の設定

# この構成のメリットとデメリット

# まとめ
