---
title: "PythonにおいてannotationsとTYPE_CHECKINGで循環参照を防ぐ"
emoji: "🐍"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["python"]
published: true
---

# はじめに

Python で `annotation` （型付け）を付けていると、循環参照に陥ることがあります。

循環参照とは以下のようにモジュールの参照がループしてしまうことを指します。

- モジュール A がモジュール B を参照
- モジュール B がモジュール A を参照

a.py
```python
from b import B


class A:
    def __init__(self):
        pass


if __name__ == '__main__':
    a: A = A()
    b: B = B(a)
```

b.py

```python
from a import A


class B:
    def __init__(self, a: A):
        self.a: A = a
```

最初から型を付けながら設計・プログラミングする場合は、循環参照を起こさないように留意できます。
しかし、すでに何年も前に作られたライブラリに型を新しく付けようとすると、問題が発生します。
これは、型定義をしているモジュールをインポートしようとすると、`相互参照`になることがあるためです。
Python は型がなくても `実行時に実体が入っていればなんとかなってしまう` ため、実体さえあればいいという設計だと、型定義を新しく付けた場合に相互参照になります。

また、プログラムが複雑になってくると、注意をしていたにも関わらず、型定義のために相互参照になってしまうことがあります。

# TYPE_CHECKING

`typing`モジュールには[TYPE_CHECKING](https://docs.python.org/ja/3/library/typing.html#typing.TYPE_CHECKING)という定数が設定されています。

これは `mypy` のような静的検査が使用されている場合に限り `True` になる変数です。
そのため、普段の通常使用時には `False` が入っています。

そのため、以下のようにすると静的検査の場合のみモジュールが読み込まれます。
はじめに、a.py では B が必要であるため、通常のように読み込みます。
しかし、b.py は `annotation` のためだけに必要であるため、`TYPE_CHECKING==True`のときのみ読み込むようにします。
このようにすると、静的検査と通常利用それぞれで以下のように動作が異なります。

- 静的検査時
  - `TYPE_CHECKING = False`
  - 静的検査のときにはモジュール A を読み込む
- 通常利用時
  - `TYPE_CHECKING = True`
  - モジュール A を読み込まないため循環参照にならない

このようにすることで、解析時のみ型のためにインポートをできます。
これによって、型＋IDE の恩恵を受けることができます。



a.py

```python
from b import B


class A:
    def __init__(self):
        pass


if __name__ == '__main__':
    a: A = A()
    b: B = B(a)

```

b.py

```python
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from a import A


class B:
    def __init__(self, a: A):
        self.a: A = a

```

しかし、実は上 2 つのファイルは動作しません。
b.py において、「`A`というクラスが型ヒントに利用されていますが、インポートされておらず名前がよくわからないよ」と出ます。
このままでは型の支援を受けることができますが実行できません。

```bash
NameError: name 'A' is not defined
```

# annotations

`__future__`の `annotations` モジュールを利用します。
[こちらで分かりやすく書かれています。](https://masahito.hatenablog.com/entry/2018/03/29/090936)
[PEPはこのページです。](https://www.python.org/dev/peps/pep-0563/)

クラス内において `__lt__` メソッドをオーバーライドする際の型ヒントのためにも使われます。

アノテーションの評価が、コンパイル時ではなく `実行時` に行われるようになります。
そのため、実行時点においてその名前が解決されていれば良くなります。

b.py を以下のように変更しました。

```python
from __future__ import annotations
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from a import A


class B:
    def __init__(self, a: A):
        self.a: A = a
```

これによって、実際にクラス B の中の引数 `A` が実行されたタイミングで、`A`という名前を解決します。
このとき、すでに `A` の身元が分かっているため、問題ありません。
（おそらく、身元がわかっていなくても python は、型ヒントをたかだか `ヒント` までにしか標準では利用しないため、問題ありません。）

# TYPE_CHECKING + annotations

TYPE_CHECKING は、静的検査のときのみモジュールをインポートさせることができます。
そのため、IDE の恩恵を受けながら、実行時はモジュールをインポートさせず、循環参照を防ぐことができます。

annotations は、実行時に注釈を解決するようになります。
そのため、IDE の恩恵を受けながら、実行時にはモジュールをインポートしなくても良くなります。

ただ、極力は相互参照しないようにコードをうまく設計したいですね。
もっと勉強していこうと思います。

