---
title: "あば＾〜 Python の random のインスタンスって複数生成できるんすね〜"
emoji: "✨"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["python"]
published: true
---

# はじめに

Python における random って複数インスタンス生成できるんですね、という内容です。

**多くの記事やパッケージでの random の使い方が `import random` だったため、Python では C# のように別のインスタンスが生成できないと思い込んでました。**

## 基本的なランダムの使い方

多くの記事やモジュールの実装においては、ランダムな値の生成を以下のように行っています。
具体的には、`random` モジュールから `random` メソッドや `randint` メソッドを呼び出しています。

```py
import random
print(random.random())

from random import random, randint
print(random())
print(randint(0, 10))
```

seed 値を固定する場合は、以下のように seed を固定します。

```py
import random
random.seed(20)
```

## Random インスタンスを分けたいとき

多くの実用上では Random インスタンスを分けたいときがあまりありません。
現在時刻を seed とすれば、`ランダムに値を返す` という振る舞いを得られるためです。

しかし、研究のコードを書いているとき、異なるオブジェクトクラスの種類ごとに使用する乱数の系列を分けたい場合があります。再現性の観点から、同じような結果を保証したいためです。

また、並列処理をするとき、複数のプロセスにおけるインスタンスの共有・コピーの観点から極力同じインスタンスを参照したくないという気持ちになります。

# Random インスタンスを複数生成する

Python も C# みたいにインスタンスを分けられるのかなと思い、CPython のコードを覗きに行きました。

https://github.com/python/cpython/blob/7842aed7a7938df20b652177458407683e7f1a0b/Lib/random.py#L857

<!-- textlint-disable -->
あ！ `random.py` モジュールで、 `Random` クラスのインスタンスを `_inst` として生成していますね。
くわえて、外部に random という名前で export してます。
つまり、用意されていた Random インスタンスを僕たちは使っていたんですね。

<!-- textlint-enable -->

```py
_inst = Random()
seed = _inst.seed
random = _inst.random
```

面倒だと思うから先にインスタンス用意しておくよ、という心遣いも垣間見えます。

```py
# ----------------------------------------------------------------------
# Create one instance, seeded from current time, and export its methods
# as module-level functions.  The functions share state across all uses
# (both in the user's code and in the Python libraries), but that's fine
# for most programs and is easier for the casual user than making them
# instantiate their own Random() instance.
```

というわけで、複数の random インスタンスを生成したい場合は以下のようにすればいいです。
0 から 9 の異なる seed 値が与えられた random インスタンスです。

```py
from random import Random
randoms = [Random(i) for i in range(10)]
```

# まとめ

詰まったときは、公式のドキュメントや実装を見ましょう（戒め）。
