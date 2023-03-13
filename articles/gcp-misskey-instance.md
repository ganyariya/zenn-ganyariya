---
title: "GCP で小さな misskey インスタンスを建ててみる"
emoji: "🤖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["misskey", "gcp"]
published: true
---

# 概要

https://misskey.ganyariya.net/@ganyariya

GCP の以下のサービスを利用して小さな個人 misskey インスタンスを建てました。

- Google Domains (`ganyariya.net` のドメインを取得)
- Google Compute Engine
  - e2-micro (無料枠)

e2-micro という無料枠のインスタンスでも、スワップファイルを利用すれば misskey をビルド & 実行できました。
そのため、`個人用` という上では e2-micro で問題なさそうです（複数人利用では当然厳しいですね）。

# misskey

misskey の概要については以下です。

https://misskey-hub.net/

今回は公式で提供されている bash script を利用しています。

https://misskey-hub.net/docs/install/bash.html

## 建て方

### ドメイン取得

https://domains.google/intl/ja_jp/

はじめに Google Domains で `ganyariya.net` というドメインを取得しました。
これまでは費用がかかるのでドメインを持っていませんでしたが、一年 1400 円は毎月かかるサブスクより安いので購入しました。

あとで GCE で e2-micro を建てるときに、静的外部 IP アドレスを予約し DNS に A レコードを登録します。

### e2-micro を建てる

GCP のプロジェクトでおもむろに e2-micro を建てます。
建てるときは以下のことに注意して作成しました。

- `e2-micro` を選択する（無料枠なので）
  - `region` は `us-central` を指定しました。通信は遅くなりますが、無料枠が米国のリージョンしか（一部を除く）適用されません。
- `ubuntu` を利用する
  - https://misskey-hub.net/docs/install/bash.html
  - 上記の bash script は `ubuntu` os を想定しています。 debian などを選択すると docker のインストールがうまくいかなかったので ubuntu にしました（いろいろ工夫すればできるのでしょうが、公式に添います）。
- HTTP, HTTPS のファイアウォールを許可する

![](https://storage.googleapis.com/zenn-user-upload/5eaabcc8c60f-20230313.png)

![](https://storage.googleapis.com/zenn-user-upload/7b4a9e4ff481-20230313.png)

![](https://storage.googleapis.com/zenn-user-upload/f4a5e5c5c6a7-20230313.png)

![](https://storage.googleapis.com/zenn-user-upload/9c9ef98bf246-20230313.png)

その後、 Google Domains で DNS に A レコードとして、e2-micro の静的 IP アドレスを登録しました。

### misskey のインストール

e2-micro に ssh でログインし、あとは公式サイトの bash-script を走らせます。

https://misskey-hub.net/docs/install/bash.html

`Systemd or Docker?` では Docker を選択し、 DockerHub から misskey の公式イメージを取得して利用しています。

`nginxを使うか` では nginx を利用する設定にしています。
Google の HTTP(S) ロードバランサを利用すると料金がかかってしまうので、 nginx そのまま利用です。

`Add more swaps!` では特になにも設定せず bash script を走らせました。
script 内でインスタンスの RAM メモリをチェックし、足りないのであれば自動でスワップファイルを作成してくれました。

Cloudflare はこの時点では利用しない設定にしています。

<!-- textlint-disable -->

:::details 実行ログ

```
ganyariya@misskey:~$ wget https://raw.githubusercontent.com/joinmisskey/bash-install/main/ubuntu.sh -O ubuntu.sh; sudo bash ubuntu.sh
--2023-03-12 06:54:10--  https://raw.githubusercontent.com/joinmisskey/bash-install/main/ubuntu.sh
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 185.199.108.133, 185.199.109.133, 185.199.110.133, ...
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|185.199.108.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 26637 (26K) [text/plain]
Saving to: ‘ubuntu.sh’

ubuntu.sh                                             100%[======================================================================================================================>]  26.01K  --.-KB/s    in 0.003s

2023-03-12 06:54:11 (8.62 MB/s) - ‘ubuntu.sh’ saved [26637/26637]


Misskey auto setup for Ubuntu
 v3.0.0

Check: Linux;
        OK.
Check: root user;
        OK. I am root user.
Check: arch;
        x86_64 (amd64)

Install Method
Do you use systemd to run Misskey?:
Y = To use systemd / n = To use docker
[Y/n] > n
Use Docker.
Determine the local IP of this computer as docker host.
The IPs that are supposed to be available are as follows (the result of hostname -I)
        10.128.0.4
> 10.128.0.4
The host name of docker host to bind with 'docker run --add-host='.
> docker_host
Do you use image from Docker Hub?:
Y = To use Docker Hub image / N = To build Docker image in this machine
[Y/n] > Y
Use Docker Hub image.
Enter repository:tag of Docker Hub image:
> misskey/misskey:latest
Misskey setting

Enter the name of user with which you want to execute Misskey:
> misskey

Enter host where you want to install Misskey:
> misskey.ganyariya.net
OK, let's install misskey.ganyariya.net!

Nginx setting
Do you want to setup nginx?:
[Y/n] > Y
Nginx will be installed on this computer.
Port 80 and 443 will be opened by modifying iptables.

Do you want it to open ports, to setup ufw or iptables?:
u = To setup ufw / i = To setup iptables / N = Not to open ports
[u/i/N] > u
OK, it will use ufw.
SSH port:
> 22

Certbot setting
Do you want it to setup certbot to connect with https?:
[Y/n] > Y
OK, you want to setup certbot.

Cloudflare setting
Do you use Cloudflare?:
[Y/n] > n
OK, you don't use Cloudflare.
Let's encrypt certificate will be installed using the method without Cloudflare.

Make sure that your DNS is configured to this machine.

Enter Email address to register Let's Encrypt certificate
> your-email@your.email.com
Tell me which port Misskey will watch:
Misskey port:
> 3000

Database (PostgreSQL) setting
Do you want to install postgres locally?:
(If you have run this script before in this computer, choose n and enter values you have set.)
[Y/n] > Y
PostgreSQL will be installed on this computer at docker_host:5432.
Database user name:
> misskey
Database user password:
> your-misskey-postgres-password
Database name:
> mk1

Redis setting
Do you want to install redis locally?:
(If you have run this script before in this computer, choose n and enter values you have set.)
[Y/n] > Y
Redis will be installed on this computer at docker_host:6379.
Redis password:
> your-misskey-redis-password

OK. It will automatically install what you need. This will take some time.

Check: Memory;
        NG. This computer doesn't have enough RAM (>= 2GB, Current 1GB).
        Swap will be made (1M x 2048).
2048+0 records in
2048+0 records out
2147483648 bytes (2.1 GB, 2.0 GiB) copied, 19.2937 s, 111 MB/s
mkswap: /swap: insecure permissions 0644, 0600 suggested.
Setting up swapspace version 1, size = 2 GiB (2147479552 bytes)
no label, UUID=04ad3a69-a009-49d4-9b40-a7029ed7841a
swapon: /swap: insecure permissions 0644, 0600 suggested.
              total        used        free      shared  buff/cache   available
Mem:         989176      156104       68144         932      764928      676600
Swap:       2097148           0     2097148
Total:      3086324      156104     2165292
Process: add misskey user (misskey);
Process: apt install #1;

```

:::

<!-- textlint-enable -->

### 初期設定

上記スクリプトが実行されたら、 `misskey.ganyariya.net` で misskey ページを確認できました。
DNS の設定もうまくいっているようです。

あとは管理者アカウントを作りサーバ名設定などを行いました。

1 件発生した問題としては、プロフィール画像のようなアセットがアップロードできないという問題でした。
github の issue を覗いた感じでは、画像などがアップロードされる `files` ディレクトリの権限が headless docker のユーザと `misskey` ユーザでずれているようです。

今回は手軽な方法として `777` パーミッションに変更しました。
bash スクリプトを再度見て、何が原因で発生しているのか確認しようと思います。

```bash
# 以下のディレクトリ
# /home/misskey/misskey/files

sudo chmod 777 /home/misskey/misskey/files
```

### cloudflare

上記までで GCE インスタンスで misskey インスタンスを建てられましたが、 CDN キャッシュをしていないため、公式通り Cloudflare を導入しました。
Cloudflare のアカウントを作成し、 Google Domains でカスタムネームサーバを設定して `ganyariya.net` を Cloudflare で扱えるようにしました。

よく考えたら、 GCP の Cloud CDN で良かったですね（無料枠はないはずなので、free プラン無料で cdn が使える cloudflare のほうがいいのか）。
