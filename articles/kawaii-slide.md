---
title: "かわいいスライドでプレゼンしたい"
emoji: "🎃"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ["slide", "プレゼンテーション", "shell"]
published: false
---

# はじめに

突然ですが、みなさんはかわいいスライドでプレゼンしたくないですか（唐突）。
ぼくはかわいいすらいどでぷれぜんがしたいです。

LT 学会・社内発表会など、発表機会が多い人もいるのではないでしょうか。
これらのスライドを作るのには時間と体力がかかります。
資料を作る際に、かわいいイラストがあると楽しく作業できます（当社比）。

しかし、僕はデザインセンスもありませんし、イラストを書くスキルもありません。
今回は、いろいろな素材をお借りして、かわいいスライドをつくることを目指します。

# イラスト

## 虎の穴ラボ メイドちゃん

虎の穴ラボさんでは、プレゼン資料で利用できるメイドちゃんのイラストを配布しています。
使用する際は、ご利用ガイドをよく読んで利用しましょう。

虎の穴ラボさんは、 connpass での LT / 説明会など積極的な活動をされており
働くのがとても楽しそうだなと感じました。（新卒採用はなく中途採用だった...）

https://yumenosora.co.jp/tora-lab/special

https://github.com/toranoana/special

## ジョイネット

ジョイネットさんでは、いくつかイラスト素材を配布されています。
とくに「七瀬くるみ」ちゃんを、 Twitter で見かける人も多いと思います。
Deep Learning などの機械学習の界隈のサーベイスライドなどに、くるみちゃんの登場が多い印象です。

https://enjoynet.co.jp/free_snsicon/

https://enjoynet.co.jp/free_snsicon/nanasekurumi1/

https://enjoynet.co.jp/ip_policy/

## 立ち絵

立ち絵素材などをお借りするのもよいかもしれません。
（利用規約には注意しましょう。）

https://seiga.nicovideo.jp/search/%E7%AB%8B%E3%81%A1%E7%B5%B5?target=illust&sort=&sort=image_view

# アイコンアニメ

demsato さんが、さまざまなコンテンツで利用できるアイコンアニメを公開されています。
もともとは動画用を想定されているため、 AviUtl で利用できる png の連番形式になっています。

https://twitter.com/UDMP/status/1397080033974358018
https://seiga.nicovideo.jp/seiga/im10751275
https://demsato.booth.pm/items/2993967

スライドで利用できる形式は、 gif 画像であるためこのままでは利用できません。
そこで、 gif 画像をコマンドで生成することにします。

画像処理を行うことのできる GraphicsMagick をインストールします。
以下は Mac Homebrew でのインストール方法です。
インストールが終わったら、先程のリンクから Zip ファイルをダウンロードします。

```shell
brew install graphicsmagick
```

あとは以下のシェルスクリプトを `アイコンアニメ素材_vol1` フォルダの中に配置して実行すればよいです。
GraphicsMagick を利用して、ループ gif 画像を作成します。
`-dispose previous`を与えることで、前回の画像を破棄して gif 画像を作成できます。（これがないと、どんどん上に塗り重ねていくような描画になります。）

![](https://i.gyazo.com/afd513af0c51f0640a87d2404f1781c9.gif)

```shell
#!/bin/zsh
base=$(pwd)
materials="materials"
if [ ! -d $materials ]; then
    mkdir $materials
fi
for f in *; do
    if [ -d "$f" ]; then
        cd $base/$f
        gm convert *.png -delay 2 -dispose previous  -loop 0 ./../$materials/$f.gif
        cd $base
    fi
done
```

# アイコン

イラストだけではなく、かわいいアイコンも使わせていただくと楽しいスライドになります。

https://fukidesign.com/

https://icooon-mono.com/

https://iconmonstr.com/

# できたもの

![](https://i.gyazo.com/2c3e1f9f3426007444a39150092bfe3b.gif)

これにて、許してもらえそうです。
(そもそも進捗を出しましょう。)
