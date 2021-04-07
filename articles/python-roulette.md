---
title: "Pythonで遺伝的アルゴリズムのルーレット選択を実装する"
emoji: "🦔"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['python']
published: true
---

# はじめに

遺伝的アルゴリズムにおける `ルーレット選択` のように、決められた割合の比になるようにルーレットを行いたいことがあります。
たとえば、`1等:2等:3等:4等 = 1:2:3:4`のように、宝くじでそれぞれの割合が出てような確率生成器を作りたいです。

# 実装例

`1:2:3:4`の割合でルーレットを実行したい場合、その値をとる重み配列を作ればいいです。
あとは、累積和を作って「重みの合計 * 乱数」を二分探索すれば $O(N \log N)$で実現できます。

```python
import random
import bisect
import numpy as np


def roulette_choice(weight):
    total = sum(weight)
    c_sum = np.cumsum(weight)
    return bisect.bisect_left(c_sum, total * random.random())


if __name__ == "__main__":
    trial = 1000000
    weight = [1, 2, 3, 4]
    count = [0] * len(weight)
    for x in range(trial):
        count[roulette_choice(weight)] += 1
    print(count)
```
