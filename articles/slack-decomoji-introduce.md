---
title: "Slackにデコモジを導入する"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['slack', 'emoji']
published: true
---

# はじめに

ganariya が所属する研究室では、コミュニケーションツールとして Slack を利用しています。
ただし、主に学生間の利用であり、指導教員との連絡についてはメールを利用しています。

しかし、個人的に Slack のコミュニケーションがあまり活発ではないように感じています（体感）。
このコロナ下というほぼリモートワーク状態においては、もっと意識的にコミュニケーション量を増やしていきたいです。

そのため、以下のデコモジを導入します。
とはいっても README 通りに行うのみです。

https://github.com/decomoji/decomoji

# 導入

以下のコマンドを実行します。

```bash
git clone https://github.com/decomoji/decomoji.git
cd decomoji
npm ci
node scripts/manager
```

`npm ci`は package-lock.json から高速にインストールを行うサブコマンドです。（始めてみました）

`node scripts/manager`を実行すると CLI が起動するため、言われたとおりに入力します。
`? ワークスペースのサブドメインを入力してください`では、Slack の `xxx.slack.com` の `xxx` の部分のみを打ち込めばいいです。

