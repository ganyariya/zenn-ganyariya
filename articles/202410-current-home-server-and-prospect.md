---
title: "2024/10 時点における自宅サーバまとめと今後の展望"
emoji: "💭"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["自宅サーバ", "kubernetes", "argocd"]
published: true
---

# はじめに

https://zenn.dev/ganariya/scraps/6c05f030ed1326

2024/09 から 1 台のミニ pc に kubernetes 環境をセットアップし、自宅サーバとして利用しはじめました。
2024/11 からは ISUCON + Unity の勉強がメインになるため、一度ここで現時点の自宅サーバの状態をまとめておきます。

## この記事の目的

2025 の ganyariya が久しぶりに自宅サーバの環境をみたときに、どこまでやったのかを振り返れるようにします。
また、記事にまとめることで現状の自宅サーバへの理解を深めます。

# 2024/10 時点における自宅サーバ

## ノード

https://www.amazon.co.jp/dp/B0C9DNKBQ5

`BMAX` という中国のブランドのミニ PC を 1 台購入して利用しています。
買った当時に入っていた windows のライセンスを確認したところ、よくわからないライセンスだったためすべて削除しました。
その後 ubuntu-server をインストールして利用しています。

n100 のミニ PC は低電力であり、 Kubernetes や Grafana などの勉強をしたいだけの人間にとってはちょうどいいスペックでとてもよかったです。
デスクトップだと幅をとってしまいますし、ガチのベアメタルサーバーだと消費電力がえげつないです。

おひとりさま misskey を動かしたいだけであれば、これぐらいの小さな n100 でちょうどよいですね。

## Kubernetes (k3s)

https://k3s.io/

ミニ PC には k3s という Kubernetes ディストリビューションを入れています。

kubeadm で最初構築したのですがうまく立ち上がらず、メモリや CPU をかなり食いつぶしていました。
そのため、より軽量でシンプルな Kubernetes 環境を探していた結果 k3s に出会いました。

機能も最小限であり、メモリ・ CPU も少量で済むためとてもよかったです。

## ArgoCD

Kubernetes の CI/CD ツールとして ArgoCD を採用しています。

https://argo-cd.readthedocs.io/en/stable/

特徴として、ArgoCD 自体を ArgoCD で管理する構成にしています。

https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/

https://qiita.com/sourjp/items/4547bc81c12286007553

`app` には jenkins, misskey などアプリケーションを用意する kustomize manifests を用意しています。
そのため、 `kubectl apply -k app/overlays/misskey` のようにすれば各アプリを手動で立ち上げられます。

`tools` には ArgoCD の共通設定や、各アプリケーションをデプロイする ArgoCD Application CustomResource を定義しています。

- argocd server manifests
  - argocd 自体の manifest を yaml で管理する
    - github oauth の設定
    - user の設定
- argocd appprojects manifest
- argocd applications manifest
  - application 全体を自動 sync する application
  - argocd 自体を管理する application
  - misskey を管理する application
  - jenkins を管理する application
  - ...

```bash
> tree -d app -d tools -L 3
app
├── bases
│   ├── apache
│   ├── common
│   ├── coredns
│   │   └── conf
│   ├── jenkins
│   │   └── config
│   └── misskey
│       ├── conf
│       └── scripts
└── overlays
    ├── apache
    ├── common
    ├── coredns
    │   └── conf
    ├── jenkins
    │   └── config
    ├── misskey
    └── prometheus-sample-go
tools
├── applications-sync # 各 application を sync する 集約 application
├── bases
│   ├── app
│   │   ├── apache
│   │   ├── common
│   │   ├── coredns
│   │   ├── jenkins
│   │   └── misskey
│   ├── argocd
│   ├── helm
│   │   ├── dashboard
│   │   ├── external-secrets
│   │   ├── kube-prometheus-stack
│   │   ├── loki
│   │   ├── loki-stack
│   │   ├── nfs-subdir-external-provisioner
│   │   └── promtail
│   └── projects
└── overlays
    ├── app
    │   ├── apache
    │   ├── common
    │   ├── coredns
    │   ├── jenkins
    │   └── misskey
    ├── argocd
    │   └── server
    ├── helm
    │   ├── dashboard
    │   ├── external-secrets
    │   ├── kube-prometheus-stack
    │   ├── loki
    │   ├── loki-stack
    │   ├── nfs-subdir-external-provisioner
    │   └── promtail
    └── projects
```


複数の ArgoCD Application を管理する App of apps pattern が便利です。

https://dev.classmethod.jp/articles/argocd-app-of-apps-pattern/

![](https://storage.googleapis.com/zenn-user-upload/49b90d0a6059-20241102.png)

## ExternalSecretsOperator

Kubernetes Secret の管理には ExternalSecretsOperator を利用しています。

https://external-secrets.io/main/

GitOps を行ううえで、シークレットを直接 Git 上で直接管理し、 GitHub に push してしまっていました。
この仕組みだとリポジトリを public にすることは永久に無理だなぁとなり、ExternalSecretsOperator を導入することにしました。

ExtenalSecrets の Store としては Google Cloud Secret Manager を利用しています。
GKE であれば Workload Identity をつかって Secret Manager と簡単に連携できるのですが、ローカルのクラスタだとそれができません。

そのため、GCP の Service Account (JSON Token) を利用した認証にしています。
セキュリティ的にあまりよい運用ではないため、使っているサービスアカウントの権限は Secret Manager の Secret Accessor ロールのみつけています。

https://external-secrets.io/main/provider-google-secrets-manager/#gcp-service-account-authentication

## Misskey

ganyariya のひとり用 misskey を Kubernetes 上にセットアップしています。

https://misskey.ganyariya.dev

cloudflare tunnels を利用することによって `misskey.ganyariya.dev` で自宅サーバの misskey に https で接続できます。
光プロバイダの固定 IP サービスを利用すると毎月 4000 円程度かかってしまいますが、 cloudflare tunnels は無料であり本当に助かります。

![](https://storage.googleapis.com/zenn-user-upload/daa2db6ca247-20241102.png)

## Grafana + Prometheus

kube-prometheus-stack helm chart を利用して、 メトリクスの監視環境を建てています。

![](https://storage.googleapis.com/zenn-user-upload/a0c558962c30-20241102.png)

下記の記事を参考に、簡単な GoWebApp をモニタリングする ServiceMonitor を設定したり AlertRule を設定したところ理解がだいぶ進みました。
Prometheus Operator と CRD, CD のきもちがほんの少しだけわかりました。

https://www.ogis-ri.co.jp/otc/hiroba/technical/kubernetes_use/part5.html

## Loki + Promtail

loki-stack helm chart を利用して、 Pod のログ監視環境を建てています。
scrape_configs はとくに変更しておらず、デフォルトの values.yaml で運用しています。

ServiceDiscovery によって、いい感じに各 pod のログを収集してくれてとても便利です。

## Jenkins

会社で Jenkins を利用しているため、自宅サーバにも jenkins master を建てました。
ただし、 CPU とメモリをとても食うので常に replicas: 0 にしています。

https://plugins.jenkins.io/configuration-as-code/

Jenkins CasC をつかうことで Jenkins のデフォルト設定を YAML (ConfigMap) で管理し、起動時に読み込ませています。
また、プラグインを txt として吐き出し、起動時に jenkins-plugin-cli をつかって install しています。
これによって、手動で必要なプラグインをインストールする、設定を毎回行うを避けられます。

## NFS

現時点ではミニ pc 1 台構成のため、ミニ pc 自体に nfs-server をインストールして PersistentVolume として利用しています。

ゆくゆくは専用の NFS サーバを購入して、そこに画像・音声・動画や, Jenkins のバックアップを残したいですね。

## CoreDNS による家庭内 DNS サーバ（難航中）

家庭内 DNS サーバを kubernetes 上の CoreDNS で建てようとしていますが、うまく DNS 解決がされません。
バッファローの無線 LAN ルータの DNS サーバアドレスに、ミニ PC の CoreDNS の IP アドレスを指定すると、おそらく DNS 問い合わせが無限ループしてしまいます。

そのため現状は CoreDNS での名前解決をやめ、通常通りバッファロー無線 LAN ルータが利用している光プロバイダの DNS サーバを使っています。
かわりに家庭内では mDNS でアクセスすることで一時的にホスト解決をしています。

https://ja.wikipedia.org/wiki/%E3%83%9E%E3%83%AB%E3%83%81%E3%82%AD%E3%83%A3%E3%82%B9%E3%83%88DNS

ISUCON が終わったらちゃんと CoreDNS サーバで家庭内 IP アドレスが解決できるようにしたいなと考えています。

# 今後の展望

今後の自宅サーバでやりたいことの展望です。

## ノベルゲームをリモートでプレイできるようにする

kubernetes 上で wine + vnc が入ったイメージの pod を作成し、ノベルゲームを起動してみたいなと考えています。

windows でしかノベルゲームがプレイできないため、それを k8s 上でうまく起動できないかなという試みです。

## 家庭内 DNS サーバを運用する

先ほどあった CoreDNS の件です。

## メールサーバを建てる

勉強用にメールサーバを建てたいです。
つかう予定はないですが...。

## NAS サーバを建てる

現状ミニ pc 1 台しかないため、この pc が死ぬとすべてのデータが死にます。
といってもバックアップしたいデータといえば misskey の postgres データぐらいですね。

ただ、勉強用 & かっこいいので NAS サーバを 1 台追加してもいいかなと考えています。

## ノード追加を自動化する

現状、以下の作業などは手動です。

- ノードに ubuntu を install する
- k3s を入れる
- dotfiles を入れる
- IP の設定をする

今後ノードを追加するときは Ansible などを利用して自動化したいです。

# 最後に

電気代を心配してなかなか自宅内でのサーバに手を出してきませんでした。
（クラウド使えばいいよね、という考えをずっとしていました。）

ただし、 Kubernetes やその他 o11y の勉強用に小さなミニ pc であれば電気代も一月に 1000 円ぐらいであるためお安めです。
ミニ PC の購入費用と電気代、そして得られる自分の知識を考えるととてもよい買い物だったなと思いました。

今後も少しずつ環境をよくしていきたいですね。
