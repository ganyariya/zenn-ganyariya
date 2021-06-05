---
title: "Zenn の Google Analytics の仕組みに思いを馳せる"
emoji: "🤖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["googleanalytics"]
published: true
---

# はじめに

Zenn では Google Analytics を設定できます。
これによって、自分の書いた記事がどれぐらい見られたか、どのような人に見られているのかを知ることができます。

# 設定方法

設定方法をまとめようと思ったら、多くの方がすでにまとめていました。

https://zenn.dev/unsoluble_sugar/articles/c784905997dde2ffce68

https://zenn.dev/rhene/articles/setup-google-analytics-2020

# 計測可能である仕組み

`How to set` がすでにまとめられていたため、この記事では `How it works` を中心的にまとめようと思います。

そもそも Google Analytics は、サイトの PV 数や訪問者の特徴などを分析するためのツールです。
Google は大規模検索エンジンを提供しているため、ユーザの Web 上での動きをすべて把握できます。
把握した動きを Google 側で加工して、我々アプリ開発者に分析内容を提供するのが Google Analytics となっています。

https://marketingplatform.google.com/intl/ja/about/analytics/

さきほどの記事を参考に設定すると `G-ABCDE12345` のような**測定 ID** を得られます。

![](https://storage.googleapis.com/zenn-user-upload/5ed93e02774caff60f73cddc.png)

この測定 ID を Google が `認識` することによって、 Web ページの動向を計測できます。

ここでいう `認識` は以下のコードを分析したい自分のページに設定することで達成できます。

```javascript
<!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-ABCDE12345"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-ABCDE12345');
</script>
```

![](https://storage.googleapis.com/zenn-user-upload/92508d47da0642e036fb4ee5.png)

この javascript を設定したページが読み込まれたときに、`gtag` イベントが発火して Google に通知されているようです。
しかし、**これは自分の Web ページを持っていて、自分のページにさきほどのコードを貼る権限がないといけません。**

どうして Zenn だとコードを書いてないのに分析できるのでしょうか。

<!-- textlint-disable -->

.
.
.
.
.
.

![](https://storage.googleapis.com/zenn-user-upload/f5c6dd72ad66923b56092895.png)

あ！！！！！（驚愕）
