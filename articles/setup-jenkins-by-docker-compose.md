---
title: "ローカル Jenkins 環境を Docker Compose で構築する"
emoji: "🦔"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["jenkins", "docker", "docker-compose"]
published: true
---

# はじめに

みなさまはおしごとにおいて Jenkins を CI/CD として利用していますでしょうか。
ganyariya がおしごとで関わっているゲーム業界においては、 Jenkins をアプリビルドやリソースビルドに利用するのが一般的です。

このとき`パイプラインとしてすでに構築・運用されている Jenkins 環境を触る` というものは非常に怖いものです。
というのも、なにか操作を間違えるとパイプラインが一気に壊滅してしまう可能性もあるためです。
そこで、ローカル環境で動作する Jenkins を Docker Compose で簡単に構築し、試行錯誤を繰り返せるようにしましょう。

今回構築した Jenkins 環境のリポジトリにおいて実現できることは以下になります。

- dood (docker-outside-of-docker) で Docker Pipeline を利用できる
- Jenkins SSH Agent を利用できる
- Jenkins TCP/WebSocket Inbound Agent を利用できる

https://github.com/ganyariya/jenkins-by-docker-compose

この記事では Docker Compose によって動作する Jenkins 環境を構築したため、その構築内容についてまとめておきます。

- この記事で取り扱うこと
  - Docker Compose で Jenkins 環境を構築するときのコードの説明
  - Docker Compose で Jenkins 環境を構築した際の試行錯誤
- この記事で取り扱わないこと
  - Docker Compose で Jenkins 環境を構築するセットアップガイド

セットアップガイドについてはリポジトリの `setup-guide` を参照ください。

https://github.com/ganyariya/jenkins-by-docker-compose/tree/main/setup-guide

# コードを解説する

## Jenkins Controller

Jenkins の本体 = Controller についての説明です。
Controller を建てるための compose.yaml は以下のリンクとなります。

https://github.com/ganyariya/jenkins-by-docker-compose/blob/85a40313a8bdc10668c81b2c503f81e3532543b3/compose.yml#L36-L59

このうち、compose.yaml として特筆すべき点としては以下の 2 点です。

1. `/var/jenkins_home` をローカルディレクトリ `enkins-controller-data` として永続化する
2. `/var/run/docker.sock:/var/run/docker.sock` で dood pattern を実現する

はじめに 1 点目についてです。
Jenkins は設定やビルド青果物、ジョブ履歴などを Controller の作業ディレクトリへ、多くの場合 `/var/jenkins_home` へ保存します。
この `/var/jenkins_home` が失われてしまうと都度最初のセットアップから行わなければなりません。
クラウドにある Jenkins の場合は該当のクラウドの外部ストレージへ保存すべきですが、破壊と構築を繰り返すローカル環境においては、直接ファイルシステムボリュームとして管理するのが便利です。

続いて 2 点目についてです。
`docker-workflow` というプラグインを導入することで、Jenkins Pipeline 上で Docker に関する操作をおこなえます。
たとえば、任意の Image を Pull したうえでそのイメージのコンテナ上で groovy script が実行できる、といったものです。

https://plugins.jenkins.io/docker-workflow/

今回は Jenkins をホスト PC の Docker 環境の 1 コンテナとして動作させます。
そのため、 Jenkins Controller Container から Docker を利用しようとすると、 `Docker in Docker` という状態になります。
Docker のなかで Docker を利用するには


