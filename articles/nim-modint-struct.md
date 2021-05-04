---
title: "Nim で ModInt 構造体を作る"
emoji: "📑"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['nim', 'modint', '競技プログラミング']
published: true
---

# はじめに

最近、使い慣れている C++ ではなく Nim で競技プログラミングを行っています。
その中で、 ModInt 構造体が欲しい気持ちになりました。
そこで、 [Muratam さんのModInt](https://github.com/Muratam/yukicoder-nim/blob/master/lib/mathlib/modint.nim) を参考に ModInt を立てました。
ゆくゆくは、 [Nim-ACL](https://github.com/zer0-star/Nim-ACL/blob/master/src/atcoder/extra/math/modint_chaemon.nim) レベルの ModInt も理解・実装したいです。

今後も Nim でライブラリを作っていくため、今回はその備忘録です。
**解いた問題はまだ 1 問だけであるため、バグる可能性があります。ご注意ください**。

# ModInt

```nim
const MOD* = 1_000_000_007
type ModInt* = object
  v*: int
proc initModInt(x: int): ModInt =
  result.v = ((x mod MOD) + MOD) mod MOD
proc `+`*(a, b: ModInt): ModInt =
  result.v = a.v + b.v
  if result.v >= MOD: result.v = result.v mod MOD
proc `*`*(a, b: ModInt): ModInt =
  result.v = a.v * b.v
  if result.v >= MOD: result.v = result.v mod MOD
proc `^`*(a: ModInt, b: int): ModInt =
  result.v = 1
  var p = b
  var mul = a
  while p > 0:
    if (p and 1) > 0: result = result * mul
    mul = mul * mul
    p = p shr 1

proc `+`*(a: ModInt, b: int): ModInt = a + b.initModInt
proc `+`*(a: int, b: ModInt): ModInt = a.initModInt + b
proc `-`*(a: ModInt, b: int): ModInt = a + -b
proc `-`*(a, b: ModInt): ModInt = a + -b.v
proc `-`*(a: int, b: ModInt): ModInt = -a + b
proc `*`*(a: ModInt, b: int): ModInt = a * b.initModInt
proc `*`*(a: int, b: ModInt): ModInt = a.initModInt * b
proc `/`*(a, b: ModInt): ModInt = a * b^(MOD-2)
proc `/`*(a: ModInt, b: int): ModInt = a * b.initModInt^(MOD-2)
proc `+=`*(a: var ModInt, b: int) = a = a + b
proc `+=`*(a: var ModInt, b: ModInt) = a = a + b
proc `-=`*(a: var ModInt, b: int) = a = a - b
proc `-=`*(a: var ModInt, b: ModInt) = a = a - b
proc `*=`*(a: var ModInt, b: int) = a = a * b
proc `*=`*(a: var ModInt, b: ModInt) = a = a * b
proc `/=`*(a: var ModInt, b: int) = a = a / b
proc `/=`*(a: var ModInt, b: ModInt) = a = a / b
proc `$`*(a: ModInt): string = $a.v
proc `~`*(a: ModInt): ModInt = 1.initModInt / a
```

## 構造体

以下のように書くことで、 C 言語でいう構造体を作れます。
この構造体は、 C++ や Python C# のようにメソッドを生やすことができません。
これは、Nim がオブジェクト指向ではなく、手続き型のパラダイムをとっているためです。
オブジェクト指向っぽい書き方も（一応）できますが、継承よりもコンポジションを重要視しています。

```nim
type ModInt* = object
  v*: int

let x = ModInt(v: 10)
```

## コンストラクタ

プロシージャを書いてコンストラクタを実現します。
ModInt の例では、 int の値を受け取って、新しく ModInt を返しています。
このとき、 `result` は暗黙的に返される返り値であり、この v に MOD の処理を行ったものを代入しています。

ただし、 nim は第一引数の型にそのプロシージャがバインドされる（メソッドが生えているようにみえる）ため、`20.initModInt` のように書くことができます。
この機能を[Method Call](https://nim-lang.org/docs/tut2.html#object-oriented-programming-method-call-syntax) と呼ぶらしいです。

```nim
proc initModInt(x: int): ModInt =
  result.v = ((x mod MOD) + MOD) mod MOD

var x = 10
var y = initModInt(x)
var z = x.initModInt
```

## 演算子のオーバーロード

演算子のオーバーロードは、記号を ` で囲むことで実現できます。

### 二項演算

代入演算子ではない、つまり２つの引数をとり新しく値を返す場合は以下のように書きます。

```nim
proc `+`*(a, b: ModInt): ModInt =
  result.v = a.v + b.v
```

`+` 演算子は２つの引数 a, b を取り、演算結果である `result` を返します。
`result = a + b` のイメージです。

気持ち的には、 左側の引数 `a` に、 b が足されてその結果新しい変数を返す感じです。

### 複合代入演算

`+=`のようになにか演算しながら代入をする場合は以下のように書きます。

```nim
proc `+=`*(a: var ModInt, b: int) =
 a = a + b
```

`a += b` であり a が直接変更されます。
そのため、 a は `var` をつけて、代入される側の変数を直接変更します。
また、返り値は `void` であり何も変えません。
（代入され、自分自身 a が直接変更されるためです。）

このように考えると、`+` では返り値の型を指定して result を編集し、 `+=` では第一引数に `var` をつけて直接編集するのも納得できる気がします。

# おわりに

ModInt の構造体を Nim で作成しました。
まだ Nim の書き方になれていないので、ライブラリを作るなかで慣れていきたいですね。

