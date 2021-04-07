---
title: "GitHub ActionsでTeXをコンパイルしてPDFをReleasesにアップロードする"
emoji: "💭"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["github", "githubactions", "latex", "tex"]
published: true
---

# はじめに

GitHub Actions で TeX ファイルをコンパイルする Action を作成しました。
[tsukuba-mas/platex-action](https://github.com/tsukuba-mas/platex-action)

TeX ファイルがあるリポジトリで `platex-action` を指定すると、PDF ファイルをコンパイルしてくれます。

# platex-action

[platex-action](https://github.com/tsukuba-mas/platex-action)の作成は以下の技術で行われています。

- Dockerfile
- action.yml
- shell script

それぞれについて備忘録のために説明します。

## Dockerfile

GitHub Actions では、Action のベースに Dockerfile を指定できます。

Dockerfile を作成かつ指定すると、Actions 実行時にこの Dockerfile をビルドして、コンテナを実行します。

Dockerfile は主に `コンテナがシェルスクリプトを実行するための環境構築` を担当します。

たとえば、今回は `aruneko/texlive:latest` というイメージをベースにします。
そして、コンテナ実行時に必要なファイルを用意するために、COPY コマンドを用いて作成するイメージの中に入れます。（入れたファイルは、イメージからコンテナが生成されたときに、エントリーポイントであるシェルスクリプト内で利用されます。）

あとは ENTRYPOINT で実行されるシェルスクリプトを指定しておきます。

```dockerfile
FROM aruneko/texlive:latest
COPY entrypoint.sh /entrypoint.sh
COPY .latexmkrc /.latexmkrc
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT [ "/entrypoint.sh" ]
```

GitHub Actions 実行時に、Dockerfile からイメージがビルドされ、そのイメージからコンテナが作成されます。
そして、`/entrypoint.sh`が実行されます。
このとき、`entrypoint.sh`はコンテナのトップディレクトリにあります。
なぜならば、COPY で `/` に配置しているためです。

しかし、コンテナのワークディレクトリ・カレントディレクトリは**ルートディレクトリではありません。**
たとえば、先に `actions/checkout@v2` が実行された場合、`/github/workspace`にチェックアウトしたファイルが展開され、カレントディレクトリも `/github/workspace` になっています。

コンテナ実行時のカレントディレクトリは、その他の Actions や `WORKDIR` に依存することに注意してください。

## action.yml

action.yml は、GitHub Actions の Action の設定に必要なファイルです。
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

特徴的なのは `inputs` です。
`inputs`は、Action を利用したい側のリポジトリにおいて自由に変数を設定できるようにするためのものです。

たとえば、`hoge`というリポジトリにおいて、コンパイルしたい TeX ファイルが `thesis.pdf` だった場合を考えます。
このとき、`hoge/.github/workflows/main.yml`などで以下のように設定すればよいです。
こうすると、利用する hoge 側から、自由に引数を変えることができます。

```yaml
      - name: Compile Tex File
        id: compile_tex_file
        uses: tsukuba-mas/platex-action@main
        with:
          LATEX_FILE_NAME: "thesis.tex"
```

そのためには、Action 側でこの引数を利用する必要があります。（当然ですが、固定した文字列を利用すると、そもそもユーザは自由に引数の中身を変更できません。）
よって、`inputs`に引数を設定します。
この引数は `Dockerfile` で指定した `entrypoint.sh` などのシェルスクリプトのなかで、`$INPUT_LATEX_FILE_NAME`のように、`INPUT`を付け足すことで利用できます。

## shell script

シェルスクリプトを用いて、コンテナ内で実行したいコマンドを実行します。
すでに Dockerfile によって環境は構築されているため、実行したいコマンドを記述するのみです。

`cp /.latexmkrc .latexmkrc`は、Dockerfile 作成時にコピーしておいた.latexmkrc ファイルをカレントディレクトリに再コピーしています。
理由としては、`.latexmkrc`をイメージビルド時にあるディレクトリにおいていたとしても、他の Action を先に実行するとカレントディレクトリが変わることがあります。（おそらく checkout action などではディレクトリを設定できます。）

そのため、とりあえずイメージビルド時はルートにおいておいて、スクリプト実行時にカレントディレクトリに持ってくるようにしています。

`.latexmkrc`をわざわざ持ってきている理由としては、利用者側のリポジトリに `.latexmkrc` ファイルが用意されていないことがあるためです。
そのため、もし利用者側のリポジトリになければ、デフォルトの `.latexmkrc` として、Action のリポジトリの `.latexmkrc` を提供しています。

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

`INPUT_LATEX_FILE_NAME`でコンパイルする TeX ファイルを与えます。


# PDFのアップロード

上記の `platex-action` を用いると、TeX ファイルを PDF ファイルにコンパイルできます。
しかし、このままではコンパイルしただけです。
せっかく作成された PDF ファイルもそのままコンテナごと消去されてしまいます。

そこで、`actions/create-release`と `actions/upload-release-asset@v1` を利用します。
create-release は、`actions/checkout@v2`のディレクトリ `/github/workspace` にあるファイルたちを Zip ファイルをリリースします。

![](https://storage.googleapis.com/zenn-user-upload/8b3x4bmouvocrwlhjf1cfvqkpcjn)

そして、upload-release-asset を用いると特定のファイルのみを Release に作成できます。（上の画像の `main.pdf` .）

これらは、下記のような yaml ファイルを `your-tex-repository/.github/workflows/tex.yaml` に書くことで、PDF のリリースまでを行うことができます。

```yaml
on:
  push:
    tags:
      - "v*"

jobs:
  test_job:
    runs-on: ubuntu-latest
    name: Example of compiling pdf
    steps:
      # make pdf
      # LATEX_FILE_NAME -> main.pdf generated
      - name: Set up Git repository
        uses: actions/checkout@v2
      - name: Compile Tex File
        id: compile_tex_file
        uses: tsukuba-mas/platex-action@main
        with:
          LATEX_FILE_NAME: "main.tex"
      # Create Release
      - name: Create Release
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
        with:
          tag_name: ${{github.ref}}
          release_name: Release ${{ github.ref }}
          body: |
            Compiled PDF ${{github.ref}}
          draft: false
          prerelease: false
      # Upload Asset main.pdf
      - name: Upload Release Asset
        id: upload_release_asset
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: ./main.pdf
          asset_name: main.pdf
          asset_content_type: application/pdf
```

`Create Release`の `with` でタグ名やリリース名、リリース文章の Body などをユーザが与えられます。
また、`upload_url`では、`steps.create_release.outputs.upload_url`のように指定することで、`Create Release`コンテナの出力を再利用できます。

# さいごに

GitHub Actions を用いて TeX ファイルをコンパイルして PDF を作成しました。
また、Release ならびに Upload アクションを用いることで、その PDF のアップロードも行いました。

公式の Action と組み合わせると、簡単にアップロードできてうれしいですね。
とても勉強になりました。
もっともっと GitHub Actions に慣れていきたいです。
