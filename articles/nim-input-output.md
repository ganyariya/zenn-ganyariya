---
title: "Nimの競技プログラミング標準入出力 まとめ"
emoji: "👌"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["nim"]
published: true
---

# はじめに

最近 `nim` という言語を競技プログラミングで使い始めました。
触り始めたばかりであり、いつも標準入出力でググっているのでまとめることにします。

ゆくゆくは `nim` のマクロの機能なども理解して、他の方がやっている便利な入力方法も理解したいです。

## import

```nim
import sequtils
import strutils
import strformat
```

以上の import をコードの先頭に置いていることを前提としています。

# 標準入力

## 1行に1つのみ

```nim
import sequtils
import strutils
import strformat

# 3
let a = stdin.readLine.parseInt

# hello, world
let b = stdin.readLine

# float
let c = stdin.readLine.parseFloat

echo &"{a} {b} {c}"
```

## 1行に複数の変数

```nim
import sequtils
import strutils
import strformat

# 4 10 32
var a, b, c: int
(a, b, c) = stdin.readLine.split.map parseInt

echo &"{a} {b} {c}"

# 4 hello 32.3
# もっといい方法あったら教えて下さい... (これ微妙です)
let s = stdin.readLine.split
var
  x = parseInt(s[0])
  y = s[1]
  z = parseFloat(s[2])

echo &"{x} {y} {z}"
```

## 1行に配列

```nim
import sequtils
import strutils
import strformat

#[
3
10 20 30
]#
let N = stdin.readLine.parseInt
let a = stdin.readLine.split.map parseInt

#[
3
a is 10 20 30
]#
echo N
echo "a is ", a.join " "
```

## N行に1つの変数

`template newSeqWith(len: int; init: untyped): untyped`

`template` は AST で動く置換アルゴリズムで、コンパイル時に置換されるものらしいです。（`!=` なども実行時に置換される。）

https://github.com/nim-lang/Nim/blob/version-1-4/lib/pure/collections/sequtils.nim#L1028

```nim
import sequtils
import strutils
import strformat

#[
3
abc
def
geh
]#
var N = stdin.readLine.parseInt
let S = newSeqWith(N, stdin.readLine)

#[
3
@["abc", "def", "geh"]
]#
echo N
echo S

discard """
2
10
20
"""
N = stdin.readLine.parseInt
let A = newSeqWith(N, stdin.readLine.parseInt)

# @[10, 20]
echo A
```

## N行に複数の変数

https://nim-lang.org/docs/sequtils.html#mapIt.t%2Ctyped%2Cuntyped

`template mapIt(s: typed; op: untyped): untyped`

`mapIt`は、型がコンパイル時に明示的である s の要素それぞれに対して op の操作をしたものを返します。
`let a = (0..<10).toSeq.mapIt(it*2)`は、`@[0, ..., 9]`の要素それぞれに対して２倍の操作をする proc が適用されています。
ここで、`it` は各要素が代入されて与えられます。

```nim
import sequtils, strutils, algorithm

discard """
https://atcoder.jp/contests/abc194/tasks/abc194_b
3
1 10
2 30
4 30
"""
var N = stdin.readLine.parseInt
let ab = (0..<N).mapIt(stdin.readLine.split.map parseInt)

# @[@[1, 10], @[2, 30], @[4, 30]]
# 多次元配列として入力する
echo ab

discard """
2
1 20
4 14
"""
N = stdin.readLine.parseInt
var a, b = newSeq[int](N)
for i in 0..<N:
  (a[i], b[i]) = stdin.readLine.split.map parseInt

# @[1, 4]@[20, 14]
echo a, b
```

## H行W列の数列

```nim
import sequtils, strutils, algorithm

#[
https://atcoder.jp/contests/abc183/tasks/abc183_c
3 2
]#
var H, W: int
(H, W) = stdin.readLine.split.map parseInt

# @[@[0, 0], @[0, 0], @[0, 0]]
# 初期化のみ
var A = newSeqWith(H, newSeq[int](W))
echo A

#[
1 2
3 4
5 6
]#
var B = mapIt(0..<H, stdin.readLine.split.map parseInt)

# @[@[1, 2], @[3, 4], @[5, 6]]
echo B


#[
1 2
3 4
5 6
]#
var C = newSeq[seq[int]](H)
for i in 0..<H:
  C[i].add(stdin.readLine.split.map parseInt)

# @[@[1, 2], @[3, 4], @[5, 6]]
echo C
```

# 標準出力

## 配列スペース区切り

```nim
import sequtils, strutils, algorithm

# 1 2 3
let a = @[1, 2, 3]
echo a.join " "
```

## 配列改行区切り

```nim
import sequtils, strutils, algorithm

#[
1
2
3
]#
let a = @[1, 2, 3]
echo a.join "\n"
```

# リンク

- [Syntax of Nim](https://gist.github.com/miyakogi/b1df00c8bc99927d9d0d)
- [個人的逆引きリファレンス](http://flat-leon.hatenablog.com/entry/nim_howto)
- [Nimの入力いろいろ 競技プログラミング用](https://qiita.com/tlllune/items/62cce5792f260a1b6326)
- [Nimの競プロ用標準入力マクロ](https://foo-x.com/blog/nim-contest-macro/)
- [Nimの文字列フォーマット strformat【Nim標準ライブラリ #1】](https://qiita.com/momeemt/items/000d1f6c384f4f00e103)
- [Nimの配列を華麗に処理する sequtils【Nim 標準ライブラリ #5】](https://qiita.com/momeemt/items/fb788a4d28dc16dcfd2f)
