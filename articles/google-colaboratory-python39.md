---
title: "Google Colaboratory で Python3.9 を実行する"
emoji: "🙆"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["python", "colaboratory"]
published: true
---

# はじめに

2021/09/26 現在、 Colaboratory の Python のバージョンは 3.7 になっています。
しかし、 Python 3.9 でコードを実行したい場合があります。

たとえば私は現在、機械学習のコードを Python3.9 で通常の py ファイルで書いています。
そして、そのリポジトリを Colaboratory 上で clone し、通常の py ファイルのまま学習しています。
これによって、Colaboratory の GPU の恩恵に預かれます。

typing の恩恵をより受けるためにも Colaboratory 上でも 3.9 を実行できるようにします。
（`Final` や `list[str]` と py ファイルに書いているため、そもそも 3.7 だと動きません。）

ただし、以下を実行しても **jupyter notebook 自体のランタイムが 3.9 になるわけではありません。**
jupyter notebook のランタイムはかわらず 3.7 のままです。

# 3.9 に対応させる

```shell
!sudo add-apt-repository -y ppa:deadsnakes/ppa
!sudo apt-get -y update
!sudo apt-get -y install python3.9
!sudo apt-get -y install python3.9-dev
!sudo apt-get -y install python3-pip
!sudo apt-get -y install python3.9-distutils
!python3.9 -m pip install --upgrade setuptools
!python3.9 -m pip install --upgrade pip
!python3.9 -m pip install --upgrade distlib

!sudo update-alternatives --set python /usr/bin/python3.9
!sudo ln -sf /usr/bin/python /usr/local/bin/python

!python --version
# Python 3.9.7
```

はじめに、Python3.9 をインストールします。
`add-apt-repository` で Python3.9 がインストールできる個人リポジトリを追加します。
あとは実際に 3.9 のランタイムをインストールします。

次に、インストールした Python3.9 の PATH を通します。
まず、`/usr/bin/python`(シンボリックリンク) が指す python バージョンを python3.9 にします。
そのためには `!sudo update-alternatives --set python /usr/bin/python3.9` を実行すればよいです。
これで `/usr/bin/python -> /usr/bin/python3.9` となります。
ただし、 Colaboratory は `/usr/local/bin/python` を PATH の設定の都合上優先しています。
そのため、シンボリックリンクを新たに貼り直してあげればいいです（`!sudo ln -sf /usr/bin/python /usr/local/bin/python`）。
これで `/usr/local/bin/python -> /usr/bin/python -> /usr/bin/python3.9` となり、3.9 の準備完了です。

あとは `!python main.py` などとして py ファイルを実行すればよいです。

# private リポジトリを Clone して Colaboratory で実行する

おまけコーナーです。

```shell
!git clone https://username:password@github.com/username/hogehuga.git
import os
path = '/content/hogehuga'
os.chdir(path)
```

上記のコードで、private リポジトリでも clone して、そのリポジトリ内に入ることができます。
ただし、password には以下のページで設定した個人アクセストークンを設定する必要があります。
これは、最近 GitHub がパスワードログインを推奨しておらず、かわりにアクセストークンを利用する必要があるためです。

https://docs.github.com/ja/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token

# 参考にさせていただいた記事

https://qiita.com/checche/items/396309459833e6ea598c