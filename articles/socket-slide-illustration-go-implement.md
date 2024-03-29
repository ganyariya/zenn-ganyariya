---
title: "ソケット通信の仕組みをスライド図解と Go 実装でまとめてみる"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["socket", "tcp", "socket", "go"]
published: true
---

# はじめに

先日、 `Linuxで動かしながら学ぶTCP/IPネットワーク入門` を読了ならびに実装しました。
こちらの本は下記に関して内容がわかりやすく記述されており、入門としてとても良い本でした。

- データリンク層におけるイーサネットを通るフレームの挙動
- TCP/IP の挙動
- アプリケーション層のプロトコル (HTTP / DHCP / NAT)
- socket 通信

https://www.amazon.co.jp/Linux%E3%81%A7%E5%8B%95%E3%81%8B%E3%81%97%E3%81%AA%E3%81%8C%E3%82%89%E5%AD%A6%E3%81%B6TCP-IP%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E5%85%A5%E9%96%80-%E3%82%82%E3%81%BF%E3%81%98%E3%81%82%E3%82%81-ebook/dp/B085BG8CH5

https://zenn.dev/ganariya/scraps/bb69305adef042

しかし、上記の本を進める中でソケット通信の内容が詳細には分からず、少しもどかしい気持ちになってしまいました。
分からなかった部分としては以下のようなものです。

- そもそも socket とはなにか
- Server で accept() したときに新しい socket を生成しているようだがこれはなにか
  - Server で最初に作成した `socket()` と同じものなのか
  - それともクライアント用の socket なのか
- Server の port 番号（例: 80）は固定でよいのか
  - 複数のクライアントから通信がくるため、 Server port 80 にやってきた通信がどの client のものかの判別方法
- pid port fd の違いについて

これら分からない部分が分からないままなのは嫌だったため、 `Server: 1 Client: 多` ソケット通信プログラムを Go で実装しました。
また、 Go のソケット通信の内部で何が行われているのかを大まかにコードリーディングしました。

<!-- textlint-disable -->
今回は、時間の経過とともに内容を忘れるであろう将来の自分、ならびにソケット通信の挙動がいまいち分からない方に向けて、学んだ内容をスライド図解とともにまとめます。
スライドは以下のリンクです。
<!-- textlint-enable -->

https://docs.google.com/presentation/d/105qsTIXiZYoUKMhXeHqqM4dQf3pqDckdVoZw0w3vnyE/edit

## 対象読者

<!-- textlint-disable -->
- 記憶が曖昧になった将来の自分
- ソケット通信の挙動がいまいち分からない方
<!-- textlint-enable -->

## 扱う内容・扱わない内容

### 扱う内容

- 下記に関する図解説明
  - ファイルディスクリプタ
  - fork / pipe
  - socket
- Go におけるクライアント複数に対する Server の Echo 実装

上記に関して、その技術を使うことによる嬉しさならびに全体的な動きをスライド図解しながらまとめようと思います。

わかりやすさを優先して書く、ならびに筆者の知識が間違っている可能性から、内容の不備が存在しえます。
ぜひコメントをいただければと思います（修正させていただきます）。

### 扱わない内容

- bind listen accept などの C 言語におけるソケット通信の流れ
  - Go はこのあたりを意識しなくていいようにしてくれています
- Family Type `AF_UNIX`
  - 同じマシン内の異なるプロセスがソケットで通信する場合の `AF_UNIX` は取り扱っていません
- 低レイヤ socket の実装
- 低レイヤ TCP / IP の実装

今度まとまった空き時間ができたら [KLab さんのスライド](https://drive.google.com/drive/folders/1k2vymbC3vUk5CTJbay4LLEdZ9HemIpZe) を参考にしながら、自分でプロトコルを実装してみたいですね。

# ソケット通信を利用する理由

はじめに、どうしてソケット通信を利用するのかについて説明します。
このとき、ファイルディスクリプタや pipe が出てきます。
これらについては、次の節で説明するため、ここではそういうものがあるのだなという認識で大丈夫です。

![](https://storage.googleapis.com/zenn-user-upload/411b29dbbfb9-20230513.png)

そもそも前提として、自プロセスが何かしらの情報を取得・送信したい場合、相手のプロセスと通信する必要があります。
たとえば、 Chrome から `zenn.dev` のサイトにアクセスして zenn のページを閲覧したい場合は、以下のプロセスが HTML 等をやり取りする必要があります。

- Chrome のプロセス
  - HTML CSS JavaScript のファイルをくださいと要求する
- zenn.dev のサーバプロセス
  - 上記のファイルを送信する

このようにプロセス間でなにかしらのメッセージ（バイト列）を通信で送信したい場合、相手のプロセスの所在が認識できなければいけません。

ここで、`親子プロセス` や明示的なコマンドパイプ（`ls | grep Documents`）の場合は、 `pipe` という UNIX 系通信機能を利用すればプロセス間で通信できます。
このように通信できるのは、2 つのプロセスが互いに簡単に相手のプロセス番号 pid を知ることができるためです。
シェルスクリプトを書くときなど、我々は明示的に `A | B | C ...` のように通信先のプロセスを指定していますね。

しかし、異なるマシン（異なるインターネット）であればどうでしょうか。
zenn.dev のサーバに関するプロセスの番号がいくつなのかは Chrome にはわかりません。
つまり**zenn.dev のどのプロセスと通信してよいのかは Client である Chrome にはわからないのです。**
このままでは Chrome と zenn.dev が情報をやりとりできません。

そこで、 Socket API を利用します。
Socket API は **`同一または異なるマシンにまたがる` 2 つのプロセスが、相手を所在を認識することなく通信するための API** です。
**ネットワーク層における `IP Address`**、ならびに**トランスポート層における `port 番号`** を組み合わせたものをソケットの通信先（アドレス）として認識します。

これによって、相手のプロセスの詳細はわからないままで、相手のアドレス（IP Address + port）に向かって socket を介して通信できます。
各プロセスは port にやってくる通信の内容を socket を通じて読み取れるため、プロセス同士が `間接的に` 通信できます。
（ポート番号や UNIX ドメインソケットを利用することで、プロセスは異なるマシンの相手の所在を知ることなく **間接的に** 通信しています、という `間接的に` です。）

## ファイルディスクリプタの利用

pipe ならびに Socket API どちらにおいても、内部ではファイルならびにファイルディスクリプタを利用しています。
そのため、Socket API の挙動について説明する前に、事前知識としてファイル・ファイルディスクリプタ・pipe からまとめようと思います。

# 事前知識: ファイルディスクリプタ pipe

## ファイル

![](https://storage.googleapis.com/zenn-user-upload/c1ceb3a69c6a-20230513.png)

UNIX / Linux ではあらゆるものを `ファイル` として扱っています。
`master_data.json` のようなテキストファイルだけでなく、キーボードや仮想端末もファイルとして扱われます。

統一的にファイルとして扱うことによって、プログラムからはファイルに対する read / write を呼び出すだけで情報を読み書きできます。

プロセスがファイルを開くと、該当のファイルを認識するための ID として `ファイルディスクリプタ` (fd) という整数が OS Kernel から与えられます。
このファイルディスクリプタは**プロセスごとに独立して** 0, 1, 2, ... と続いてきます。
<!-- textlint-disable -->
注意として、プロセス A が 0, 1, 2, 3, 4 まで開いたからといって、プロセス B の fd が 5 から始まるわけではありません。
それぞれのプロセスで 0 からはじまります。
<!-- textlint-enable -->

![](https://storage.googleapis.com/zenn-user-upload/c510e8bdf8ab-20230513.png)

たとえば、上記の画像のようにターミナルで `zsh` シェルを起動したとします。
このとき、ターミナルには仮想端末 `/dev/ttys013` が紐付けられています。

そして、 zsh のプロセスが開いているファイルディスクリプタを `lsof` コマンドで確認してみると、各 fd は `/dev/ttys013` ファイルをシンボリックリンクで指しています。

- fd: 0 標準入力 `/dev/ttys013`
- fd: 1 標準出力 `/dev/ttys013`
- fd: 2 標準エラー出力 `/dev/ttys013`

ゆえに、 Alacritty のようなターミナルでシェルを起動すると、そのターミナルに文字を入力・表示できるようになっているのですね。

## fork

![](https://storage.googleapis.com/zenn-user-upload/16b13517d6c6-20230513.png)

fork はソケット通信のために必須ではないのですが、 pipe の説明であったほうがよいので記述します。

親プロセスから子プロセスを生成する、`fork` すると、親プロセスの環境変数や `fd` が子プロセスへ継承されます。
これによって、デフォルトでは子プロセスは親プロセスと同じ標準入出力を扱えます。

fork の具体的なイメージについて、上記の画像の例で説明します。
ターミナルで `sleep 100 & > a.txt` と入力した場合を考えます。

zsh プロセスから sleep プロセスが fork されます。
このとき、 zsh の fd が sleep に継承され、標準入出力の向き先が `/dev/ttys013` となっています。
ただし、 `> a.txt` として標準出力の向き先をリダイレクトで変更しているため、 `fd: 1` のみ `a.txt` を指すようになっています。

## pipe

![](https://storage.googleapis.com/zenn-user-upload/409fe52d522f-20230513.png)

`ls | grep` のように、ユーザ自身で 2 つのプロセスの通信先を指定できるのであればソケット通信でなくパイプを利用すればよいです。
親子プロセスの通信においても `pipe()` システムコールを呼び出せば、パイプを利用して情報をやりとりできます。

パイプを利用すると、ファイルディスクリプタの向き先が接続されることによって通信を行えます。

上記の画像の例では `sleep 100 | sleep 200 > a.txt &` を実行しています。
各 sleep コマンドは zsh から fork されているため、デフォルトでは zsh と同じ標準入出力を fd が指します。

しかし、 `|` でパイプを実行しているため、`sleep 100` の `fd:1` の向き先が `sleep 200` の `fd:0` となっています。
そのため、 `sleep 100` の出力はそのまま `sleep 200` の標準入力に流れていきます。（sleep のため、なにも影響を及ぼさないですが...）

このように、ユーザ自身で 2 つのプロセスの通信先を指定できる場合は pipe でプロセス同士が通信できます。

# ソケット通信

## ソケット API がない場合

![](https://storage.googleapis.com/zenn-user-upload/8fb2b990d625-20230513.png)

同一マシンだが相手のプロセスが明示的に指定しづらい場合や、異なるマシン（ネットワーク）の場合、通信すべきプロセスがわかりません。

上記の画像の例では、 Client A は Server S のプロセスがわかりません。
同様に、 Server も Client のプロセスがどのようなものなのか、 pid がいくつかを知ることができません。
毎回 Server の会社や所有者に連絡して、プロセスならびに pid を教えてくださいということはできません。
（当然ですが、仮に相手の pid が分かっても異なるマシンであれば通信できません。）

そこで、ソケット API を利用します。

## Socket API = IP Address + Port 番号を利用する

ここ以降では、 `AF_INET` アドレスファミリーの場合のみを考慮します。
これは、異なるネットワーク（同じネットワークでもよい）の特定の Port 番号を通じて TCP/UDP で通信をする種別のことです。
`AF_UNIX` は本記事で扱いません。

![](https://storage.googleapis.com/zenn-user-upload/d25e36682c7f-20230513.png)

異なるネットワークのマシンと通信するときには、ソケット通信を利用します。
このとき、ソケットのアドレスは **「IP Address + port 番号」** で表されます。
上記のアドレスさえ分かれば通信相手を認識できるためです。

逆にいえば、どちらかだけでは相手を認識できません。
IP Address だけでは、同じクライアントにある複数のプロセスから通信が来ると、どちらのポート（プロセス）から来たものかサーバは判断できません。
同様に、ポート番号だけでは、どのネットワークのマシン（IP アドレス）からきたのか分かりません。
両方を組とすれば、複数のクライアント、ならびに同じマシンで複数のプロセス（ポート）から通信が来ても区別できます。

上記の画像の例では、Client A のプロセスは Server S のプロセスを知りません。
しかし、Client はクライアント側のソケットを介して Server S のアドレス `11.11.43.11 + 80` に向かってデータを送信するだけでうまく通信できます。
これは、Server 側で以下が行われるためです。

- Server 側が port 80 で Client A からの通信データを受け取る
- Client A のアドレス `43.12.11.8 + 1443` に該当する Server 側のソケット（ファイルディスクリプタ）に、Server の os kernel が書き込む
- Server プロセスは Server 側のソケット（ファイルディスクリプタ）からデータを読み出すことで、 Client A からのデータを受け取れる

## 通信の流れ

![](https://storage.googleapis.com/zenn-user-upload/ee0202b7264c-20230513.png)

通信の流れを具体例で説明します。

はじめに、 Server 側プログラムが起動され、サーバプロセス (pid:9983) が作成されます。

このとき、 Server がどのアドレスで待ち受けるかをプログラムで指定し、待ち受け socket を作成します。
今回の場合は、`11.11.43.11 + 80` でクライアントからの通信を待ち受けます。
待ち受け socket には `laddr = local address` に自身のアドレスが記載されています。

> 画像において socket (netFD) と書いてあるのは、のちのちの Go の実装で *net.netFD という構造体が socket の実体に Go では該当するためです。

続いて、 Client 側プログラムが起動され、クライアントプロセス（pid:2124）が作成されます。
通信先である `11.11.43.11 + 80` を `raddr = remote address` に指定した通信用ソケットを Client プログラムが作成します。
このとき、 Client がサーバと通信するための port が自動で割り振られ、`laddr` に記載されます。

今回の例では `1443` がクライアント側の通信 port として払い出されています。

Client が Server に接続したタイミングで、図における 3 番目の手順として、 Server 側は Client A 用の通信用ソケットを作成します。
待ち受けソケットをコピーして A 通信用ソケットとし、ネットワーク層のパケットから IP アドレス、トランスポート層のセグメントからポート番号を取り出し、`raddr` に記載します。
今回の例では A 通信用ソケットの `raddr` に `43.112.11.8 + 1443` を記載します。

ここまでの操作によって、 Server と Client のプロセスはそれぞれ自身の socket を介して、通信相手のアドレスが分かるようになります。
あとは socket を介して TCP のセグメントもしくは UDP のデータグラムをネットワーク層に託して相手へ送信します。

図において、`socket の内部では fd が利用されている。` とありますが、 socket も内部的にはファイルを利用しており、該当するファイルディスクリプタが払い出されています。

socket がファイルディスクリプタをラップすることにで、プログラムは socket API を介してファイルに write/read し、ファイルに記述されたデータが相手へ届けられます。

## Client が複数台の場合

ここまでの動作を眺めていくと、自分には 1 つの疑問がわきました。

> Client 側では、通信時に 1 つの port がランダムに割り当てられる。
> しかし、 Server 側は 1 つの port (例: 80) しか存在しない。
> 複数の Client から通信が来たとき、 Server は 1 つの port のみで対応できるのだろうか。

上記が達成できるのか、 Client が複数台の例を考えてみます。

![](https://storage.googleapis.com/zenn-user-upload/a0c033ede9eb-20230515.png)

Server S は `11.11.43.11 + 80` で、サーバプロセス (pid:9983) がクライアントからの通信を待ち受けています。

その後、 Client A にある 2 つのプロセス A1, A2 からサーバに対して TCP Socket 通信が行われました。
このとき、 Client A 側ではそれぞれのプロセスへ port がランダムに割り振られています (1443, 9783)。

もし、プロセス A1, A2 に同じ port 番号（例:9999）が割り振られた場合、 サーバは A1, A2 のどちらの場合でも `43.11.11.8 + 9999`  から通信を受けます。
サーバから見ると A1, A2 のどちらのプロセスから通信が来たかわかりません。そのため、通信プロセスごとに新しい port 番号が振られます。

注意点として、 Client B のプロセス B1 の通信用として port 9783 が割り当てられ、 A2 の port と一致しています。
しかし、 Client A と B の IP Address は異なるため、サーバはこれらをきちんと判別して対処できます。

ここまででのことから、 Client 側で port がプロセスごとに割り振られるのは、 Server 側がそれぞれの通信相手を区別することを認識するためと説明できました。

続いて、 Server がどのような挙動をしているのか、そしてどうして 1 つの port でよいかについてまとめます。

通信待ちの Server S プロセスがクライアント X からの通信を受け取ると、 `X 通信用の子プロセス or スレッド` と `X 通信用 socket` を生成します。
そして、 Server S プロセスは再び通信待ちに戻り、 X 通信用スレッドがクライアントとの実際の通信を対応します。

例えば、 A1 `43.12.11.8 + 1443` から `80` へ通信が来た場合、クライアント A1 通信用のスレッドと A1 通信用 socket が生成されます。
A1 通信用スレッドは、クライアント A1 との通信を担当し、 Server S は再び別のクライアントからの通信待ちに戻ります。
そして、 A1 からソケットを介した TCP 通信がやってくると、 Server S の A1 通信用 socket のファイルディスクリプタへそのデータが書き込まれます。
あとは、 A1 通信用スレッドがソケットに対して `read() / write()` を実行すれば、socket / ファイルディスクリプタを介して通信用ファイルからデータを読み出し・書き込めます。

サーバは 1 つの port (例: 80) で待機しておけば、どのクライアントから通信がやってきたのかを、サーバ側クライアント用 socket に格納した `raddr` で判別できます。
よって、サーバは 1 つの port でやりくりできます。

## Socket API のうれしさ

![](https://storage.googleapis.com/zenn-user-upload/0eea97b1eff9-20230515.png)

Socket API を利用すると、同一または異なるプロセスが互いの所在を正確には知ることなく、トランスポート層のポート番号を介して通信を行えます。

これは、プログラムから見ても `ファイル・ファイルディスクリプタ` のようなうれしさがあります。

プログラムは Socket API を利用して、 socket に対して `read/write` を行うだけでよいです。
あとは socket API が内部でいい感じにファイル・ファイルディスクリプタを用意して、通信相手とよしなにやり取りしてくれます。

# Go におけるソケット通信の実装

これまでのソケット通信の概要を踏まえて、それでは Go 言語において以下の場合のソケット通信を実装します。

- クライアント: 多
- サーバ: 1

## リポジトリ

https://github.com/ganyariya/playground/tree/main/linux-tcpip/go_socket

`cmd/server` `cmd/client` がそれぞれの実装です。
また、`pkg/info` が情報を表示出すための utility 関数 package です。

以下のコマンドでサーバ・クライアントプログラムを起動できます。

```shell
go run ./cmd/server

# client 1
go run ./cmd/client
# 別 terminal client 2
go run ./cmd/client
```

## サーバ側の実装

https://github.com/ganyariya/playground/blob/main/linux-tcpip/go_socket/cmd/server/main.go

はじめに、 `net.ResolveTCPAddr` で Socket 通信における「サーバ側（待受）」アドレスを指定します。
今回の場合は、 `tcp` ならびに `localhost:12345` です。
これで、`サーバが tcp プロトコルにおいて localhost:12345 で待ち受ける` ことを表すアドレス構造体 `TCPAddr` を作成できます。

```go
tcpAddress, _ := net.ResolveTCPAddr(TCP_PROTOCOL, SERVER_TCP_ADDRESS)
```

`ResolveTCPAddr` が返す変数は `TCPAddr` であり、`IP` `Port` をメンバ変数として持ちます。
IP Address + Port が socket 通信におけるアドレスでしたね。

https://github.com/golang/go/blob/5f345e8eb995409fec5e1abf231031613885f2ae/src/net/sockaddr_posix.go#L15

https://github.com/golang/go/blob/aa4d5e739f32397969fd5c33cbc95d316686039f/src/net/tcpsock.go#L21

続いて、 `net.ListenTCP` で `tcpAddress` のアドレスに関するサーバ待受ソケットを作成します。
このとき、内部では通信用のファイルが作成され、そのファイルディスクリプタも払い出されます。

```go
listener, _ := net.ListenTCP(TCP_PROTOCOL, tcpAddress)
```

`net.ListenTCP` の返り値は `*net.TCPListener` 構造体です。
`fd *netFD` という socket に相当するものを所持しています。

https://github.com/golang/go/blob/aa4d5e739f32397969fd5c33cbc95d316686039f/src/net/tcpsock.go#L279

`net.ListenTCP()` の内部では、 `internalSocket` 関数が実行されます。
`internalSocket` では内部的に socket system call が呼ばれ、ファイル・ファイルディスクリプタが作成されます。 
そして、 `*net.netFD` という Go における socket が生成され、上記のファイルディスクリプタを内部に所持（ラップ）します。

https://github.com/golang/go/blob/2ca4104f0519027c55266d48b47ea16ee4da6915/src/net/fd_posix.go#L17

`*net.netFD` の初期化時には、 `sysfd` (通信用ファイルのファイルディスクリプタ)が `*net.netFD` の内部に格納されていることが `newFD()` の実装で分かるかと思います。

https://github.com/golang/go/blob/2ca4104f0519027c55266d48b47ea16ee4da6915/src/net/fd_unix.go#L26

そのため、 `*net.netFD` がファイルディスクリプタならびに `tcpAddr`を内部で所持し、 listener がさらに `*net.netFD` を内部で所持するという形式になっています。

`listener` を通してソケット通信をしようとすると、 `fd: *net.netFD` などは別 package & private field なので、アクセスできません。
そのため、ソケット通信をする際は細かい内部の実装・メンバ変数を気にすることなく、 `listener.Accept()` などの抽象化されたメソッドを呼び出すだけで良くなります。

サーバ待受処理の最後として、 `listener.Accept()` で接続を待ち受けます。
そして、クライアント X から接続が来るまでは `listener.Accept()` でずっと待っています。

実際にクライアント X から接続が来ると、クライアント X 通信用に socket (*net.netFD) を作成し、 `handler` スレッドにクライアント X の通信を委ねます。
このとき、すでに `clientConn` が内部に持っている `*net.netFD` の `raddr` にはクライアント X のアドレスが記載されています。

```go
	for {
		// 実際に接続を待つ
		// クライアントから接続が来たら、そのクライアント用に新しいソケットを作成する
		clientConn, _ := listener.Accept()
		go handler(clientConn)
	}
```

handler には実際にクライアント X と TCP 通信する処理を記載します。
`conn.Read` でクライアント X から通信が来るまで待機します。

続いて、`conn` の `fd *net.netFD` が指すファイルディスクリプタのファイルに通信データが来たら、そのデータを `conn.Read()` で読み取ります。
読み取ったデータは、そのままクライアントに `conn.Write` へ送り返します。

```go
/*
クライアント X と実際に通信をする
conn = listener.fd をコピーして作成された、特定のクライアント X 用の socket connection
*/
func handler(conn net.Conn) {
	connInfo := info.GetNetConnectionInfo(true, conn)
	log.Println(connInfo)

	defer conn.Close()

	for {
		request := make([]byte, 4096)

		// クライアント X から通信が来るまで待機する
		readLen, _ := conn.Read(request)

		// クライアントが接続を切った
		if readLen == 0 {
			break
		}

		conn.Write([]byte("[From][Server] Hello! Your message is " + string(request)))
		log.Printf("%s sent to client message: %s", connInfo, string(request))
	}
}
```

## クライアント

https://github.com/ganyariya/playground/blob/main/linux-tcpip/go_socket/cmd/client/main.go

サーバ側のアドレスを示す `serverTcpAddr` を作成し、そのサーバアドレスと通信するための socket を `net.DialTCP` で作成します。

このとき、クライアント側のアドレス（`IP Address + Port`）はクライアントプログラムで指定していないことに注意してください。
クライアントとしては、通信先のサーバのアドレスさえ分かればよいです。
また、サーバ通信用のクライアントポートは `net.DialTCP` 時に割り当てられ、 `*net.netFD` 構造体に port が記載されます。

```go
	/*
		通信先である Server の アドレス (IP Address + Port)
	*/
	serverTcpAddr, _ := net.ResolveTCPAddr(TCP_PROTOCOL, SERVER_TCP_ADDRESS)

	/*
		Server と通信するための Socket (conn) を作成する

		Client 側の アドレス (IP Address + Port) は指定しなくていい = nil
	*/
	conn, _ := net.DialTCP(TCP_PROTOCOL, nil, serverTcpAddr)
```

あとは実際にサーバへ TCP 通信を投げます。

```go
	for {
		var message string
		fmt.Scanln(&message)

		// サーバに送信
		conn.Write([]byte(message))

		// サーバからのレスポンスがくるまで待機
		response := make([]byte, 1000_000)
		readLen, _ := conn.Read(response)

		if readLen == 0 {
			break
		}
		log.Println(string(response))
	}
```

## 動作例

Server プロセスが 1 つ、 Client プロセスが 2 つの場合で実行してみます。
先に Server を起動し、 Client 1, Client 2 を続いて起動します。
その後、 Client 1 が先にメッセージを送り、続いて Client 2 もメッセージを送ります。

```shell:server
❯ go run ./cmd/server
2023/05/16 10:13:44 [Server][Parent] *net.TCPListener Address: 127.0.0.1:12345, fd: 5
2023/05/16 10:13:46 [Server][Child] pid:42856, fd:9, localAddress:127.0.0.1:12345, remoteAddress:127.0.0.1:60189
2023/05/16 10:13:49 [Server][Child] pid:42856, fd:10, localAddress:127.0.0.1:12345, remoteAddress:127.0.0.1:60190
2023/05/16 10:13:56 [Server][Child] pid:42856, fd:9, localAddress:127.0.0.1:12345, remoteAddress:127.0.0.1:60189 sent to client message: Hello!IamClient1
2023/05/16 10:14:07 [Server][Child] pid:42856, fd:10, localAddress:127.0.0.1:12345, remoteAddress:127.0.0.1:60190 sent to client message: Oh!IamClient2...
```

server 親スレッドは `127.0.0.1:12345` で待ち受けており、サーバ待受ソケットのファイルディスクリプタは 5 です。
続いて、 `client1` から接続要求が来て、サーバ待受ソケットがコピーされて `client1` 用の socket ならびに通信用スレッドが作成されます。
`client1` 通信のサーバ socket (net.Conn, netFD) の内容が以下になっていることがわかります。

- raddr = `127.0.0.1:60189`（client 1 の待受ポートが 60189）
- laddr は親スレッドと同じ `127.0.0.01:12345`
- `client1` 通信用のサーバファイルディスクリプタは `9`

`client2` からも同様の接続要求が来て、`client2` 用に通信ソケットならびに通信スレッドを作成します。
ここで、`client2` に割り振られた port は `60190` となっています。

`client1` から `Hello!IamClient1` メッセージが来たときは、それを `127.0.0.1:60189` に返信しています。
`client1` 通信用スレッドは、 `client1` 用 socket のファイルディスクリプタを監視しているため、 `60189` から来た通信データを読み取れるのですね。

```shell:client1
❯ go run ./cmd/client
2023/05/16 10:13:46 [Client] pid:44705, fd:5, localAddress:127.0.0.1:60189, remoteAddress:127.0.0.1:12345
Hello!IamClient1
2023/05/16 10:13:56 [From][Server] Hello! Your message is Hello!IamClient1
```

client1 側の内容を見ると、 `60189` の port が割り振られており、 サーバ `12345` に接続していることがわかりますね。

```shell:client2
❯ go run ./cmd/client
2023/05/16 10:13:49 [Client] pid:46808, fd:5, localAddress:127.0.0.1:60190, remoteAddress:127.0.0.1:12345
Oh!IamClient2...
2023/05/16 10:14:07 [From][Server] Hello! Your message is Oh!IamClient2...
```

# 最後に

socket 通信がどのように行われているかを、以下について触れながら自分なりにまとめてみました。

- ファイル
- ファイルディスクリプタ
- fork / pipe
- socket
- Go 実装

より詳しくなれるように、今度は [`KLab` さんのプロトコル実装](https://drive.google.com/drive/folders/1k2vymbC3vUk5CTJbay4LLEdZ9HemIpZe)をやってみようと思います。

# 参考記事

https://www.amazon.co.jp/Linux%E3%81%A7%E5%8B%95%E3%81%8B%E3%81%97%E3%81%AA%E3%81%8C%E3%82%89%E5%AD%A6%E3%81%B6TCP-IP%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E5%85%A5%E9%96%80-%E3%82%82%E3%81%BF%E3%81%98%E3%81%82%E3%82%81-ebook/dp/B085BG8CH5

https://envader.plus/article/27

https://www.ibm.com/docs/ja/i/7.2?topic=programming-how-sockets-work

http://www.osssme.com/doc/funto45.html

https://milestone-of-se.nesuke.com/sv-basic/linux-basic/fd-stdinout-pipe-redirect/

https://xtech.nikkei.com/it/article/COLUMN/20071031/285990/
