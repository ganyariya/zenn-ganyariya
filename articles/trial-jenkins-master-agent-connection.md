---
title: "jenkins のエージェントノード追加を試してみる"
emoji: "🗂"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["jenkins", "terraform", "gcp"]
published: true
---

# はじめに

会社において jenkins + GKE を利用しています。
ここで、 jenkins でどうやってエージェントノードを追加しているのかわかりませんでした。

そのため、 Google Cloud Platform にお試し用の jenkins master node を建てて、そこに jenkins agent node を追加してみました。
こちらの記事では、 ganyariya と同様に jenkins ノード追加をどうやるのか疑問になっている方々に向けて、自分が行ったことをまとめます。

# 構築で利用する環境について

こちらの記事では Google Cloud Platform + terraform を利用します。
そのためこれらツールが使えるように、あらかじめセットアップが必要です。

# 事前知識

実際にエージェントノードの追加を試す前に、事前に知っておいたことがあるため先にそちらについて記載します。

## あらかじめマスタノードで「ノード追加」の設定を接続したいエージェントノードの数だけ行う必要がある

jenkins におけるエージェントノード追加について、 ganyariya は当初以下のようなものだと考えていました。

> jenkins-master が 1 node 立っており、エージェントからの接続通信を常に待ち受けている。
> agent-node `A` 側で何かしらのコマンドを叩き、 jenkins-master に接続要求を行いエージェントとして追加する。
> このとき、 jenkins-master 側で設定はとくに必要なく、特定の待ち受けポートを空けているだけでよい。
> agent-node `A`, `B`, `C`... それぞれは勝手にコマンドを叩いて、 jenkins-master に要求を行い、 jenkins-master がそれらのリクエストをすべて許容してエージェントとして利用する。

しかし、上記のような `jenkins-master は特定のポートを開いて待っているだけでよい` は勘違いでした。

実際には、**以下のような操作が接続したいエージェントごとに** 必要でした。

> jenkins-master のウェブコンソール上で「ノード追加」のボタンをクリックし、 agent-node `A` を追加する。
> すると、 agent-node `A` 用の `シークレット` が発行される。
> その後、 agent-node `A` は該当のシークレットを使って jenkins-master にリクエスト要求を行い、jenkins-master のジョブノードとして利用される。
> そのため、 agent-node `A`, `B`, `C` ... のように接続した台数ぶんだけ、jenkins-master ウェブコンソールで「ノード追加」操作を行い、該当エージェントノード用のシークレットを発行する。

ジョブを動かしたいエージェントノードの数だけ、jenkins-master のウェブコンソール上で「ノード追加」をあらかじめ行う必要がありました。
また、各エージェントノードごとに個別のシークレットが発行されます。

ただ、こちらの挙動についてはセキュリティのことを考えるとそれはそうだなとなりました。
というのも、`jenkins-master の特定のポートに通信を送れば即座にエージェントとして利用される` が可能だった場合、不正な第三者が勝手にノードを追加できます。
また、 シークレットの発行がなければ、どのエージェントノードなのかの識別が行えません。

### 実行例

jenkins-master でノード `1`, ノード `2` それぞれに対して「ノード追加」を行います。
接続コマンドをみるとわかるとおり、ノード 1, 2 それぞれでシークレットが異なります。

```bash
curl -sO http://34.146.48.134:8080/jnlpJars/agent.jar
java -jar agent.jar -url http://34.146.48.134:8080/ -secret 4827832d9a8530770466799d3438479593b264ea84a3bf451fc95fdd354f7db6 -name "my-agent1" -webSocket -workDir "/home/jenkins/my-agent1"
```

```bash
curl -sO http://34.146.48.134:8080/jnlpJars/agent.jar
java -jar agent.jar -url http://34.146.48.134:8080/ -secret 9ff47345efec37f0a484de4efc5d4478d89e609eb36e5cb743f90a269036c50c -name "my-agent2" -webSocket -workDir "/home/jenkins/my-agent2"
```

![](https://storage.googleapis.com/zenn-user-upload/da559e13867f-20241116.png)
![](https://storage.googleapis.com/zenn-user-upload/291d94cfdc54-20241116.png)
![](https://storage.googleapis.com/zenn-user-upload/625c8f704f73-20241116.png)
![](https://storage.googleapis.com/zenn-user-upload/5c0016548b2d-20241116.png)
![](https://storage.googleapis.com/zenn-user-upload/00ffd83b3d69-20241116.png)

## マスタノードは接続通信を待ち受けて & エージェント側が接続要求を行う

マスタノードで「ノード追加」を行い、エージェントノードそれぞれ用のシークレットを発行します。
その後、各ノードのページを開くと `エージェントノードで叩くべきコマンド` が表示されています。

このコマンドを実行することで `エージェントノード` から jenkins-master へ接続要求を行います。

![](https://storage.googleapis.com/zenn-user-upload/625c8f704f73-20241116.png)

そのため、**通信の開始点はエージェント側**になります。
master は待ち受けるのみです。

```bash
ganyariya@jenkins-agent-node:/home/jenkins/my-agent1$ curl -sO http://34.146.48.134:8080/jnlpJars/agent.jar
java -jar agent.jar -url http://34.146.48.134:8080/ -secret 4827832d9a8530770466799d3438479593b264ea84a3bf451fc95fdd354f7db6 -name "my-agent1" -webSocket -workDir "/home/jenkins/my-agent1"
Nov 16, 2024 5:21:41 AM org.jenkinsci.remoting.engine.WorkDirManager initializeWorkDir
INFO: Using /home/jenkins/my-agent1/remoting as a remoting work directory
Nov 16, 2024 5:21:41 AM org.jenkinsci.remoting.engine.WorkDirManager setupLogging
INFO: Both error and output logs will be printed to /home/jenkins/my-agent1/remoting
Nov 16, 2024 5:21:41 AM hudson.remoting.Launcher createEngine
INFO: Setting up agent: my-agent1
Nov 16, 2024 5:21:41 AM hudson.remoting.Engine startEngine
INFO: Using Remoting version: 3261.v9c670a_4748a_9
Nov 16, 2024 5:21:41 AM org.jenkinsci.remoting.engine.WorkDirManager initializeWorkDir
INFO: Using /home/jenkins/my-agent1/remoting as a remoting work directory
Nov 16, 2024 5:21:41 AM hudson.remoting.Launcher$CuiListener status
INFO: WebSocket connection open
Nov 16, 2024 5:21:41 AM hudson.remoting.Launcher$CuiListener status
INFO: Connected
```

## マスタとエージェントが通信するには主に 3 パターン存在する

マスタとエージェントが通信するとき、主に以下の 3 パターンがあります。

- SSH
- TCP with WebSocket
- TCP

こちらの記事では `TCP` & `TCP with WebSocket` の方法を試しています。
SSH は秘密鍵と公開鍵を発行する必要があり手間だなと考えたため行っていません。

### TCP with WebSocket

下記のように `-webSocket` をつけてエージェント側でコマンドを実行すると WebSocket を通じて jenkins-master と接続します。

```bash
java -jar agent.jar -url http://34.146.48.134:8080/ -secret 4827832d9a8530770466799d3438479593b264ea84a3bf451fc95fdd354f7db6 -name "my-agent1" -webSocket -workDir "/home/jenkins/my-agent1"
```

公式ドキュメントの通り、 WebSocket の場合は Web Console のポート（デフォルト 8080）を利用します。
そのため、後続する `Seciruty > TCP for inbound agents` **の設定はしなくてよいです**。

https://www.jenkins.io/doc/book/security/services/#tcp-agent-listener-port

>Inbound agents may instead be configured to use WebSocket transport to connect to Jenkins. In this case no extra TCP port need be enabled and no special security configuration is needed.

### TCP

TCP の場合は `-webSocket` を外すことで、 TCP による接続になります。

```bash
java -jar agent.jar -url http://34.146.48.134:8080/ -secret 4827832d9a8530770466799d3438479593b264ea84a3bf451fc95fdd354f7db6 -name "my-agent1" -workDir "/home/jenkins/my-agent1"
```

この場合、 エージェントからの通信を待ち受ける `jenkins-master 接続ポート` を設定する必要があります。
この設定は Security から行います。

![](https://storage.googleapis.com/zenn-user-upload/c6642f1e2476-20241116.png)


50000 ポートに固定すれば、 jenkins-master は 50000 ポートを jenkins-agent との通信に利用します。
こちらのポート固定を利用することでファイアウォールの設定が楽になります。

一方、ランダムを選択すると空いているポートをランダムに利用するため、ファイアウォールを広めに開ける必要があります。

ためしに my-agent1, my-agent2 から `50000 ポートに固定` で通信すると以下のようになりました。
lsof を見ると、 jenkins-master は 50000 ポートを利用していることがわかります。

<!-- textlint-disable -->
:::message
`10.0.1.2` を利用しているのは、 50000 ポートが terraform で定義したファイアウォールの設定で許可されていないためです。
内部 IP では全部のポートが許容されているため、 `10.0.1.2` を利用しています。
:::
<!-- textlint-enable -->

```bash
# my-agent1
java -jar agent.jar -url http://10.0.1.2:8080/ -secret 4827832d9a8530770466799d3438479593b264ea84a3bf451fc95fdd354f7db6 -name "my-agent1"  -workDir "/home/jenkins/my-agent1"

# my-agent2
java -jar agent.jar -url http://10.0.1.2:8080/ -secret 9ff47345efec37f0a484de4efc5d4478d89e609eb36e5cb743f90a269036c50c -name "my-agent2"  -workDir "/home/jenkins/my-agent2"

# master
sudo lsof -i -P | grep java
java      3757         jenkins    8u  IPv6  19478      0t0  TCP *:8080 (LISTEN)
java      3757         jenkins  301u  IPv6  26347      0t0  TCP jenkins-master-node.asia-northeast1-a.c.ganyariya.internal:50000->jenkins-agent-node.asia-northeast1-a.c.ganyariya.internal:38686 (ESTABLISHED)
java      3757         jenkins  306u  IPv6  25935      0t0  TCP *:50000 (LISTEN)
java      3757         jenkins  307u  IPv6  25552      0t0  TCP jenkins-master-node.asia-northeast1-a.c.ganyariya.internal:50000->jenkins-agent-node.asia-northeast1-a.c.ganyariya.internal:34772 (ESTABLISHED)
```

# 実際にマスタとエージェントをつなげてみる

ここからは実際にノード追加を試し、簡単なジョブを実行してみます。

## terraform を立ち上げる

https://github.com/ganyariya/playground/tree/main/jenkins-agent-connection

上記を clone して `terraform apply` を行います。
これによって、 master と agent ノードが立ち上がります。

![](https://storage.googleapis.com/zenn-user-upload/240b832eda64-20241116.png)

## jenkins-master をセットアップする

Compute Engine VM で表示されている `外部IP` にアクセスして jenkins を初期設定します。

はじめに、`http://34.146.48.134:8080` のようにアクセスすればよいです。
すると、 jenkins 初期画面が表示されるため、 jenkins の通常セットアップを行います。

## ノードを追加する

my-agent1, my-agent2 を追加します。
このとき、以下をそれぞれ設定します。

- remote FS route
  - my-agentX の作業パスを設定します。
  - `/home/jenkins/my-agent1` の場合、このパス配下にエージェント用の作業フォルダが用意されます。
- Number of executors
  - 最大並列ジョブ実行数
- **ラベル**
  - groovy で「どのノードを使いたいか」をラベルで指定します
  - そのときに使うのがここの `ラベル` です

ここではともにラベルを `my-agent` にしています。

![](https://storage.googleapis.com/zenn-user-upload/471005f9f220-20241116.png)

![](https://storage.googleapis.com/zenn-user-upload/7f2040b95ae8-20241116.png)


## ノードをエージェントに接続する

`jenkins-agent-node` に 2 つぶん SSH 接続します。
gcloud でもよいですし、画像の `SSH` ボタンによる接続でもよいです。

![](https://storage.googleapis.com/zenn-user-upload/240b832eda64-20241116.png)

それぞれで以下のコマンドを実行します（TCP 通信パターン）。
なお、 secret は環境ごとに異なるため jenkins-master ウェブコンソールで出ているシークレットを使ってください。

```bash
# my-agent1 (SSH1)
java -jar agent.jar -url http://10.0.1.2:8080/ -secret 4827832d9a8530770466799d3438479593b264ea84a3bf451fc95fdd354f7db6 -name "my-agent1"  -workDir "/home/jenkins/my-agent1"

# my-agent2 (SSH2)
java -jar agent.jar -url http://10.0.1.2:8080/ -secret 9ff47345efec37f0a484de4efc5d4478d89e609eb36e5cb743f90a269036c50c -name "my-agent2"  -workDir "/home/jenkins/my-agent2"
```

`INFO: Connected` が出れば成功です。
また、接続に成功した場合 jenkins-master ウェブコンソール上でもマシンとして認識されています。

```bash
Nov 16, 2024 5:38:49 AM org.jenkinsci.remoting.engine.WorkDirManager initializeWorkDir
INFO: Using /home/jenkins/my-agent1/remoting as a remoting work directory
Nov 16, 2024 5:38:49 AM org.jenkinsci.remoting.engine.WorkDirManager setupLogging
INFO: Both error and output logs will be printed to /home/jenkins/my-agent1/remoting
Nov 16, 2024 5:38:49 AM hudson.remoting.Launcher createEngine
INFO: Setting up agent: my-agent1
Nov 16, 2024 5:38:49 AM hudson.remoting.Engine startEngine
INFO: Using Remoting version: 3261.v9c670a_4748a_9
Nov 16, 2024 5:38:49 AM org.jenkinsci.remoting.engine.WorkDirManager initializeWorkDir
INFO: Using /home/jenkins/my-agent1/remoting as a remoting work directory
Nov 16, 2024 5:38:49 AM hudson.remoting.Launcher$CuiListener status
INFO: Locating server among [http://10.0.1.2:8080/]
Nov 16, 2024 5:38:49 AM org.jenkinsci.remoting.engine.JnlpAgentEndpointResolver resolve
INFO: Remoting server accepts the following protocols: [JNLP4-connect, Ping]
Nov 16, 2024 5:38:49 AM hudson.remoting.Launcher$CuiListener status
INFO: Agent discovery successful
  Agent address: 10.0.1.2
  Agent port:    50000
  Identity:      32:48:76:67:15:4c:4b:db:a3:5f:4d:79:26:11:36:b7
Nov 16, 2024 5:38:49 AM hudson.remoting.Launcher$CuiListener status
INFO: Handshaking
Nov 16, 2024 5:38:49 AM hudson.remoting.Launcher$CuiListener status
INFO: Connecting to 10.0.1.2:50000
Nov 16, 2024 5:38:49 AM hudson.remoting.Launcher$CuiListener status
INFO: Server reports protocol JNLP4-connect-proxy not supported, skipping
Nov 16, 2024 5:38:49 AM hudson.remoting.Launcher$CuiListener status
INFO: Trying protocol: JNLP4-connect
Nov 16, 2024 5:38:49 AM org.jenkinsci.remoting.protocol.impl.BIONetworkLayer$Reader run
INFO: Waiting for ProtocolStack to start.
Nov 16, 2024 5:38:50 AM hudson.remoting.Launcher$CuiListener status
INFO: Remote identity confirmed: 32:48:76:67:15:4c:4b:db:a3:5f:4d:79:26:11:36:b7
Nov 16, 2024 5:38:50 AM hudson.remoting.Launcher$CuiListener status
INFO: Connected
```

![](https://storage.googleapis.com/zenn-user-upload/69b62ce27163-20241116.png)

## ジョブを実行する

エージェント上でジョブを実行したいため、適当なサンプルジョブを作ります。
`HELLO` パイプラインジョブを作成し、以下の groovy を入力します。

![](https://storage.googleapis.com/zenn-user-upload/fd2c9d69b483-20241116.png)

```groovy
 pipeline {
     agent {
         label 'my-agent'
     }
     
     stages {
         stage('Hello') {
             steps {
                 echo 'Hello World from Jenkins Pipeline!'
                 sh 'pwd'
             }
         }
     }
 }
```

該当の groovy では `agent { label 'my-agent' }` を指定しています。
これによって、 `my-agent1`, `my-agent2` 上でジョブを実行できます。

ジョブによっては Mac や Windows でしか実行できないものがあると思います。
たとえば、 XCode によるアプリビルドなどです。
この場合は Mac インスタンスに `mac-instance` のようなラベルをつけて、 groovy 上でラベルを指定するのがよさそうです。

![](https://storage.googleapis.com/zenn-user-upload/24962e04c69b-20241116.png)

## ジョブを実行する

ジョブを実行すると下記の画像のような表示になります。
なお、追加で `sleep 30` を `sh` に追加したうえで実行した画像になります。

`my-agent2` で正常に処理が行えていることがわかります。

![](https://storage.googleapis.com/zenn-user-upload/fb48fe375338-20241116.png)

## リソースの削除

GCP のリソースを下記コマンドで削除します。

```bash
terraform destroy
```

# 最後に

実際に手を動かしてみてエージェント追加の仕組みを理解できました。
大量のノードを追加したい場合はシェルスクリプトと groovy を用意して自動化するのがよいのかなと考えています（あまりなさそうですが）。

リソースのセットアップとして terraform の勉強につながったのも良かったです。
今後もどんどんわからないことはとりあえず試してみようと思います。
