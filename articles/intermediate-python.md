---
title: "Python中級者になるためのModern Python"
emoji: "💭"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['python', 'modern']
published: false
---

# はじめに

## 本記事の読者対象

- Pythonに慣れてきて、新しい文法・開発環境を覚えたい方
- よりモダンに近いPython環境が欲しい方

## 想定していない方

- Python自体が初めての方
- Python上級者


## 説明すること・しないこと

説明する

- ツールのおおまかな説明
- ツールを使用する理由・嬉しさ
- 参考になるドキュメント・URL

説明しない

- 具体的なコマンド


# Modern Python

大学院で研究をするようになってから、長い時間Pythonを書くようになりました。
なぜならば、研究で利用しやすいライブラリが豊富、かつ研究のようなイテレーションがはやいプロジェクトに対して非常に有効であるためです。

しかし、Pythonは短期的にコードを試して動作を変更できる分、安定した動作が難しくなってきます。
例えば、C++などはコンパイルを通す必要があるため、設計をうまく考えて実装する必要があります。
一方、Pythonはスクリプト言語なので最悪`闇の設計`をすると実装考えなくてもなんとかなります。
ただ、このような後先考えないコードは将来的に大きな負債になります。
実際、締め切りが近い論文に合わせて急ピッチで書いたコードが現在自分の前に立ちはだかり、また1から設計・実装し直す羽目になりました。

Pythonは良くも悪くも以下のような特徴があります。

- 型を設定しなくていい（その分、変数名に思いを馳せる）
- モジュールが多い（バージョンがずれる）
- パッケージマネージャも豊富（どれを使えばいいのかが分かりづらい）
- 設計が甘くて良い（読み辛くなる）


今回は、これらの問題を解決できる可能性があるツールについてまとめます。
ただし、実際の使い方や詳細については割愛しているため、他記事を参考ください。

もっと自分もはやくPythonに慣れて中級者になっていきたいです。


# パッケージマネージャ

Pythonのパッケージマネージャには多くの種類の組み合わせがあります。
以前[pythonの環境構築戦争にイラストで終止符をどうやら打てない](https://qiita.com/ganariya/items/1bf870275bad7b5ab506)という記事でPythonの環境の構築について説明しました。
そこから自分の理解もある程度進み、今のPythonの環境構築これでいいかな〜と感じるものがあったため、それについてまとめようと思います。

## パターン1: pyenv + pipenv

`pyenv`は**複数のPythonのバージョンを管理**することができます。
例えば、Python3.7、Python3.8、Python3.9をそれぞれインストールして好きに切り替えることが出来ます。
バージョンを切り替えることによって、複数のプロジェクトに対応することができます。
昔から続いているプロジェクトのコードはPython2.7でしか動かないんだ！みたいなこともあります。
そのため、pyenvでバージョンを切り替えられるとうれしいわけです。

しかし、`pyenv`はバージョンを切り替えることはできますが、仮想環境を作成することはできません。
この仮想環境とはプロジェクトごとに利用する環境のことを本記事では指します。

もし仮想環境を切り分けられない場合を考えてみます。
機械学習のプロジェクト開発を行った後、別のプロジェクトに割り当てられDjangoの開発になったとします。
このとき、機械学習のpytorchのライブラリはDjangoに直接必要はありません。
大量にライブラリが増えてくると動作も重くなり、必要なバージョンの整合性が取れなくなってきます。
そのため、プロジェクトごとにライブラリをインストールできるような仮想環境が必要なわけです。

そして、`pipenv`は、`あるバージョンのPythonにおいて、複数の仮想環境を作成する`ことができます。
venvをラップするような便利な機能がpipenvにたくさん備わっているのでおすすめです。
また、ここでは詳しくは述べませんが、バージョンのロックを行うことが出来ます。

まとめると、`pyenv`でPython自体のバージョンを管理し、`pipenv`で特定のPythonのバージョンにおける仮想環境を管理します。
Macではbrewでpipenv, pyenv両方インストールできます。

## パターン2: pyenv + poetry

pyenvは先程出てきました。
今回、新しく出てきたのはpoetryになります。

poetryはrustっぽくライブラリ管理ができるマネージャのようです。
まだ触ったことがないため詳しくないのですが、tomlファイル一つですべてを管理するらしいです。

かなり新しいマネージャのようなので、今度触ってみたいです。


## 参考URL

- [poetry](https://python-poetry.org/docs/)
- [pipenv](https://pipenv-ja.readthedocs.io/ja/translate-ja/basics.html)
- [Pythonのパッケージ周りのベストプラクティスを理解する](https://www.m3tech.blog/entry/python-packaging) おすすめです

# 型の導入

Pythonは型付けをしなくても動くスクリプト言語です。
そのため、初期段階ではかなりのスピードで開発できますが、後半になってくると変数に思いを馳せる時間が長くなり、実行時エラーに悩まされることが多くなります。

そこで、Python3.5から導入された`typing`などを利用して型安全にコーディングすることができます。
しかし、**実行時に型が異なってもエラーを出さない**ことに注意が必要です。
実行時に止まるわけではなく、IDEなどでおかしい部分を指摘されやすくなります。

## typing

```python
def greeting(name: str) -> str:
    return 'Hello ' + name
```

Python3.5から、上記のように変数や関数などに型を指定できるようになりました。
型を指定することで、IDEの恩恵を受けやすくなります。
また、長期的に見るとコーディングの効率化に繋がります。

`Final`キーワードもあり、定数などをより安全に設定することが出来ます。


詳しくは参考URLを御覧ください。

## data classes

データを格納するクラスをより簡単に作成するデコレータなどを提供します。

```python
from dataclasses import dataclass

@dataclass
class InventoryItem:
    """Class for keeping track of an item in inventory."""
    name: str
    unit_price: float
    quantity_on_hand: int = 0

    def total_cost(self) -> float:
        return self.unit_price * self.quantity_on_hand
```

## namedtuple

名前をつけたタプルを宣言できます。
書き換えられないデータを保証できるので、変更しないものを管理するには便利そうです。

可能であれば`typing.NamedTuple`を継承したクラスでタプルを宣言したほうがわかりやすいです。

```python
class Employee(NamedTuple):
    name: str
    id: int
```

## ジェネリクス

## pydantic

FastAPIで採用されているライブラリです。
実行時に型情報を提供してくれます。

```python
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel


class User(BaseModel):
    id: int
    name = 'John Doe'
    signup_ts: Optional[datetime] = None
    friends: List[int] = []
    
external_data = {
    'id': '123',
    'signup_ts': '2019-06-01 12:22',
    'friends': [1, 2, '3'],
}
user = User(**external_data)
```

型があっていないようなデータが入ると**実行時でも**例外を投げてくれます。
（一方typingなどは投げません。そのため、より型でおかしい箇所がわかりやすく、堅牢性が上がります。）

## 参考URL

- [typings](https://docs.python.org/ja/3/library/typing.html)
- [dataclasses](https://docs.python.org/ja/3.9/library/dataclasses.html)
- [namedtuple](https://docs.python.org/ja/3/library/collections.html#collections.namedtuple)
- [pydantic](https://pydantic-docs.helpmanual.io/)
- [Pythonではじまる、型のある世界](https://qiita.com/icoxfog417/items/c17eb042f4735b7924a3)
- [pydanticを使って実行時にも型情報が適用されるPythonコードを書く](https://qiita.com/koralle/items/93b094ddb6d3af917702)
- [PythonとType Hintsで書くバックエンド](https://engineering.mercari.com/blog/entry/20201105-0a4057b2ba/)
- [Python 3.9 時代の型安全な Python の極め方](https://www.youtube.com/watch?v=jLQLFFznPIo)

# docstring

`docstring`は、関数やクラスなどの情報を表す文字列です。

関数やクラスがどのような引数・属性を持つのか、どのような振る舞いをするのかを文字列で記述します。

```python
def add(x:int, y:int) -> int:
    """add function.

    xとyの和を計算する。

    Attributes
    ----------
    x: int
        足される数
    y: int
        足す引数

    Returns
    -------
    int

    Notes
    -----
    こういう関数に普通はここまで書くことはない（わかるので）

    """
    return x + y
```

## docstringのメリット

docstringを書くことで以下のようなメリットがあります。

- 他のチームメンバに関数やクラスの振る舞いを伝えることができる
- ドキュメントとコードの距離が近い
- IDEなどにおいて、型や補足情報がより詳細になる
- 後述しますが、`Sphinx`というドキュメント自動作成ツールでdocstringを利用できる
- なにより将来の自分のためになる

## スタイルの種類

docstringの書き方にはいくつかの流儀があります。
主なものは以下の3つです。

- reStructuredText
- NumPy
- Google

それぞれ書き方に特徴があります。
自分の好きな書き方を参照するのが良さそうです。
また、チームでdocstringの書き方が決まっていればその書き方にならいましょう。

docstringは書き方のリファレンスが少なく、何かのライブラリを参考にすると良さそうです。

## 参考URL

- [NumPyスタイルPython Docstringsの例](https://www.sphinx-doc.org/ja/1.5/ext/example_numpy.html#example-numpy)
- [numpydoc docstring guide](https://numpydoc.readthedocs.io/en/latest/format.html)
- [Pythonのドキュメントコメントの書き方(NumPyスタイル編)](https://www.memory-lovers.blog/entry/2019/01/10/003824)
- [\[Python\]可読性を上げるための、docstringの書き方を学ぶ（NumPyスタイル）](https://qiita.com/simonritchie/items/49e0813508cad4876b5a)
- [チームメイトのためにdocstringを書こう！](https://www.slideshare.net/cocodrips/docstring-pyconjp2019)
- [numpy/numpy](https://github.com/numpy/numpy)
- [Pythonでdocstringを書く (Numpy-Style)](https://scrapbox.io/ganariya-public/Python%E3%81%A7docstring%E3%82%92%E6%9B%B8%E3%81%8F_(Numpy-Style))

# スタイルガイド

コードを複数人で書くと、それぞれ異なるコードの書き方の癖が現れます。
`"` or `'`, 文字数, 変数の付け方など様々です。

異なるコードスタイルを統一的にするためにコードチェック・Lint・フォーマッターなどがあります。
これらを用いることでより統一的なPythonコードを書くことが出来ます。

この節では、そのうち自分が使っているものについてのみ触れます。
そのため、これら以外にも他のLinterがあります。ぜひ調べてみてください。

## pep

pepは、`python enhancement proposal`の略で、ドキュメント・コーディング規約を指します。
Pythonをより良くするための提案書であり、有名なのはpep8です。

pep8は標準ライブラリなどのコーディング規約となっており、多くのPythonのコードはこのpep8を基準にしています。

![](https://storage.googleapis.com/zenn-user-upload/zhin92fp6grcf2i5cuf8u3648gaf)

## flake8

flake8はpipでインストールできるコードのフォーマットをチェックするツールです。
コーディング規約を守っているかをチェックしてくれます。

flake8は以下3つのライブラリのラッパーになっています。

- PyFlakes
- pycodestyle
- mccabe

flake8は、一行の文字数など、細かい規約の設定を行うことが出来ます。
また、以下のようなflake8-プラグインをpipインストールすると、`flake8`のコマンドを実行したとき、自動でそれらのプラグインも実行してくれます。

- flake8-docstrings
- flake8-mypy
- flake8-isort
- flake8-print

## black

`black`はコードフォーマッターです。
flake8は`規約違反の箇所を教える`ものでしたが、blackは実際にコードをフォーマットします。

blackの特徴は比較的新しくできたものであり、そして変更できる設定がかなり少ないです。
そのため、blackを使っておけば多くのプロジェクトで似たような強制フォーマットになります。

blackは非常に使いやすいため、ぜひ使いたいですね。

## mypy

mypyは、コードのアノテーション・型を静的解析して、間違っている型を教えてくれます。
mypyのおかげで、間違っている箇所の型を治すだけで良くなります。

しかし、利用しているライブラリなどに対してエラーを出すこともあるため、そのときはスタブを生成したり、すでにpipで配布されているスタブをインストールする必要があります。



## 参考URL

- [pep 0](https://www.python.org/dev/peps/)
- [flake8](https://flake8.pycqa.org/en/latest/)
- [black](https://black.readthedocs.io/en/stable/)
- [mypy](http://www.mypy-lang.org/)
- [Configuring Flake8](https://flake8.pycqa.org/en/latest/user/configuration.html)
- [IntelliJやPyCharmでPythonファイルの変更を検知してflake8で文法チェックをする](https://dev.1dz.jp/jetbrains/intellij/flake8_file_watchers/)
- [Pythonによるパッケージ開発](https://future-architect.github.io/articles/20200820/)
- [PythonでLintをする](https://scrapbox.io/ganariya-public/Python%E3%81%A7Lint%E3%82%92%E3%81%99%E3%82%8B)

# 設定ファイル


# pypi


# テスト


# ドキュメント

