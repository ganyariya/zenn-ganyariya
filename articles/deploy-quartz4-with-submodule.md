---
title: "[ユースケース] Obsidian Vault と Quartz を分離した状態で Cloudflare Pages にデプロイする"
emoji: "🍣"
type: "tech"
topics: ["obsidian", "quartz", "cloudflarepages", "githubactions"]
published: true
---

# はじめに

https://note.ganyariya.dev/

Obsidian で書いた Markdown について [Quartz](https://quartz.jzhao.xyz/)（静的サイトジェネレータ）を利用して Cloudflare Pages へデプロイしています。

この記事では、1 つのユースケースとして上記の構成についてまとめます。

# 扱うことと扱わないこと

- 扱うこと
  - 今回のユースケースにおける全体構成
  - GitHub Actions の設定
  - submodule の注意点
  - 構成のメリデメ
- 扱わないこと
  - Quartz の概要
  - Obsidian の概要

# この記事を書こうとおもった背景

Obsidian Vault を Quartz でデプロイするにあたって、先駆者の方々の構成を知るためにブログ記事をいろいろと調べました。
しかし、 `Obsidian と Quartz を submodule をつかって分離しながらデプロイする`、という自分にとって丁度よい記事がみつかりませんでした。

そのため、 上記構成の一例としてこの記事を残しています。

# 全体構成

## Obsidian Vault と Quartz を別リポジトリにする

![全体構成](https://storage.googleapis.com/zenn-user-upload/5d0b63b9c312-20250603.png)

異なる 2 つのリポジトリを利用しています。

1. ganyariya-obsidian
   - private repository
   - Obsidian Vault であり Markdown ファイルを管理する
2. ganyariya-obsidian-quartz
   1. public repository
   2. Quartz4 を `clone` or `Use This Template` でもってきたもの
   3. `/content` フォルダに対して `ganyariya-obsidian` を submodule で登録する


![ganyariya-obsidian](https://storage.googleapis.com/zenn-user-upload/bb393cf06af9-20250603.png)
*ganyariya-obsidian*

![ganyariya-obsidian-quartz](https://storage.googleapis.com/zenn-user-upload/6795c4c26bca-20250603.png)
*ganyariya-obsidian-quartz*

https://github.com/ganyariya/ganyariya-obsidian-quartz

ganyariya-obsidian はただの Obsidian Vault であり、 Markdown を普段通り管理するリポジトリです。
Quartz4 のことはできるだけ意識していません。ただし、 YAML frontmatter については意識しており、 `title` `date` などを設定しています。

ganyariya-obsidian-quartz は Quartz4 を `Use This Template` でもってきたものです。
Quartz4 では `/content` フォルダに Markdown を入れることで静的サイトとして生成されます。
そのため、このフォルダに ganyariya-obsidian を submodule として登録しています。

# GitHub Actions の設定

ganyariya-obsidian に新しいノートを push したときに、その変更を自動的に ganyariya-obsidian-quartz へ伝えたいです。
そのため、`repository_dispatch` イベントで ganyariya-obsidian-quartz へ最新化してほしい旨を伝えています。

## PAT の発行

private リポジトリかつ異なるリポジトリへイベントを飛ばすためには Personal Access Token (PAT) が必要です。
ganyariya の場合は `ganyariya-obsidian-(quartz)?` のために共通のトークンを発行しています。

自分の場合は Fine Grained Access Token でトークンを発行しました。
発行したトークンは後続する GitHub Actions ジョブの `secrets.OBSIDIAN_QUARTZ_TOKEN` として登録します。

- Only select repositories
  - ganyariya-obsidian
  - ganyariya-obsidian-quartz
- Contents: Read & Write
- Metadata: Read
- Actions: Read & Write (必要ないかもしれません)

https://note.ganyariya.dev/01_Note/Obsidian-%E3%81%AE%E8%A8%98%E4%BA%8B%E3%82%92%E6%9B%B4%E6%96%B0%E3%81%97%E3%81%9F%E3%81%A8%E3%81%8D%E3%81%AB-Quartz4-%E3%83%AA%E3%83%9D%E3%82%B8%E3%83%88%E3%83%AA%E3%81%AE-submodule-%E3%82%92%E8%87%AA%E5%8B%95%E3%81%A7%E8%87%AA%E5%8B%95%E6%9B%B4%E6%96%B0%E3%81%99%E3%82%8B

## ganyariya-obsidian 側の設定

`workflow_dispatch` (手動トリガー) もしくは main ブランチが更新されたときに発火されます。
発火すると ganyariya-obsidian-quartz に `obsidian-updated` というイベントを飛ばします。

```yaml:dispatch.yaml
name: dispatch-obsidian-updated
on:
  workflow_dispatch:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Dispatch event to ganyariya-obsidian-quartz
        uses: peter-evans/repository-dispatch@v3
        with:
          event-type: obsidian-updated
          token: ${{ secrets.OBSIDIAN_QUARTZ_TOKEN }}
          repository: ganyariya/ganyariya-obsidian-quartz
```

## ganyariya-obsidian-quartz 側の設定

`obsidian-updated` というイベントをどこかのリポジトリ、今回では `ganyariya-obsidian` から受け取ったら発火します。   
やっていることは、もし `/content` remote submodule に変更があったら最新化して main ブランチにコミットするのみです。

https://github.com/ganyariya/ganyariya-obsidian-quartz/blob/4df8729d149852c3131f73772d71c4e4f2ad3de7/.github/workflows/update-submodule.yaml

```yaml:update-submodule.yaml
name: update content submodule
on:
  repository_dispatch:
    types: [obsidian-updated]

jobs:
  update-submodule:
    runs-on: ubuntu-latest
    steps:
      - name: checkout repository
        uses: actions/checkout@v4
        with:
          submodules: recursive
          token: ${{ secrets.OBSIDIAN_QUARTZ_TOKEN }}

      - name: update submodule
        run: |
          git config --global user.name 'github-actions[bot]'
          git config --global user.email 'github-actions[bot]@users.noreply.github.com'

          git submodule update --remote --recursive 
          git add .

          if [ -z "$(git status --porcelain)" ]; then
            echo "No changes detected in submodule."
            exit 0
          fi

          git commit -m "🔄 Update obsidian content submodule"
          git push
```

# Cloudflare Pages における　submodule の注意点

https://quartz.jzhao.xyz/hosting#cloudflare-pages

https://note.ganyariya.dev/01_Note/Quartz4-%E3%81%AE-content-%E3%81%AB-private-submodule-%E3%82%92%E9%85%8D%E7%BD%AE%E3%81%97%E3%81%9F%E7%8A%B6%E6%85%8B%E3%81%A7-Cloudflare-Pages-%E3%81%AB%E3%83%87%E3%83%97%E3%83%AD%E3%82%A4%E3%81%99%E3%82%8B

今回のケースにおいては ganyariya-obsidian-quartz が private リポジトリになっています。
ここで、Cloudflare Pages において、 **private リポジトリを HTTPS 認証で submodule として登録すると clone 時に認証エラーが発生してしまいます。**

https://roboin.io/article/2024/04/25/how-to-use-git-submodules-with-cloudflare-pages/#goog_rewarded

そのため、ろぼいんさんの記事を参考に private リポジトリを SSH 認証で submodule 登録することにしました。
やったことは url 設定を `git@` に書き換えるのみです。

https://github.com/ganyariya/ganyariya-obsidian-quartz/commit/e506bc4e8846fa949181c6c7841a8f1eed6e3cb2

```diff toml: .gitmodules
[submodule "content"]Add commentMore actions
	path = content
-	url = https://github.com/ganyariya/ganyariya-obsidian
+	url = git@github.com:ganyariya/ganyariya-obsidian
```

また、 Cloudflare Pages の GitHub App が private リポジトリへのアクセスできる必要があります。
アクセス権限について確認するには、 [GitHub Installations](https://github.com/settings/installations) の Cloudflare Workers & Pages の設定を確認してください。

![](https://storage.googleapis.com/zenn-user-upload/64e5e1bc29f6-20250603.png)

Cloudflare Workers & Pages GitHub App が該当の private リポジトリへの Read Access をもっていれば問題ありません。

# この構成のメリットとデメリット

- メリット
  - `記事` と `Quartz 設定` を分離できる
    - コミット履歴がそれぞれきれいになる
  - Obsidian Vault が Quartz をできるだけ意識しなくてよい
  - Quartz のバージョンが将来あがったときに受け身がとりやすい
- デメリット
  - リポジトリがわかれるため、切り替えが少し面倒

# まとめ

今回のユースケースでは、 Obsidian と Quartz4 の内容をそれぞれ分離できます。
もしリポジトリを分けたいかたがいらっしゃればご参考ください。
不明点や誤字・不備がありましたらコメントいただければありがたいです。
