---
title: "fish-shellで過去のコマンドをインタラクティブに選択して実行する"
emoji: "📝"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["fish", "terminal", "shell"]
published: true
---

# はじめに

[![asciicast](https://asciinema.org/a/6m7SNJPGuIp2l1BlAVmYKPjN1.svg)](https://asciinema.org/a/6m7SNJPGuIp2l1BlAVmYKPjN1)

## 扱う内容

- historyコマンド
- bashにおける過去のコマンドの再利用
- fish-nativeにおける過去のコマンドの再利用
- fish-pluginを用いたインタラクティブな過去のコマンドの再利用

## 対象読者

- historyコマンドを聞いたことのない人
- fishを使っている人

## 本記事の目的

historyコマンドの挙動を理解し、その上で過去のコマンドを呼び出せるようにします。
これをbash、fishでどのように行うかをまとめます。
そして、fish-pluginでよりインタラクティブかつuser-friendlyに行う方法をまとめます。

# historyコマンド

bashやzsh、fishにはそれぞれ`history`コマンドが実装されています。
このコマンドは`過去に実行したコマンドを表示する`ものです。
このとき、具体的な実装は各シェルによって異なります。

例えば、bashでは以下のように番号つきで表示されます。
27のほうが過去であり、41のほうが現在に近い時間で入力したコマンドです。

```bash
   27  exit
   28  eit
   29  exit
   30  ls
   31  ls
   32  pw
   33  pwd
   34  ls
   35  pip
   36  pip
   37  echo pip
   38  exit
   39  history
   40  ls
   41  history
```

対して、fishでは以下のようにインタラクティブにコマンド列が表示されます。
上に表示されるほうが、より現在に打ち込んだコマンドとなります。
そのため、bashとは表示順序が真逆となっています。
これは、fishがよりユーザにとって使いやすいシェルとなることを目指したためです。
文字を打つとコマンドがリアルタイムに絞り込まれるのも、user-friendlyを目指したためと考えられます。

```fish
history
bash
fzf
fish list
git status
:(文字を打つとインタラクティブに絞り込まれる)
```

# bashで過去のコマンドを実行する

`history`コマンドで過去の入力したコマンドを表示できるようになりました。
今度は、それをぜひ「再利用」したい気持ちになります。

bashでは`!(数字番号)`で過去のコマンドを実行できます。
たとえば、先程のbashの例では`!37`で`echo pip`を実行できます。
また、`!!`で直前のコマンド、`!$`で直前のコマンドの最後の引数を取り出せます。

```bash
bash-3.2$ !37
ls
README.md               install_brew.sh
install_fisher.sh
```

# fishで過去のコマンドを実行する

fishでは、残念ながら`!(数字番号)`や`!!`、`!$`は利用することができません。

以下の記事でも触れられていますが、user-friendlyなシェルをfishが目指した結果、このような数字番号などで過去のコマンドを実行する機能を実装しませんでした。

https://qiita.com/beeeyan/items/6e981f61c6b701597f82

そのかわりにfishではインタラクティブにコマンドを検索できます。
たとえば、何も入力していない状態で`上矢印`を入力すると、1つ前のコマンドが表示されます。
また、途中まで入力して同様に`上矢印`を入力すると、途中までの文字列が含まれるコマンドを検索できます。

このように、fishではインタラクティブな入力を提供することによって、過去のコマンドの呼び出し機能を提供しています。

# fish-pluginでインタラクティブに過去のコマンドを呼び出す

しかし、できる限り上矢印のキーはキーボード上で遠くにあるため、あまり入力したくありません。
そこで、fish-pluginを利用できます。

[![asciicast](https://asciinema.org/a/6m7SNJPGuIp2l1BlAVmYKPjN1.svg)](https://asciinema.org/a/6m7SNJPGuIp2l1BlAVmYKPjN1)

https://github.com/PatrickF1/fzf.fish

`fzf.fish`は`fzf`コマンドをもとにして、よりインタラクティブかつfuzzyなコマンド呼び出しならびに、ファイルの検索機能を提供します。

以下のような機能を提供します。

- `ctrl + r`: 過去のコマンドをインタラクティブに選択
- `ctrl + f`: 現在のディレクトリ以下のファイルとディレクトリをインタラクティブに選択
- `ctrl + v`: 環境変数をインタラクティブに選択

他にもgitのコミットをインタラクティブに選択できる機能などもあります。

# まとめ

過去のコマンドを表示する`history`についてまとめました。
その上で、過去のコマンドを再利用する方法についてまとめました。

日に日にターミナルで生活をする時間が長くなってきたので、もっともっとコマンドやシェルを理解していきたいです。
