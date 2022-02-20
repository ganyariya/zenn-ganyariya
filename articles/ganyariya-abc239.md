---
title: "ganyariya with ABC239"
emoji: "🐡"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["atcoder", "競技プログラミング"]
published: true
---

# 解説

https://scrapbox.io/ganariya-competitive/AtCoderBeginnerContest239_B%E5%95%8F%E9%A1%8C200%E7%82%B9_%E3%80%8CInteger_Division%E3%80%8D

https://scrapbox.io/ganariya-competitive/AtCoderBeginnerContest239_C%E5%95%8F%E9%A1%8C300%E7%82%B9_%E3%80%8CKnight_Fork%E3%80%8D

https://scrapbox.io/ganariya-competitive/AtCoderBeginnerContest239_D%E5%95%8F%E9%A1%8C400%E7%82%B9_%E3%80%8CPrime_Sum_Game%E3%80%8D

https://scrapbox.io/ganariya-competitive/AtCoderBeginnerContest239_E%E5%95%8F%E9%A1%8C500%E7%82%B9_%E3%80%8CSubtree_K-th_Max%E3%80%8D

https://scrapbox.io/ganariya-competitive/AtCoderBeginnerContest239_F%E5%95%8F%E9%A1%8C500%E7%82%B9_%E3%80%8CConstruct_Highway%E3%80%8D

# 個人的感想と学び

## Go ラムダ再帰関数

Go においてもラムダっぽく再帰関数できる書き方がありました。
先に型宣言を行い、その後中身を書くことで再帰の名前を参照できます。

```go
var f func(i int) int
f = func(i int) int {
    return func(i-1)
}
```

## 反省

1 つの考えに固執してずっとデバッグしていました。
いろいろな考え方・アイディアにすぐ切り替える必要があります。
