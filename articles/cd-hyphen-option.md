---
title: "cdコマンドで直前にいたディレクトリに戻る + fishのディレクトリ移動おまけ"
emoji: "🗂"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["linux", "command", "shell", "fish"]
published: true
---

# モチベーション

`fish`には `z` コマンドが用意されています。
正確には、fish シェルで使えるプラグインに `z` があります。
このプラグインは、Fuzzy 検索でこれまでターミナルで訪れたことがあるディレクトリから最も似ている名前のディレクトリに一発で移動してくれます。

たとえば以下のように打つと、`現在のディレクトリA`がどこであっても、最も名前の似ている Desktop ディレクトリに一発で移動してくれます。
```bash
z Dektop
```

このとき、Desktop ディレクトリから `元いたディレクトリA` に移動したい・戻りたい場合があります。
しかし、カレントディレクトリからの相対パスを打ち込むのは面倒です。

# `cd -`

```bash
cd -
```

つい最近知ったのですが、`cd -`と打つと直前にいたディレクトリに移動します。

たとえば、`~/Desktop/A/B/C/D`というディレクトリにいたとします。
ここで、`cd ~/Desktop/X/Y/Z`と打つと、当然 Z に移動します。
このとき、`cd -`を打つともとの `~/Desktop/A/B/C/D` に戻ります。

`pushd/popd`コマンドより機能が絞られており利用が簡単です。

# fishのディレクトリ移動

fish シェルの man コマンドで `cd` を調べるとハイフンコマンドについて書かれていました。

```bash
       Fish also ships a wrapper function around the builtin cd that understands cd - as changing to  the  previous  directory.
       See  also  prevd.  This wrapper function maintains a history of the 25 most recently visited directories in the $dirprev
       and $dirnext global variables. If you make those universal variables your cd history is shared among all fish instances.
```

Fish シェルはどうやら cd コマンドをいい感じにラップしてくれているようです。

`prevd`, `nextd`は Fish の機能のコマンドで、ディレクトリ履歴を数字$POS$だけ移動してくれます。
`dirh`コマンドでこれまでの移動履歴をわかりやすく表示してくれます。

```bash
prevd [ -l | --list ] [POS]
```

`cd -`の内部ではおそらく prevd などを叩いているのかなと思います。

# さいごに

`cd -`だけ書こうと思っていたら最終的に fish になりました。
`fish`がさらに好きになりました。

# 参考URL

- [fishシェルのディレクトリ移動履歴管理はとても簡単](https://medium.com/veltra-engineering/fish-shell-cd-history-bd70999b99a6)
- [prevd,nextd,dirh:ディレクトリ履歴を扱う](http://fish.rubikitch.com/prevd/)
