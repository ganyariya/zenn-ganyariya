---
title: "モンテカルロ木探索を Python で実装する"
emoji: "🐕"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["python", "モンテカルロ木探索"]
published: true
---

# はじめに

[AlphaZero 深層学習・強化学習・探索 人工知能プログラミング実践入門](https://www.borndigital.co.jp/book/14383.html)

以上の本を参考にさせていただき、モンテカルロ木探索(MCTS)を Python で実装しました。
実装リポジトリは以下です。

https://github.com/Ganariya/MonteCarloTreeSearch

今回は、 MCTS を書くときに気をつけたことなどを将来の自分に向けてまとめておこうと思います。

# 局面に対するお気持ち

`MiniMax` や　`MCTS` の実装や本を読むときに以下のような悩みが発生すると思います。

> 二人でプレイしているけど、現在見ている state オブジェクトの `turn` プロパティって先手と後手のどっちを表しているんだ？
> そもそも `MiniMax` や `MCTS` ってどっちの視点で考えればいいんだ？

上記のような部分は、本ではかなり省略されることが多いです。

## 視点の考え方

まず、どっちの視点で考えればよいかですが、`state`の局面でこれから打つ側の視点に立って考えます。

例えば、三目並べで `o` (先手) と `x`(後手)が対戦するとします。
そして、あるメソッドの `state` において `o`が **これから** 打つとします。
このとき、必ずこのメソッドでは `o` の気持ちに立って `x` を倒す気持ちでコードを読むとよいです。
`o`としてこれから打つ手のうち、自分(これから打つ `o` )が得られる最大の点数となる行動を選択します。

同様に、あるメソッドの `state` において `x`が **これから** 打つとします。
このとき、このメソッドでは `x` の気持ちに寄り添って `o` を倒す気持ちになりましょう。
`x`としてこれから打つ手のうち、 `x`の利得が最大となる行動を選択します。

よって、捉えるべき視点は交互に変化し、「これから打つ」プレイヤーの気持ちに立って考えるとよいです。

## 点数の考え方

言葉では表現しづらいため、自分用に動画を残しています。
完全に自分用であるため、画質も悪くはきはきと喋っていません。(そもそも、記事を書くとも思っていなかったので...)
MiniMax の気持ちを書いていますが、モンテカルロ木探索も同様です。

https://www.youtube.com/watch?v=xzbruBv5FmQ

以下のコード `v = -self.next_child_based_ucb().evaluate()` では、次の局面から返される点数に `-` をつけています。
これは、動画内で説明している「親の視点」から「子供の局面」を考えるときに `-` をつけることを表しています。

https://github.com/Ganariya/MonteCarloTreeSearch/blob/af8216429217e4bb84203e7adf3d2c717f31dac3/monte_carlo_tree_search/node.py#L35

# ゲーム状態の抽象化

`abc` モジュールでゲームの状態(state)を抽象化します。
本当はインターフェースで抽象化を行いたいですが、 Python にはインターフェースが存在しません。
そのため、`ABC` クラスを継承することで、擬似的にインターフェースを表現します。

`legal_actions` はゲームのある状態で `これから` 打つことのできる合法手を返します。

```py
from __future__ import annotations
from abc import ABC, abstractmethod
from typing import List


class IState(ABC):
    @abstractmethod
    def legal_actions(self) -> List[int]:
        pass

    @abstractmethod
    def random_action(self) -> int:
        pass

    @abstractmethod
    def next(self, action: int) -> IState:
        pass

    @abstractmethod
    def is_lose(self) -> bool:
        pass

    @abstractmethod
    def is_draw(self) -> bool:
        pass

    @abstractmethod
    def is_done(self) -> bool:
        pass

    @abstractmethod
    def is_first_player(self) -> bool:
        pass
```

`tic_tac_toe` パッケージの `state.py` ではインターフェースを実際に実装しています。
各変数の意味・詳細については、[参考本](https://www.borndigital.co.jp/book/14383.html)のサンプルコードを読むとよいです。
`HEIGHT` と `WIDTH` は縦と横の盤面の長さです。
`LENGTH` は揃えるべきコマ数を表しています。

https://github.com/Ganariya/MonteCarloTreeSearch/blob/main/tic_tac_toe/state.py

# ノードの実装

モンテカルロ木で利用するノードを `node.py` として実装しています。
探索の概念自体は、参考本でわかりやすく書かれています。
また、[こちらの記事](https://blog.brainpad.co.jp/entry/2018/04/05/163000) も分かりやすいです。

特に、重要なのが `evaluate`, `expand`, `next_child_based_cub` です。

`evaluate` は　今のメソッド `evaluate` で見ているノード(self) の評価値を返します。
このとき、もし self ノードに子ノードがないのであれば、プレイアウト（ランダムに手をうつことをゲーム決着まで繰り返すこと）をします。

プレイアウトをしたのち、
self ノードの訪問回数が規定回数を超えたときに `expand` で子ノードを展開します。
各ノードへはじめて到達したときにすぐ子ノードを展開しないのは、すぐ展開するとノード数が一気に増えてしまい、見るべきでない弱い局面も探索しないといけないためです。
訪問回数が規定回数を超えるほど人気なノードのみ子ノードを展開することによって、より強い局面を中心的に探索できます。

`expand` は self (今のノード) に続く子ノードを一段回展開します。
今の局面で取れるすべての合法手それぞれを試した局面を子ノードとします。

`next_child_based_ucb` は self (今のノード)に子ノードが存在する場合、子ノードを 1 つ選択します。
訪問回数が 0 のノードがあった場合、それを優先的に選びます。
すべてのノードを 1 回以上訪問しているならば、訪問回数を基準に UCB1 で選択します。

```py

class Node:
    def __init__(self, state: IState, expand_base: int = 10) -> None:
        self.state: IState = state
        self.w: int = 0 # 報酬
        self.n: int = 0 # 訪問回数
        self.expand_base: int = expand_base
        self.children: Optional[List[Node]] = None

    def evaluate(self) -> float:
        """self (current Node) の評価値を計算して更新する."""
        if self.state.is_done():
            value = -1 if self.state.is_lose() else 0
            self.w += value
            self.n += 1
            return value

        # self (current Node) に子ノードがない場合
        if not self.children:
            # ランダムにプレイする
            v = Node.playout(self.state)
            self.w += v
            self.n += 1
            # 十分に self (current Node) がプレイされたら展開(1ノード掘り進める)する
            if self.n == self.expand_base:
                self.expand()
            return v
        else:
            v = -self.next_child_based_ucb().evaluate()
            self.w += v
            self.n += 1
            return v

    def expand(self) -> None:
        """self (current Node) を展開する."""
        self.children = [Node(self.state.next(action), self.expand_base) for action in self.state.legal_actions()]

    def next_child_based_ucb(self) -> Node:
        """self (current Node) の子ノードから1ノード選択する."""

        # 試行回数が0のノードを優先的に選ぶ
        for child in self.children:
            if child.n == 0:
                return child

        # UCB1
        sn = sum([child.n for child in self.children])
        ucb1_values = [ucb1(sn, child.n, child.w) for child in self.children]
        return self.children[argmax(ucb1_values)]

```

# MCTS

https://github.com/Ganariya/MonteCarloTreeSearch/blob/main/monte_carlo_tree_search/monte_carlo_tree_search.py

MCTS は、クラスメソッドのみで実装しています。
最初は、 MCTS にノードを貯めるような実装にしようと考えていたのですが、ひとまず参考本の通りに実装しました。

今の実装では、 `Node` 自身が次のノードを選択しています。
しかし、この実装では、ある局面が複数の探索のルートから複数作成される可能性があります。

たとえば、以下の局面を考えます。
以下の局面は、`もともとxがあって、右上にoを置いた`場合と `もともとoがあって、真ん中にxを置いた場合` の 2 種類で到達できます。
先手が `o` ですが、説明の簡略化のためどちらでもいい場合を考えます、許してください。
このとき、以下の局面は  2 つの親ノード（o を先に置いていた場合と x を先においていた場合）から到達できます。
現在の実装では、同じ以下の局面なのに、２つの親ノードから到達されるため、計算が無駄になってしまいます。

```
--o
-x-
---
```

そのため、 MCTS 自体がノードの繋がりを辞書で管理する実装が考えられます。
訪問回数も `defaultdict[Node, int]`などで　MCTS 自体が持つと [DAG](https://ja.wikipedia.org/wiki/%E6%9C%89%E5%90%91%E9%9D%9E%E5%B7%A1%E5%9B%9E%E3%82%B0%E3%83%A9%E3%83%95) のように実装できて、効率化できそうです。

# まとめ

Python で MCTS を実装しました。
参考本や参考記事が分かりやすいので、ぜひ読んでみてください。

# 参考文献

- [AlphaZero 深層学習・強化学習・探索 人工知能プログラミング実践入門](https://www.borndigital.co.jp/book/14383.html)
- [強化学習入門 Part3 － AlphaGoZeroでも重要な技術要素！ モンテカルロ木探索の入門 －](https://blog.brainpad.co.jp/entry/2018/04/05/163000)
