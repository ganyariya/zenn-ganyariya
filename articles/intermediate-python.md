---
title: "中級者へのModern Python"
emoji: "💭"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['python', 'modern']
published: true
---

# はじめに

## 本記事の読者対象

- Python の開発環境・ツールをさらに覚えたい方
- よりモダンに近い Python 環境が欲しい方

## 想定していない方

- Python 自体がはじめての方
- Python 上級者

## 説明すること・しないこと

説明する

- ツールのおおまかな説明
- ツールを使用する理由・嬉しさ
- 参考になるドキュメント・URL

説明しない

- 具体的なコマンド
- 細かい文法

# Modern Python

大学院で研究をするようになってから、かなりの時間 Python を書くようになりました。
なぜならば、研究で利用しやすいライブラリが豊富であり、かつ研究のようなイテレーションがはやいプロジェクトに対して非常に有効であるためです。

しかし、Python は短期的にコードを試して動作を変更できる分、安定した動作が難しくなってきます。
たとえば、C++などはコンパイルを通す必要があるため、設計をうまく考えて実装する必要があります。
一方、Python はスクリプト言語なので最悪 `闇の設計` をすると設計が適当でもなんとかなってしまいます。
ただ、このような後先考えないコードは将来的に大きな負債になります。
実際、締め切りが近い論文に合わせて急ピッチで書いたコードが現在自分の前に立ちはだかり、また 1 から設計・実装し直す羽目になりました。

Python は良くも悪くも以下のような特徴があります。

- 型を設定しなくていい
  - その分、変数名に思いを馳せることになる
- モジュールが多い
  - バージョンがずれる
- パッケージマネージャーが豊富
  - どれを使えばいいのかが分かりづらい
- 設計が甘くて良い
  - 読み辛くなる

今回は、これらの問題を解決できる可能性があるツールについてまとめます。
ただし、実際の使い方や詳細については割愛しているため、他記事を参考ください。

自分もはやく Python に慣れて中級者になっていきたいです。

# パッケージマネージャー

Python のパッケージマネージャーには多くの種類の組み合わせがあります。
以前[pythonの環境構築戦争にイラストで終止符をどうやら打てない](https://qiita.com/ganariya/items/1bf870275bad7b5ab506)という記事で Python の環境の構築について説明しました。
そこから自分の理解もある程度進み、今の Python の環境構築これでいいかな〜と感じるものがあったため、それについてまとめようと思います。

## パターン1: pyenv + pipenv

`pyenv`は**複数の Python のバージョンを管理**できます。
具体的には、Python3.7、Python3.8、Python3.9 をそれぞれインストールして好きに切り替えることができます。
このように Python のバージョンを切り替えることによって、複数のプロジェクトに対応できます。
たとえば、昔から続いているプロジェクトのコードは Python2.7 でしか動かないんだ！みたいなこともあります。
そのため、pyenv でバージョンを切り替えられるとうれしいわけです。

しかし、pyenv はバージョンを切り替えることはできますが、仮想環境を作成することはできません。
この仮想環境とはプロジェクトごとに利用する環境のことを本記事では指します。

もし仮想環境を切り分けられない場合を考えてみます。
機械学習のプロジェクト開発を行った後、別のプロジェクトに割り当てられ Django の開発になったとします。
このとき、機械学習の pytorch のライブラリは Django に直接必要はありません。
大量にライブラリが増えてくると動作も重くなり、必要なバージョンの整合性が取れなくなってきます。
そのため、プロジェクトごとにライブラリをインストールできるような仮想環境が必要なわけです。

この問題を解決すべく、`pipenv`は `あるバージョンのPythonにおいて複数の仮想環境を作成する` ことができます。
venv をラップするような便利な機能が pipenv にたくさん備わっているのでオススメです。
また、ここでは詳しくは述べませんが、ライブラリのバージョン管理をより賢く行えます。

まとめると、`pyenv`で Python 自体のバージョンを管理し、`pipenv`で特定の Python のバージョンにおける仮想環境を管理します。
Mac では brew で pipenv, pyenv 両方インストールできます。

## パターン2: pyenv + poetry

pyenv はさきほど出てきました。
今回、新しく出てきたのは poetry になります。

poetry は rust っぽくライブラリ管理ができるマネージャーのようです。
まだ触ったことがないため詳しくないのですが、toml ファイル 1 つですべてを管理するらしいです。

かなり新しいマネージャーのようなので、今度触ってみたいです。

## 参考URL

- [poetry](https://python-poetry.org/docs/)
- [pipenv](https://pipenv-ja.readthedocs.io/ja/translate-ja/basics.html)
- [Pythonのパッケージ周りのベストプラクティスを理解する](https://www.m3tech.blog/entry/python-packaging) 

# 型の導入

Python は型付けをしなくても動くスクリプト言語です。
そのため、初期段階ではかなりのスピードで開発できますが、後半になってくると変数に思いを馳せる時間が長くなり、実行時エラーに悩まされることが多くなります。

そこで、Python3.5 から導入された `typing` などを利用して型安全にコーディングできます。
しかし、**プログラム実行時、変数に異なる型の内容が入っていてもエラーを出さない**ことに注意が必要です。

実行時に異なる型が入っていても止まりません。
しかし、IDE の恩恵を受けやすくなったり、第三者がコードの意味を理解しやすくなるため、積極的に書いていきましょう。

## typing

```python
def greeting(name: str) -> str:
    return 'Hello ' + name
```

Python3.5 から、上記のように変数や関数などに型を指定できるようになりました。
型を指定することで、IDE の恩恵を受けやすくなります。
また、長期的に見るとコーディングの効率化に繋がります。

`Final`キーワードもあり、定数などをより安全に設定できます。

詳しくは参考 URL を御覧ください。

## data classes

データを格納するクラスを簡単に作成するデコレータなどを提供します。

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

可能であれば `typing.NamedTuple` を継承したクラスでタプルを宣言したほうがわかりやすいです。

```python
class Employee(NamedTuple):
    name: str
    id: int
```

## ジェネリクス

## pydantic

FastAPI で採用されているライブラリです。
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

型があっていないデータが入ると**実行時でも**例外を投げてくれます。
（一方 typing などは実行時エラーを投げません。そのため、型でおかしい箇所がよりわかりやすく、堅牢性が上がります。）

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

docstring を書くことで以下のようなメリットがあります。

- 他のチームメンバーに関数やクラスの振る舞いを伝えることができる
- ドキュメントとコードの距離が近い
- IDE などにおいて、型や補足情報がより詳細になる
- 後述しますが、`Sphinx`というドキュメント自動作成ツールで docstring を利用できる
- なにより将来の自分のためになる

## スタイルの種類

docstring の書き方にはいくつかの流儀があります。
主なものは以下の 3 つです。

- reStructuredText
- NumPy
- Google

それぞれ書き方に特徴があります。
自分の好きな書き方を参照するのが良さそうです。
また、チームで docstring の書き方が決まっていればその書き方にならいましょう。

docstring は書き方のリファレンスが少なく、何かのライブラリを参考にすると良さそうです。

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
`"` or `'`、文字数、変数の付け方などさまざまです。

異なるコードスタイルを統一的にするべく、コードチェック・Lint・フォーマッターなどがあります。
これらを用いることでより統一的な Python コードを書くことができます。

この節では、そのうち自分が使っているものについてのみ触れます。
そのため、これら以外にも他の Linter があります。ぜひ調べてみてください。

## pep

`pep`は、`python enhancement proposal`の略で、ドキュメント・コーディング規約を指します。
Python をより良くするための提案書であり、有名なのは `pep8` です。

pep8 は標準ライブラリなどのコーディング規約となっており、多くの Python のコードはこの pep8 を基準にしています。

![](https://storage.googleapis.com/zenn-user-upload/zhin92fp6grcf2i5cuf8u3648gaf)

## flake8

`flake8`は pip でインストールできるコードのフォーマットをチェックするツールです。
コーディング規約を守っているかをチェックしてくれます。

flake8 は以下 3 つのライブラリのラッパーになっています。

- PyFlakes
- pycodestyle
- mccabe

flake8 は、一行の文字数など、細かい規約の設定を行うことができます。
また、以下のような flake8 プラグインを pip インストールすると、`flake8`のコマンドを実行したとき、自動でそれらのプラグインも実行してくれます。

- flake8-docstrings
- flake8-mypy
- flake8-isort
- flake8-print

## black

`black`はコードフォーマッターです。
flake8 は `規約違反の箇所を教える` ものでしたが、black は `実際にコードをフォーマット` します。

black の特徴は比較的新しくできたものであり、そして変更できる設定がかなり少ないです。
そのため、black を使っておけば多くのプロジェクトで似たような強制フォーマットになります。

black は非常に使いやすいため、ぜひ使いたいですね。

## mypy

`mypy`は、コードのアノテーション・型を静的解析して、間違っている型を教えてくれます。
mypy のおかげで、間違っている箇所の型を治すだけで良くなります。

しかし、利用しているライブラリなどに対してエラーを出すこともあるため、そのときはスタブを生成したり、すでに pip で配布されているスタブをインストールする必要があります。

## isort

`isort`は、python の import の順番を修正します。
flake8 に isort プラグインがあるため、順番がおかしいと警告されたときに isort をすると良さそうです。

## 参考URL

- [pep](https://www.python.org/dev/peps/)
- [flake8](https://flake8.pycqa.org/en/latest/)
- [black](https://black.readthedocs.io/en/stable/)
- [mypy](http://www.mypy-lang.org/)
- [Configuring Flake8](https://flake8.pycqa.org/en/latest/user/configuration.html)
- [IntelliJやPyCharmでPythonファイルの変更を検知してflake8で文法チェックをする](https://dev.1dz.jp/jetbrains/intellij/flake8_file_watchers/)
- [Pythonによるパッケージ開発](https://future-architect.github.io/articles/20200820/)
- [PythonでLintをする](https://scrapbox.io/ganariya-public/Python%E3%81%A7Lint%E3%82%92%E3%81%99%E3%82%8B)

# 設定ファイル

Python のプロジェクトを作る際はいくつかの設定ファイルが出てきます。
この節ではこれらの設定ファイルについて説明します。

## setup.py

`s`etup.py`はプロジェクトを第三者に向けて配布するために利用するファイルです。
`setuptools`というモジュールを用いて、プロジェクトのファイルを pip でインストールできるようなパッケージを作成します。
パッケージの情報やインストールの方法、URL などを記述します。

```python
# https://packaging.python.org/tutorials/packaging-projects/?highlight=setup.py#creating-setup-py
import setuptools

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setuptools.setup(
    name="example-pkg-YOUR-USERNAME-HERE", # Replace with your own username
    version="0.0.1",
    author="Example Author",
    author_email="author@example.com",
    description="A small example package",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/pypa/sampleproject",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
)
```

普段何気なく書いている `pip install numpy` というコマンドは、setup.py で作成されたパッケージをオンライン（PyPI）から取得し、`site-packages`というディレクトリに入れています。

プロジェクトをパッケージとしてオンラインで公開したい場合は `setup.py` を書きましょう。

### MANIFEST.in

`setup.py`でプロジェクトからパッケージを作成するときに、[pythonファイル以外をパッケージに含みたいとき](ソースコード配布物を作成する)があります。
たとえば、画像ファイルや音声ファイルなどが考えられます。

このとき、`MANIFEST.in`というファイルを作成することによって、より簡単にさまざま々なファイルをパッケージに含めてビルドできます。

### setup.cfg

`setup.py`はパッケージとして公開、インストールするために必要です。
しかし、直接 Author やインクルードするファイルなどを指定してしまうと、後から変更しづらくなります。

そこて、設定ファイルである `setup.cfg` を追加で作成することによって、
パッケージで使う情報を独立して管理できます。
setup.py を実行したときに `setup.cfg` があった場合は、情報を取り出して内容を上書きし、それからパッケージを作成します。

```toml
[metadata]
name = my_package
version = attr: src.VERSION
description = My package description
long_description = file: README.rst, CHANGELOG.rst, LICENSE.rst
keywords = one, two
license = BSD 3-Clause License
classifiers =
    Framework :: Django
    License :: OSI Approved :: BSD License
    Programming Language :: Python :: 3
    Programming Language :: Python :: 3.5

[options]
zip_safe = False
include_package_data = True
packages = find:
scripts =
    bin/first.py
    bin/second.py
install_requires =
    requests
    importlib; python_version == "2.6"
```

## requirements.txt

pip でインストールしたパッケージのリストが表されたファイルです。
必ずしも `requirements.txt` という名前でなくても構いませんが、慣習的にこの名前になっています。

このファイルを作成して GitHub などに含めることによって、
`pip install -r requirements.txt`で簡単に第三者がパッケージをインストールできます。

しかし、依存性の解決に向いておらず、ライブラリのバージョンの更新をし辛いなどの問題が requirements.txt には存在しています。
そのため、現在は pipenv では Pipfile、poetry では pyproject.toml という、別のパッケージ管理のファイルが利用されています。

## Pipfile/Pipfile.lock

`Pipfile`, `Pipfile.lock`は requirements.txt の問題を解決した pipenv の管理ファイルです。

Pipfile には、**直接依存する**ライブラリが記入されます。
たとえば、`requests`を使って URL を叩くプロジェクトをつくる場合には以下のような Pipfile を作成します。

```yaml
[[source]]
url = "https://pypi.python.org/simple"
verify_ssl = true
name = "pypi"

[packages]
requests = "*"
```

このとき、`requests`は他のライブラリに依存しています。
たとえば、`chardet`と呼ばれるファイルの文字コードを判別するライブラリを内部で使用しています。

ここで、`chardet`のバージョンは Pipfile には記入されません。
一方で、ライブラリすべてのバージョンが `Pipfile.lock` に記入されます。

このとき、直接使用したいトップレベルのライブラリは `Pipfile` で管理できるため、簡単にバージョンのアップグレードを検討できます。
また、依存するライブラリすべてのバージョンは `Pipfile.lock` で管理されるため、第三者が同じ実行環境を簡単に用意できます。
これによって、依存性の問題をファイルを分けることで解決できました。

## pyproject.toml

`pyproject.toml`は `PEP 518` で定義された、パッケージの設定を管理するファイルです。
最近では poetry というパッケージマネージャーがこのファイルを利用していますが、
poetry に限った設定ファイルではないらしいです。
対応している任意のパッケージマネージャーが pyproject.toml を使えます。

これまでは、`requirements.txt`, `setup.py`, `setup.cfg`, `MANIFEST.in`など多くのファイルがパッケージ公開に必要でしたが
pyproject.toml はこのファイルのみでこれらをすべて補う機能を果たします。

現在 pipenv を使っていますが、poetry ならびに pyproject.toml に興味が湧いたため使ってみようと思います。

## tox.ini

`tox`は、Python のテストを自動化するライブラリです。
tox コマンドを打つことで、`tox.ini`に書かれたテストの内容をすべて自動実行してくれます。

1 つの `pytest` ぐらいであれば、毎回そのコマンドを打つだけで良いです。
しかし、配布するバージョンに合わせて、`python2.7`, `python3.8`, `python3.9`など複数バージョンでテストを行いたいことがあります。
また、flake8 のようなコーディング規約を満たしているかのテストだけを行いたい場合もあります。

そこで、tox ならびに設定ファイル tox.ini を使うことで、1 コマンドのみですべてのテストを自動実行できます。
しかも、tox は tox が扱う特別なディレクトリ内部に他のバージョンの Python 環境を作成します。
そのため、テストごとに仮想環境が作成され、テスト間の依存がないという嬉しさもあります。

```ini
 [tox]
 # 使用する環境を指定する
 # 名前が一致しているflake8-py38は[testenv:flake8-py38]を実行する
 # py38は[testenv:py38]がないため[testenv]を実行する
 envlist =
     py38
     flake8-py38
     mypy-py38
 
 [testenv]
 deps = pipenv
 # テストで実行するコマンド
 # このコマンドはpipenv installするだけなので当然テストをパスする
 commands =
     pipenv install
 
 [testenv:flake8-py38]
 basepython = python3.8
 description = 'check flake8-style is ok?'
 commands=
     pipenv install
     pipenv run flake8 gym_md
 
 # 設定ファイル
 # https://flake8.pycqa.org/en/latest/user/configuration.html#configuration-locations
 [flake8-py38]
 max-line-length = 88
 
 
 [testenv:mypy-py38]
 basepython = python3.8
 description = 'check my-py is ok?'
 commands =
     pipenv install
     pipenv run mypy gym_md
```

## 参考URL

- [tox](https://tox.readthedocs.io/en/latest/)
- [poetry](https://python-poetry.org/)
- [Python Packaging User Guide¶](https://packaging.python.org/)
- [ソースコード配布物を作成する](https://docs.python.org/ja/3/distutils/sourcedist.html)
- [pythonのsetup.pyについてまとめる](https://qiita.com/Tadahiro_Yamamura/items/2cbcd272a96bb3761cc8)
- [Python パッケージ管理技術まとめ](https://www.yunabe.jp/docs/python_package_management.html)
- [【Techの道も一歩から】第21回「setup.pyを書いてpipでインストール可能にしよう」](https://buildersbox.corp-sansan.com/entry/2019/07/11/110000)
- [Pipfile/Pipfile.lockの必要性 -requirements.txtを用いる手法と比較して-](https://qiita.com/miyashiiii/items/92e6f745a940c4df2ddd)
- [Pythonのパッケージ周りのベストプラクティスを理解する](https://www.m3tech.blog/entry/python-packaging)
- [Python パッケージングの標準を知ろう](https://engineer.recruit-lifestyle.co.jp/techblog/2019-12-25-python-packaging-specs/)
- [Pythonによるパッケージ開発](https://future-architect.github.io/articles/20200820/)
- [Pythonのパッケージングのベストプラクティスについて考える2018](https://techblog.asahi-net.co.jp/entry/2018/06/15/162951)
- [pythonのbdistとsdistとwheelファイルについて](https://blog.n-t.jp/tech/python-wheel-bdist-sdist-pip/)

# PyPI

[PyPI](https://pypi.org/)は、python のライブラリをアップロードできるサイトです。
`pip install`をした場合などは、ここからダウンロードされています。

# テスト

python には複数のテストツールがあります。

## unittest

標準のテストライブラリは `unittest` です。
標準パッケージに含まれているため、インストールせずにテストを書けます。

TestCase クラスを継承し、test から始まるメソッドを作ります。

```python
import unittest

class TestStringMethods(unittest.TestCase):

    def test_upper(self):
        self.assertEqual('foo'.upper(), 'FOO')

    def test_isupper(self):
        self.assertTrue('FOO'.isupper())
        self.assertFalse('Foo'.isupper())

    def test_split(self):
        s = 'hello world'
        self.assertEqual(s.split(), ['hello', 'world'])
        # check that s.split fails when the separator is not a string
        with self.assertRaises(TypeError):
            s.split(2)

if __name__ == '__main__':
    unittest.main()
```

## pytest

`pytest`は、サードパーティ製のテストライブラリです。
pytest は関数をベースにテストを行い、unittest よりも詳細なエラーを出してくれます。

たとえば、以下のように出力値が間違っていた場合に、間違えた場所とその値を出力します。
pytest は簡単にかけて出力値もわかりやすいため、私は pytest を使っています。

```python
# content of test_sample.py
def inc(x):
    return x + 1


def test_answer():
    assert inc(3) == 5
```

```bash
$ pytest
=========================== test session starts ============================
platform linux -- Python 3.x.y, pytest-6.x.y, py-1.x.y, pluggy-0.x.y
cachedir: $PYTHON_PREFIX/.pytest_cache
rootdir: $REGENDOC_TMPDIR
collected 1 item

test_sample.py F                                                     [100%]

================================= FAILURES =================================
_______________________________ test_answer ________________________________

    def test_answer():
>       assert inc(3) == 5
E       assert 4 == 5
E        +  where 4 = inc(3)

test_sample.py:6: AssertionError
========================= short test summary info ==========================
FAILED test_sample.py::test_answer - assert 4 == 5
============================ 1 failed in 0.12s =============================
```

## doctest

`doctest`は、さきほど出てきた `docstring` でテストを実行することを可能とします。
doctest をインポートすると、もし docstring に `>>>` で実行例が書いてあったらその通りの動作になるかをテストしてくれます。

`pytest`のように、複雑なテストを書くことはできません。
しかし、docstring の中にあるため、テストとして利用しながら実行例として第三者に提示できます。
そのため、コードがどのような動作をするのか理解しやすく、コードも変更しやすくなります。

```python
def square(x):
    """Return the square of x.

    >>> square(2)
    4
    >>> square(-2)
    4
    """

    return x * x

if __name__ == '__main__':
    import doctest
    doctest.testmod()
```

## tox

さきほど出て来ましたが、tox を書くことで複数のテスト・コマンドを自動化できます。

## 参考URL

- [unittest](https://docs.python.org/ja/3/library/unittest.html)
- [pytest](https://docs.pytest.org/en/stable/)
- [コードのテスト](https://python-guideja.readthedocs.io/ja/latest/writing/tests.html)
- [Pytestでテストを書く 自分用](https://scrapbox.io/ganariya-public/Pytest%E3%81%A7%E3%83%86%E3%82%B9%E3%83%88%E3%82%92%E6%9B%B8%E3%81%8F)

# ドキュメント

Sphinx は、きれいなドキュメントを簡単につくることができるツールです。
Python のライブラリのリファレンスの多くは、この `Sphinx` で作成されています。

![](https://storage.googleapis.com/zenn-user-upload/xo5992jgw1m3rhaj9z8oijeu4m29)

Sphinx は、`reStructuredText`と呼ばれるマークアップ言語を用いてドキュメントを作成します。
このとき、自動でドキュメントを作成する機能である `sphinx-apidoc` が付属しており、docstring を Python コードにきちんと書いていれば、コマンド一発でドキュメントを作成できます。
そのため、docstring を書くと型や情報などを将来のために残すことができ、しかもそれがそのままリファレンスになります。
これによって、ドキュメントがコードに比べて更新されなくなり、ドキュメントが形骸化してしまうという負債も発生しづらくなりますね。

ただし、`shpinx-apidoc`によって作成される bst ファイルはデフォルトのため、立派なものにするためには自分で追加編集する必要があります。

## 参考URL

- [Sphinx](https://www.sphinx-doc.org/ja/master/)
- [ShpinxでPythonプログラムのドキュメントを書こう](https://youtu.be/euiqryTk5uk?t=3309k)
- [ドキュメントを作りたくなってしまう魔法のツールSphinx](https://www.slideshare.net/shimizukawa/sphinx-6084667)
- [Sphinxによるドキュメント作成と国際化の事始め](https://qiita.com/tatsurou313/items/8bf7b43842b7827760fa)

# cookiecutter

`cookiecutter`は、Python のきれいなプロジェクトを簡単に作成できるツールです。
[利用できるテンプレート](https://github.com/topics/cookiecutter-template)が GitHub で公開されており、このテンプレートを指定するとよく設計されたプロジェクトを簡単にローカルに作成できます。
boilerplate に自分の情報を設定しながら
ローカルに作成できるツールと考えると良さそうです。

たとえば、[cookiecutter-pypackage](https://github.com/audreyfeldroy/cookiecutter-pypackage)を指定すると簡単に以下が設定されたプロジェクトを作成できます。

- 洗練されたプロジェクト設計
- TravisCI を用いたテスト自動化
- Shpinx を用いたドキュメント作成
- tox を用いた複数環境でのテスト
- PyPI への自動リリース
- CLI インターフェイス（click）

これまで説明してきたものが一括で用意できるのでうれしいですね。

## 参考URL

- [cookiecutter](https://github.com/cookiecutter/cookiecutter)
- [cookiecutter-pypackage](https://github.com/audreyfeldroy/cookiecutter-pypackage)

# さいごに

Python の開発ツールについてまとめてきました。
まとめる中で、自分もまだまだ理解が浅い、使いこなせていないと実感しました。

`pythonic`なコードが書けるように、毎日練習していきたいです。
