---
title: "執筆環境にtextlintを追加して読みやすい文章を書く"
emoji: "📚"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['latex', 'textlint', 'github_actions']
published: false
---

# はじめに

私は、以前 `週論` という取り組みをはじめるという旨の記事を書きました。
この記事では、研究を毎週インクリメンタルに行い論文を書くという取り組みを紹介しています。

https://zenn.dev/ganariya/articles/weekly-paper-trial

今回はこの週論の環境に、 textlint を追加して Github Actions で lint を自動実行できるようにしようと思います。
参考にさせていただいた記事は参考文献として、記事の最後にまとめさせていただきます。

# 週論環境に textlint を追加する

以下のリポジトリに textlint を追加しました。
textlint はテキストファイルや Markdown の Lint を行うツールです。
ルールやプラグインを npm から自由に追加できます。

https://github.com/tsukuba-mas/weekly_report

はじめに、必要なモジュールを npm で追加します。
これは `npm install --save-dev below-packages` によってインストールできます。
`textlint-plugin-latex2d` は textlint に $\LaTeX$を対応させるためのプラグインです。
また、 `prh` は表記揺れを検出し、自動で修正するための外部ライブラリです。
そのため、 `textlint-rule-prh` が prh と textlint のインターフェースになっています。

```json
  "devDependencies": {
    "prh": "^5.4.4",
    "textlint": "^11.9.0",
    "textlint-filter-rule-comments": "^1.2.2",
    "textlint-plugin-latex2e": "^1.1.0",
    "textlint-rule-preset-ja-engineering-paper": "^1.0.2",
    "textlint-rule-preset-ja-spacing": "^2.0.2",
    "textlint-rule-preset-ja-technical-writing": "^4.0.1",
    "textlint-rule-preset-jtf-style": "^2.3.8",
    "textlint-rule-prh": "^5.3.0",
    "textlint-rule-spellcheck-tech-word": "^5.0.0"
  }
```

しかし、これだけでは lint を行えません。
`.textlintrc` という設定ファイルを設定する必要があります。

以下の .textlintrc では、プラグインやルールにおいて細かい設定を行えます。
weekly-report は論文執筆環境であるため、ピリオドやカンマなどに関する追加設定を行っています。
`prh` は自分用の yaml ファイルを作成するのがよいかと思います。

```json
{
    "plugins": [
        "latex2e"
    ],
    "rules": {
        "preset-ja-spacing": true,
        "preset-ja-technical-writing": {
            "ja-no-mixed-period": {
                "periodMark": "．",
            },
            "max-kanji-continuous-len": false,
            "sentence-length": 100,
        },
        "preset-ja-engineering-paper": true,
        "preset-jtf-style": {
            "1.2.1.句点(。)と読点(、)": false,
            "1.2.2.ピリオド(.)とカンマ(,)": false,
            "4.1.3.ピリオド(.)、カンマ(,)": false
        },
        "prh": {
            "rulePaths": [
                "node_modules/prh/prh-rules/media/WEB+DB_PRESS.yml"
            ]
        },
    },
    "filters": {
        "comments": {
            "enablingComment": "textlint-enable",
            "disablingComment": "textlint-disable"
        }
    }
}
```

あとは `npx textlint main.tex **/**.tex` のコマンドを実行すると、 .textlintrc を自動で読み込んで間違っている箇所を表示してくれます。

しかし、このコマンドを毎回打つのは面倒であるため、 Makefile を作りました。
`make lint` を実行すると、自動で lint がかかります。

```makefile
MAIN_TEX = main.tex

compile:
	latexmk $(MAIN_TEX)
	rm **/__latexindent_temp.tex
	rm __latexindent_temp.te

.PHONY: install
install:
	npm install
	npm audit fix

.PHONY: lint
lint:
	npx textlint $(MAIN_TEX) **/**.tex

.PHONY: fix-lint
fix-lint:
	npx textlint $(MAIN_TEX) **/**.tex --fix
```

あとは GitHub Actions を追加して、プルリクエストを出したタイミングで lint のチェックが行われるようにします。
こちらの yaml ファイルは以下の記事を参考にさせていただきました。

https://zenn.dev/yuta28/articles/blog-lint-ci-reviewdog

```yaml
name: reviewdog

on:
  pull_request:
    branches:
      - main

jobs:
  reviewdog-check:
    name: reviewdog (check)
    runs-on: ubuntu-latest
    steps:
      - name: Set up reviewdog
        uses: reviewdog/action-setup@v1
        with:
          reviewdog_version: latest
      - name: Set up node
        uses: actions/setup-node@v2
      - name: Checkout
        uses: actions/checkout@v2
      - name: Cache
        uses: pat-s/always-upload-cache@v2.1.3
        env:
          cache-name: cache-node-modules
        with:
          path: ~/.npm
          key: node-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            node-
      - name: install dependencies
        run: |
          npm install
      - name: Execute textlint
        run: |
          npx textlint -f checkstyle main.tex components/**.tex >> .textlint.log
      - name: Run reviewdog
        if: failure()
        env:
          REVIEWDOG_GITHUB_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          cat .textlint.log | reviewdog -f=checkstyle -name="textlint" -reporter="github-pr-review"
      - name: Slack Notification
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_USERNAME: weekly-textlint
          SLACK_ICON_EMOJI: ":bell:"
```

# Zennの執筆環境に lint を追加する

同様に Zenn の執筆環境にも lint ならびに GitHub Actions を追加しました。
詳細は以下のリポジトリを参考ください。

https://github.com/Ganariya/zenn-ganariya

しかし、とある問題が発生しました。
これまで私は textlint を入れておらず、新しく textlint を追加した結果、過去の記事で大量に修正箇所が出るようになりました。
加えて、`zenn-ganariya` リポジトリには main ブランチの protection rule を設定しており、 textlint(ReviewDog) が通らないと main にマージすることができません。

その結果、新しく記事を書いてプルリクエストを出したとしても、過去の記事で lint error が出てマージすることができなくなりました。



