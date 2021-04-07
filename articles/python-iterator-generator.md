---
title: "Pythonにおけるイテレータとジェネレータについて学ぶ"
emoji: "😊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["python"]
published: true
---

# イテレータ

イテレータは以下のような位置にくるオブジェクトを指す。

```python
for x in イテレータ:
    xの処理
```

イテレータは複数のメソッド（プロトコル）を定義している必要がある。
`__iter__`メソッドと `__next__` メソッドである。

`__iter__`メソッドはイテレータオブジェクトを返すことを期待している。
このイテレータオブジェクトは `next` 関数を呼び出せるように `__iter__` メソッドを実装している必要がある。

そして、`__next__`メソッドをオブジェクトに実装することでイテレータオブジェクトとなり、for のような反復処理を実装できる。
`StopIteration`例外を送ることで、データの読み出しが終わったことを示す。

たとえば、以下のコードは 2 乗を行うイテレータである。

```python
class SquareIterator:

    def __init__(self, *args):
        self.args = args
        self.i = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self.i == len(self.args):
            raise StopIteration()
        ret = self.args[self.i] ** 2
        self.i += 1
        return ret


sit = SquareIterator(10, 20, 30)
for x in sit:
    print(x)
```

# ジェネレータ

yield で値を返すメソッドのことである。
`__next__`プロトコルを実装できる。（どうやら暗黙的に呼び出されるらしい。）

ジェネレータを用いる理由としては、リストのように `前もってすべて計算するとメモリ的に厳しい` などがある。
全体をすべて持つことは厳しいため、１つ要素を触るごとに呼び出しごとに返すなどが行える。

```python
import random
def generator():
    while True:
        # 本当はここで画像を読むなどの重い処理がなされる
        yield random.randint(0, 10)


for x in generator():
    print(x)
```

# Type Hints

Iterator の型ヒントは以下のように行う。

```python
from typing import Iterator

class SquareIterator:

    def __init__(self, *args):
        self.args = args
        self.i = 0

    def __iter__(self) -> Iterator[int]:
        return self

    def __next__(self):
        if self.i == len(self.args):
            raise StopIteration()
        ret = self.args[self.i] ** 2
        self.i += 1
        return ret


sit: Iterator = SquareIterator(10, 20, 30)
```

ジェネレータは以下のように行う。
`Generator[YieldType, SendType, ReturnType]`という形式になっている。
今回は値を返すだけなので、SendType と YieldType が必要ない。

```python
from typing import Generator
import random


def generator() -> Generator[int, None, None]:
    while True:
        yield random.randint(0, 10)


for x in generator():
    print(x)
```

ただし、これら `Iterator` , `Generator`は 3.9 以降では `[]` で書くことが推奨されている。

# イテラブル

イテラブル (Iterable)は、for などで繰り返せるオブジェクトを指す。
たとえば、リスト、セットなどがイテラブルである。
`__iter__`メソッドもしくは `__getitem__` メソッドを定義しているオブジェクトである。

イテラブルのオブジェクトから `__iter__` メソッドを読んでイテレータを取り出す。（これは、`iter関数`によって、実行される。）
このイテレータとは `__next__` と `__iter__` メソッドをプロトコルとして実装しているオブジェクトである。
そして、このイテレータを `next関数` にわたすことによって、データを順次取り出しすることが可能である。


# 参考URL

- https://docs.python.org/ja/3/library/stdtypes.html#typeiter
- https://docs.python.org/ja/3/library/typing.html
- https://python.ms/iterable