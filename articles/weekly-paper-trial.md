---
title: "【志】論文を毎週書く「週論」を始めます"
emoji: "✨"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ["論文", "研究", "TeX", "GitHubActions", "agile"]
published: true
---

# はじめに

## 対象読者

- 研究がなかなかうまくいかない学生さん（僕）

## この記事で目指すこと

- 毎週論文をインクリメンタルに書く
  - 実験や考察の不足を早い段階で明らかにする
  - 全体像を固める
  - 「推敲」の練習を積む
- GitHub Actions で週論を自動化する

## きっかけ

先日，大学のアジャイルワークショップに参加しました．
このワークショップでは，指導教員と学生が参加することによって，カオスである研究にアジャイル・スクラムを取り入れようというものでした（おそらく）．
内容は，アジャイル動物園の動物になりきって，プロジェクトに対する利害関係を経験してみようというものでした．
ここで得た一番の経験は以下のことです．

> 人間は誰しも「ブタ」であり「カモメ」であり，「ニワトリ」なのです．環境がそうさせるのです．

https://www.ryuzee.com/contents/blog/4215

ワークショップ終了後，今回の先生である[@kiro](https://twitter.com/haradakiro)さん，そして大学の先生・学生のみなさんで「研究とアジャイル」について話す場がありました．

このとき，kiro さんにアドバイスを以下のようにいただきました．

> 2週間ごとに論文や動作物などのMVPをステークホルダーに提示するのは良さそう

ここにおけるステークホルダーは自分ならびに指導教員，共同研究者です．
かなり意識は遠いですが，研究室のメンバーも相当します．
彼らステークホルダーに読んでもらえるように論文や動作物を `2週間という短いスパン` で，
`見える・動く形`で提示することを目指します．

このアプローチは，以下のようなメリットが考えられます．

- かなり早い段階で研究の全体像が見える
- 書くことによって，今の研究に不足していることがわかる
  - 実験設定
  - 関連研究
  - etc...
- 推敲する力がつく
- 「形になるもの」が完成するため，先生も自分も安心する・確認できる

アジャイルはおもにチームがカオスな課題に解決するために存在し，なかなか個人志向の研究には難しいところです．
それでも，この「1・2 週間のスプリントで成果物を生み出す」アプローチをぜひ研究に取り入れてみたいなと思いました．

# 仕組みづくり

1・2 週間のスプリントで研究を行うことは非常に難しいです．
これは以下の理由が考えられます．

- 新しいことを行うのが研究であり，タスクが細かいバックログに切りづらい
  - かなり大きな粒度になり，かつ工数ポイントが読みづらい
  - そもそも不確定要素が大きく切れない
- ステークホルダーが基本的に自分と指導教員だけなので，自分がカモメになる瞬間が高い
- 複数人だからこそ開発は続く，個人だと途中でダレる

そこで，毎週論文をインクリメンタルに書くために GitHub Actions で実現することにしました．
システムの力を外部から自分に与えることによって，強制的に論文を書くようにしようと思います．

## リポジトリ

GitHub Actions（論文リポジトリ）は以下のリポジトリ `weekly_report` です．
このリポジトリを Clone もしくは Import することによって，毎週論文を書く「週論」をおそらく実現できます．

https://github.com/tsukuba-mas/weekly_report

機能は以下の通りです．

- TeX ファイルをコンパイルして Release -> Asset にする
  - タグプッシュ時
  - 毎週の指定時間（変更可能）
- Slack への通知


## GitHub Actions

`weekly.yml`

```yaml
on:
  schedule:
    # Friday 11:30(JST)
    - cron: "30 2 * * 5"

jobs:
  ComPile_PDF_With_Tags:
    runs-on: ubuntu-latest
    name: Compile PDF with Tags
    steps:
      - name: Get Current Time
        uses: 1466587594/get-current-time@v2
        id: current_time
        with:
          format: "YYYY/MM/DD-HH/mm/ss"
          utcOffset: "+09:00"
      - name: Set up Git repository
        uses: actions/checkout@v2
      - name: Compile Tex File
        id: compile_tex_file
        uses: tsukuba-mas/platex-action@main
        with:
          LATEX_FILE_NAME: "main.tex"
      - name: Create Release
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
        with:
          tag_name: ${{steps.current_time.outputs.formattedTime}}
          release_name: Release ${{steps.current_time.outputs.formattedTime}}
          body: |
            Compiled PDF Weekly ${{steps.current_time.outputs.formattedTime}}
          draft: false
          prerelease: false
      - name: Upload Release Asset
        id: upload_release_asset
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: ./main.pdf
          asset_name: main.pdf
          asset_content_type: application/pdf
      - name: Slack Notification
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_USERNAME: weekly-report
          SLACK_ICON_EMOJI: ":bell:"
          SLACK_MESSAGE: "${{steps.upload_release_asset.outputs.browser_download_url}}"
```

`main.yaml`はタグプッシュ時の PDF のコンパイル＋AssetRelease です．
タグプッシュ時については以下の記事を参考にしてください．
https://zenn.dev/ganariya/articles/platex-github-action

`main.yaml`と比較して，`weekly.yaml`ではいくつかの変更を行っています．

### cron

毎週金曜日 11:30 に Action が実行されるようにしています．
この時間に間に合うように毎週論文を書いて実験を取り，先週よりも良い論文を書くことを目指します．

```yaml
on:
  schedule:
    # Friday 11:30(JST)
    - cron: "30 2 * * 5"
```

### 日時取得

Action 実行時の時刻を取得しています．
ここで取得した時刻は，cron 時の Release のタグ名として利用します．

```yaml
      - name: Get Current Time
        uses: 1466587594/get-current-time@v2
        id: current_time
        with:
          format: "YYYY/MM/DD-HH/mm/ss"
          utcOffset: "+09:00"
```

Release 作成時に時刻を設定しています．

```yaml
      - name: Create Release
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
        with:
          tag_name: ${{steps.current_time.outputs.formattedTime}}
          release_name: Release ${{steps.current_time.outputs.formattedTime}}
          body: |
            Compiled PDF Weekly ${{steps.current_time.outputs.formattedTime}}
          draft: false
          prerelease: false
```

### Slackに通知

Release と Asset 作成が終わったら Slack に通知を行います．
SlackMessage に URL を設定することで，論文 PDF のダウンロード URL を Slack に表示できます．

```yaml
      - name: Slack Notification
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_USERNAME: weekly-report
          SLACK_ICON_EMOJI: ":bell:"
          SLACK_MESSAGE: "${{steps.upload_release_asset.outputs.browser_download_url}}"
```

![](https://storage.googleapis.com/zenn-user-upload/op79jqprl5mmz4yhqycor0zubne2)

`SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}`については，[Incoming-Webhook](https://multi-agent.slack.com/apps/A0F7XDUAZ--incoming-webhook-)をチャンネルに設定する必要があります．
そして，Webhook 先の URL をリポジトリの secrets に `SLACK_WEBHOOK` として登録する必要があります．

## 使い方

https://github.com/tsukuba-mas/weekly_report

上記リポジトリを Clone または Import し，Slack の Webhook を設定します．
そして，WebhookURL を以下のように，あなたのリポジトリの `Repository Secrets` に設定すればいいです．
あとは，タグプッシュ時か cron のタイミングで論文がデプロイされます．
cron のタイミングは変更可能です．

![](https://storage.googleapis.com/zenn-user-upload/1v4hrrxoxudb766dxvtbo7n31ymq)

# 最後に

修士１年生の間，うまく研究を進めることができませんでした．
その結果，「今年なにか成長したかな...」という感想を持ってしまっています．（競プロやインターンは良かったのですが，研究で Full が通らずなかなかテーマも決まらず...）

研究は授業のように決まった時間がなく，個人できちんと計画を立てて進める必要があります．
その一方，非常に複雑なタスクであり，なかなか細かい粒度でバックログを切ることもできません．

1 週間・2 週間という短いスパンで「目に見える論文・動作物」を作成することで，研究のクオリティを上げていきたいと思います．
実際に自分でこの方法を試し，どのような結果が出たかを 1 か月後にまとめてみようと思います．


# P.S.

リーンキャンバスを研究時に書くと，方向性が見えるという話をきいたので，これもやっていきたいです．
また，1 週間のはじまりに「やりたい全体のバックログ」から細かいスプリント単位のログに切れるように努力しようと思います．

今気づきましたが結局は研究に対するモチベーションですね...（いくらログを切っても，競プロなどを優先していては進まない）

# 参考ページ

- https://github.com/actions/create-release
- https://github.com/actions/upload-release-asset
- https://github.com/marketplace/actions/slack-notify
- https://github.com/ajilraju/actions-date
- https://github.com/1466587594/get-current-time
