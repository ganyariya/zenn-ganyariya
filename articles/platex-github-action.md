---
title: "pLaTeXのGitHub Actionsを作成してPDFをReleasesにアップロードする"
emoji: "💭"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["GitHub", "GitHub Actions", "latex", "tex"]
published: false
---

# はじめに

GitHub ActionsでTeXファイルをコンパイルするActionを作成しました。
[tsukuba-mas/platex-action](https://github.com/tsukuba-mas/platex-action)

TeXファイルがあるリポジトリで`platex-action`を指定すると、PDFファイルをコンパイルしてくれます。

# platex-action

[platex-action](https://github.com/tsukuba-mas/platex-action)の作成は以下の技術で行われています。

- Dockerfile
- action.yml
- shell script

それぞれについて備忘録のために説明します。

## Dockerfile

GitHub Actionsでは、ActionのベースにDockerfileを指定できます。

Dockerfileを作成かつ指定すると、Actions実行時にこのDockerfileをビルドして、コンテナを実行します。

Dockerfileは主に`コンテナがシェルスクリプトを実行するための環境構築`を担当します。

たとえば、今回は`aruneko/texlive:latest`というイメージをベースにします。
そして、コンテナ実行時に必要なファイルを用意するために、COPYコマンドを用いて作成するイメージの中に入れます。（入れたファイルは、イメージからコンテナが生成されたときに、エントリーポイントであるシェルスクリプト内で利用されます。）

あとはENTRYPOINTで実行されるシェルスクリプトを指定しておきます。

```Dockerfile
FROM aruneko/texlive:latest
COPY entrypoint.sh /entrypoint.sh
COPY .latexmkrc /.latexmkrc
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT [ "/entrypoint.sh" ]
```

Github Actions実行時に、Dockerfileからイメージがビルドされ、そのイメージからコンテナが作成されます。
そして、`/entrypoint.sh`が実行されます。
このとき、`entrypoint.sh`はコンテナのトップディレクトリにあります。
なぜならば、COPYで`/`に配置しているためです。

しかし、コンテナのワークディレクトリ・カレントディレクトリは**ルートディレクトリではありません。**
たとえば、先に`actions/checkout@v2`が実行された場合、`/github/workspace`にチェックアウトしたファイルが展開され、カレントディレクトリも`/github/workspace`になっています。

コンテナ実行時のカレントディレクトリは、その他のActionsや`WORKDIR`に依存することに注意指定ください。

## action.yml

action.ymlは、GitHub ActionsのActionの設定に必要なファイルです。
今回は以下のように記述しています。

```yaml
name: "platex Action"
author: "mas-tsukuba"
description: "Compile tex file with platex"
inputs:
  LATEX_FILE_NAME:
    description: "Compile Tex File"
    required: true
    default: "main.tex"
runs:
  using: "docker"
  image: "Dockerfile"
```

特徴的なのは`inputs`です。
`inputs`は、Actionを利用したい側のリポジトリにおいて自由に変数を設定できるようにするためのものです。

たとえば、`hoge`というリポジトリにおいて、コンパイルしたいTeXファイルが`thesis.pdf`だった場合を考えます。
このとき、`hoge/.github/workflows/main.yml`などで以下のように設定すればよいです。
こうすると、利用するhoge側から、自由に引数を変えることができます。

```yaml
      - name: Compile Tex File
        id: compile_tex_file
        uses: tsukuba-mas/platex-action@main
        with:
          LATEX_FILE_NAME: "thesis.tex"
```

そのためには、Action側でこの引数を利用する必要があります。（当然ですが、固定した文字列を利用すると、そもそもユーザは自由に引数の中身を変更できません。）
よって、`inputs`に引数を設定します。
この引数は`Dockerfile`で指定した`entrypoint.sh`などのシェルスクリプトのなかで、`$INPUT_LATEX_FILE_NAME`のように、`INPUT`を付け足すことで利用できます。

## shell script

シェルスクリプトを用いて、コンテナ内で実行したいコマンドを実行します。
すでにDockerfileによって環境は構築されているため、行いたいコマンドを記述するのみです。

`cp /.latexmkrc .latexmkrc`は、Dockerfile作成時にコピーしておいた.latexmkrcファイルをカレントディレクトリに再コピーしています。
理由としては、`.latexmkrc`をイメージビルド時にあるディレクトリにおいていたとしても、他のActionを先に実行するとカレントディレクトリが変わることがあります。（おそらくcheckout actionなどではディレクトリを設定できます。）

そのため、とりあえずイメージビルド時はルートにおいておいて、スクリプト実行時にカレントディレクトリに持ってくるようにしています。

`.latexmkrc`をわざわざ持ってきている理由としては、latexmkrcコマンドでコンパイルするため、利用者側のリポジトリに`.latexmkrc`ファイルが用意されていないことがあります。
そのため、もし利用者側のリポジトリになければ、デフォルトの`.latexmkrc`として、Actionのリポジトリの`.latexmkrc`を提供しています。

```bash
#!/bin/bash

# . = /github/workspace if actions/checkout
set -eux

if [ ! -f .latexmkrc ]; then
    cp /.latexmkrc .latexmkrc
fi

# make pdf
latexmk $INPUT_LATEX_FILE_NAME
```

`INPUT_LATEX_FILE_NAME`でファイルを指定しています。