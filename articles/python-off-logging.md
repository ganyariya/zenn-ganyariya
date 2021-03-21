---
title: "pythonでThird-Partyモジュールのログ出力を止める"
emoji: "🐍"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['python', 'logging']
published: true
---

# はじめに

pythonのロギングを使うと，サードパーティ製のログも大量に出力されることがあります．
これはサードパーティのログの出力レベルが，自分のロガーの要求レベル以下である場合に発生します．

また，本記事では以下のように，プロジェクトにおいてルートロガーにすべてpropagateしてログ出力する場合を仮定しています．

```python
from logging import getLogger, Logger, FileHandler, StreamHandler, INFO, Formatter, WARNING

class Some:
    def __init__():
        self.logger: Final[Logger] = getLogger()
        stream_handler: StreamHandler = StreamHandler()
        formatter: Formatter = Formatter(fmt="%(asctime)s - %(name)s - %(levelname)s - %(message)s", datefmt='%Y/%m/%d %H:%M:%S')
        stream_handler.setFormatter(formatter)
        self.logger.addHandler(stream_handler)
        self.logger.setLevel(INFO)
```

# サードパーティ製のログをOffにする

`getLogger`を呼び出すことによって，特定の名前をもつロガーを呼び出すことができます．
このとき，サードパーティ製のパッケージ名を指定することで，サードパーティのパッケージ以下を担当するロガーを取り出せます．
これは，PythonのLoggerは木構造になっているためです．

よって，以下のように設定するとログの量を減らせます．
以下の例では，matplotlibパッケージで発生したログの出力レベルを`WARNING`に設定でき，WARNING未満は出力されなくなります．

```python
getLogger('matplotlib').setLevel(WARNING)
```

### 挙動の原因

上記のようにgetLoggerを設定することによってログの出力を減らせる理由について考えてみます．

通常サードパーティのパッケージでは，`NullHandler`が設定されています．
このように設定することによって，利用する自分のプロジェクト側で出力形式を設定できるためです．(こうしないと，たとえばサードパーティで発生したログの出力フォーマット形式が，サードパーティ独自の形式になってしまいます．)

https://python-guideja.readthedocs.io/ja/latest/writing/logging.html

しかし，自分のプロジェクト側でルートロガーを設定すると，サードパーティパッケージで発生したログがpropagateされルートロガーのレベルに対応して出力されます．
そのため，ルートロガーにINFOを設定すると，matplotlibで発生したINFOレベルのログはルートロガーまで伝搬されログに出力されてしまいます．

よって，ルートロガーまで伝搬させないために，getLoggerでロガーを取り出し，サードパーティ以下のログレベルを変更すればよいです．
