---
title: "Appleユーザーが強制的に集中できる環境を構築する"
emoji: "🐈"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ['mac', 'focus', 'python']
published: true
---

# はじめに

みなさんは集中することが得意ですか。
僕は苦手です。

この世には YouTube niconico Twitter などインスタントに面白いエンタメで溢れています。
しかも、おわりがありません。

**現代の人間はこれらのエンタメの欲望には勝てないのです。**
今回は、これら「集中させないよアプリたち」に立ち向かうべく、なるべく集中できる環境を作ったのでその備忘録です。

ぜひ、みなさんの知っているツールをご紹介いただければうれしいです。

## 対象読者

- Apple User
  - MacOS
  - iPhone / iPad

# スマホの使用時間を制限する

iPhone / iPad の使用時間をへらすためには、`スクリーンタイム`を設定すればいいです。
これは、ゲームや動画アプリなど、特定のアプリを使用する時間を制限するものです。

https://support.apple.com/ja-jp/HT208982

しかし、スクリーンタイムを設定しても `4桁の数字パスワード` を打ち込んでしまえば制限時間を解除できてしまいます。
僕は欲深いので、意思が弱いときには解除してしまっていました。

## スクリーンタイムを知人に設定してもらう

この問題を解決すべく、知人に頼んでスクリーンタイムパスワードを打ち込んでもらいました。
ただ、母に頼んだとき母がパスワードを忘れて iPad をクリーンインストールすることになったため、以下のような方法を取るとよいかと思います。

1. スクリーンタイムパスワードを打つ画面になるまで、自分で操作する。
2. 知人に 4 桁のパスワードを打ち込んでもらったあと、紙に書いてもらい、かつその紙を封筒に入れてもらう。
3. 封筒に封をして、家の取り出しづらいところに置いておく。

この方法は、知人の負担も少ない（4 桁のパスワードを覚えなくてよい）ため、比較的よさそうです。

## Safari を使う

Google Chrome などでは、特定のサイトの使用時間を制限できません。
Web 版 YouTube を見ても制限対象にならないのです。

そのため、断腸の思いで Chrome を削除して、 Safari を使いましょう。

# パソコンにおける SNS の使用時間を制限する

エンジニア（学生）はスマホよりもパソコンを触っている時間が長いです。
そのため、パソコンを制すれば人生を制します。

パソコンは仕事道具でありながら遊び道具であるため、Gmail Twitter YouTube などに直結します。
これらをうまく制限して、集中できるようにします。

## SNS の時間を制限する（よわい）

https://chrome.google.com/webstore/detail/blocksite-block-websites/eiimnmioipafcokbfikbljfdeojpcgbh?hl=ja

BlockSite という Chrome 拡張機能を利用します。
このアプリは、Twitter や Gmail, YouTube の使用できる時間帯を設定できます。
僕は `~07:00`, `11:40~12:30`, `20:00~` のみこれらのサイトへアクセスできるようにしています。

しかし、拡張機能であるため、削除すれば普通にサイトを見れてしまいます。
また、以下のようにオプション画面から制限時間の設定を外せば、削除せずとも見れてしまいます。

![](https://storage.googleapis.com/zenn-user-upload/4de99e71b1e31f02c91f3b1f.png)

## SNS の時間を制限する（つよい）

https://github.com/SelfControlApp/selfcontrol

`SelfControl` というアプリを利用します。
このアプリは Objective-C で書かれており、Mac の設定ごと書き換えます。
そのため、**アプリを削除しても Mac を再起動しても SNS が開けなくなります。**
一度使わない設定をするとなにをしようが使えなくなるので、おすすめです。
（逆にいえば、**かなりがんばらないと SNS アプリが使いたいときに使えない**ので自己責任、と公式に書いてありました。）

しかし、このアプリは「今から 120 分 SNS を使えなくする」というように、
数値を設定してボタンを毎回押さなくてはいけません。
これはかなり面倒です。

そこで、SelfControl をスケジュールして利用できるようにします。

https://github.com/andreasgrill/auto-selfcontrol

`Auto-SelfControl` という SelfControl のラッパーツールがあります。
json で制限したい時間帯を入力できるので便利です。

`SelfControl` と `Auto-SelfControl` は両方 brew でインストールできるので、
dotfiles に設定しておけば便利ですね。

以下のように設定しています。

```json
{
    "username": "ganariya", // Mac の User 名じゃないとだめらしい
    "selfcontrol-path": "/Applications/SelfControl.app",
    "host-blacklist": [
        "twitter.com",
        "youtube.com",
        "nicovideo.jp"
    ],
    "block-schedules":[
        {
            "weekday": null, // 毎日
            "start-hour": 6, // 使っているMacの時間帯がそのまま利用できる (JST UCT とか考えなくていい)
            "start-minute": 30,
            "end-hour": 11,
            "end-minute": 40
        },
        {
            "weekday": null,
            "start-hour": 12,
            "start-minute": 30,
            "end-hour": 20,
            "end-minute": 0
        }
    ]
}s
```

# Twitter を CLI から投稿のみできるようにする

ここまでやって、それでも Twitter をしたいときがあります。
そういうときは、CLI から Twitter をしています。

ganyariya がつくった `投稿のみ` できるツールです。
他の人のタイムラインは見れないので、一方的に投稿したいときに便利です。
集中力も途切れません。

https://github.com/ganyariya/tweet

# Gmail を極力開かないようにする

僕はなにかと Gmail を開いてしまう癖があります。
指導教員の先生からメールが来ていないか、などをチェックしてしまいます。

そもそも、**一日 2 回ぐらいしかメールを見なくてよいのです。(Twitter も)**
急用は電話や LINE 通話で来るはずです。
メールの時点で、1, 2 日遅れたとて問題ないのです（社会人は別かもです）。

そういう意識をして、極力メールを見る回数を朝と昼、そして夜だけに絞っています。

ただ、重要なメールのみは同期的にチェックしたい気持ちがあります。

そこで、Gmail から Slack にメールを転送すればいいです。
大学関連のメールのみ、Slack にメールを転送してもらいます。

以下の記事を参考に、`*@*.ac.jp` のメールが来たら Slack へ通知が来るようになりました。
Slack は常時開いており、たまにしか見ないため、より集中できそうです。

https://qiita.com/tfactory/items/70c24e8e52daa2c0edb9

# 最後に

そもそも自分の意思をもっと強くしろという話ですね...。

<!-- textlint-disable -->

ぜひ、便利なアプリや仕組みがあったら教えていただければと思います〜
