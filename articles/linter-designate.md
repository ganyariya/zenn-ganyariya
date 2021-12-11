---
title: "linter を使うときに . を指定しないほうがよさそう？"
emoji: "🖊️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["python", "linter", "formatter"]
published: true
---

# はじめに

表題のとおりです。
**linter や formatter 系ツールを使うときにおもむろにカレントディレクトリを指定するのではなく、管理したいディレクトリをちゃんと指定したほうがいいのかも**と思いました。

というのも、 python プロジェクトを作って研究しているときに linter の実行時間が徐々に長くなる事案に出くわしたためです。
**最終的には isort の実行に 5 分ぐらいかかるようになりました。**
isort が実行されている間、 ganyariya はお外を眺めているのです（無駄ですね）。

# linter & formatter

linter や formatter は、プロジェクトのコードを整合性高く管理するためのものです。
複数人で作業するとコードスタイルや規約、テストが良くない状態になることがあるので、これらのツールで強制的に管理・統一できます。

Python では以下のツールなどが有名です。
他にも汎用的なものとして reviewdog や codecov などもあります。いっぱいあります。

- flake8
- isort
- mypy
- black
- nox
- pytest (テストツールは含まれない気がしますね)

これらツールを Github Actions, Jenkins, Travis などに組み込むことで、 CI/CD と組み合わせてソースコードの品質を担保できます。

# 事案内容

研究コードを書いているとき、以下のように Makefile から linter を hook していました。
また、 GitHub Actions による CI もこれらの Makefile を叩いていました。

```Makefile
.PHONY: format
format:
	echo "Format"
	poetry run black .
	poetry run isort .

.PHONY: lint
lint:
	echo "Lint"
	poetry run isort --check --diff .
	poetry run black --check --diff .
	poetry run flake8 .
	poetry run mypy .
```

## 何が問題だったか

どういうわけか isort の実行時間が、日が経つにつれて長くなっていきました。
同時に python ファイルも増えていたため、 isort は 50 ファイルぐらいで 5 分ぐらいかかっちゃうのかって思ってました（そんなわけない）。

**しかし、 GitHub Actions 側を見るとあっという間に実行が終わっています。**
これには ganyariya さんもびっくりです。

原因を調べたところ、ローカルだけにある研究コードの実行結果 `results` ディレクトリが原因ではなかろうかと考えました。
この `results` ディレクトリには大量のディレクトリとログファイル、モデルなどが格納されていました。

結果として、 isort がこの `results` ディレクトリを再帰的にチェックしていたため大量の時間がかかっていました。
`isort .` と指定し、（おそらく）全ファイルを検索していたためです。
black などは `.` と指定してもすぐに実行が終わっていたため、このような原因をまったく疑っていませんでした。

## どうすると良かったか

`isort numpy` `black numpy` のようにチェックしたいディレクトリを明示的にすると良かったです。

これら CI や CLI のオプションなどは、デフォルトや全体を指定しがちなため、ちゃんと扱いたいディレクトリだけ指定するのが良さそうです。
なにか意図していない挙動が起きたときに、問題の切り分けがしやすくなりますね。

# 学び

linter formatter ツールによって、対象とするファイル・ディレクトリの glob 検索方式は異なります。
そのため、ツールによっては対象としてほしくないディレクトリを対象とし、実行時間が長くなる原因になります。

もし対象とするディレクトリが明らかかつ指定しやすい状態なのであれば `isort numpy` のように、直接指定するほうがいいんだなぁと思いました。

# 最後に

疑ってごめんね isort 、悪いのは僕でした...。
