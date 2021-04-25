---
title: "Pythonにおけるお手軽グリッドサーチ"
emoji: "👏"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['python']
published: true
---

# はじめに

`グリッドサーチ` は機械学習において精度の良いモデルを学習するための、ハイパーパラメータの組み合わせを見つける手法の１つです。

具体的には、各パラメータの組み合わせを試すことによって、精度の高いハイパーパラメータの組を発見します。
パラメータの種類が少ないうちはいいですが、増えてくると指数的に探索数が増えてくるため、ベイズ最適化や粒子群最適化などの他の手法を採用するほうがよいです。

scikit-learn には、このグリッドサーチがすでに実装されています。
しかし、今回自分は機械学習とは直接関係ないドメインで、お手軽にグリッドサーチを使いたいです。
そのため、より簡易的なグリッドサーチを実装することにします。

https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.GridSearchCV.html

# グリッドサーチ

ドメインをある１つに限った場合のグリッドサーチの例です。
本当であれば、ドメインが複数ある場合なども考慮したほうが良いのですが、来週以降使う内容を考えるとこれで事足りると判断しました。

```python
from typing import List, Generator
from itertools import product


def grid_search(domain: List[float], dim=1) -> Generator[List[float], None, None]:
    for p in product(domain, repeat=dim):
        yield p


domain = list(range(3))
for p in grid_search(domain, dim=4):
    print(p)
"""
(0, 0, 0, 0)
(0, 0, 0, 1)
(0, 0, 0, 2)
(0, 0, 1, 0)
(0, 0, 1, 1)
...
"""
```

`grid_search` 関数は、１つのパラメータに対するドメインを入力とします。
また、パラメータの個数自体が `dim` です。
パラメータの組み合わせ自体は `itertools.product` を用いると最小限で実装できます。

各パラメータに対して重い処理をする可能性があるため、 `yield` でパラメータの組ごとにで返すようにします。
