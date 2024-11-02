---
title: "自宅サーバの Kubernetes に Misskey を建ててインターネットからアクセスできるようにする"
emoji: "🦁"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["kubernetes", "misskey", "cloudflare"]
published: true
---

# はじめに

https://zenn.dev/ganariya/articles/202410-current-home-server-and-prospect

https://misskey.ganyariya.dev/

ganyariya ひとり用の Misskey を自宅サーバの Kubernetes 上に建てて運用しています。

この記事では Kubernetes に Misskey を建てる際の一例として構成やマニフェストを紹介します。
（そのまま参考にはならないためご注意ください。 自分の環境にあわせて適宜修正する必要があります。）

## 参考記事

Misskey のセットアップ時は以下の記事を参考にさせていただきました。
ありがとうございました。

https://4nm1tsu.com/posts/4pdgkbc/

# 背景（自宅サーバの環境）

N100 intel CPU のミニ PC 1 台のみの構成で自宅サーバとして運用しています。
電気代を抑えたい & 場所を取りたくないため、ミニ PC 1 台のみです。

該当のミニ PC に ubuntu server を入れて、そのうえに k3s (Kubernetes Distribution) を導入しています。

k8s には以下を導入しています。

- ArgoCD
  - GitOps による k8s CI/CD ツール
- ExternalSecretsOperator
  - k8s Secret を外部ストアに保存できる Custom Operator

そのため、 Misskey のマニフェスト構成に ArgoCD と ExternalSecretsOperator を利用しています。
よって、後続の Manifest にはこれらが要素として出てきます。

# 構成図

![](https://storage.googleapis.com/zenn-user-upload/4af1d373e0d8-20241102.png)

ganyariya Misskey の構成図をあらかじめ示しておきます。

Misskey 自体は 3 つの Deployment で構成しています。

- Postgres (DB)
- Redis (Cache)
- Misskey (本体)

Misskey Server が Postgres や Redis と内部的に通信しています。
これら内部的な通信のために Kubernetes Service (ClusterIP) を用意し、それらを介して通信します。

しかしこのままではこの Misskey をインターネット上に公開できず、 ganyariya の自宅ローカル環境でしか見れません。

対応策として、インターネット上の第三者も Misskey を見れるように Cloudflare Tunnels を利用しています。
`ganyariya 家庭内 cloudflared pod` と `cloudflared エッジサーバ` がそれぞれ通信することでトンネリングを行います。
これによって `misskey.ganyariya.dev` への通信が家庭内への Misskey pod まで届くようになります。 

https://www.cloudflare.com/ja-jp/products/tunnel/

各種 Deployment で利用したいシークレットは ExternalSecrets を利用して Google Cloud Secret Manager に保存しています。

画像などのメディアオブジェクトについては Cloudflare R2 を利用しています。
これによって、自宅サーバの misskey の負担を減らし、 Cloudflare CDN を活用できます。

# Manifest

## Namespace

```yaml:namespace.yaml
kind: Namespace
apiVersion: v1
metadata:
  name: misskey
```

## Redis

Redis のバックアップデータを保存するために PersistentVolume を定義しています。
ただし、キャッシュ用途でしかないためバックアップする必要はなさそうです（今思うと PV & PVC はいらない）。

```yaml:redis.yaml
kind: Service
apiVersion: v1
metadata:
  name: redis-svc
spec:
  selector:
    app: redis-server
  ports:
    # http という名前をつける
    - name: http
      port: 6379
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: redis-pv
spec:
  capacity:
    storage: 500Mi
  accessModes:
    - ReadWriteMany
  # 環境によって使いたいストレージクラスを変更します
  storageClassName: local-storage
  nfs:
    path: PlaceHolder
    server: PlaceHolder
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            # node.label に kubernetes.io/hostname=ganyariya-ubuntu が入っているノードを選択する
            - key: kubernetes.io/hostname
              operator: In
              values:
                - ganyariya-ubuntu
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: redis-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: local-storage
  resources:
    requests:
      storage: 500Mi
  volumeName: redis-pv
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-server
  template:
    metadata:
      labels:
        app: redis-server
    spec:
      containers:
        - name: redis
          image: redis:7
          resources:
            limits:
              memory: "200Mi"
              cpu: "200m"
          ports:
            # redis は 6379 ポートで通信を待ち受けておく
            # misskey server がアクセスしてくる
            - containerPort: 6379
          volumeMounts:
            - name: redis-volume
              # 定期的に dump.rdb が /data に書き込まれる
              mountPath: /data
      volumes:
        - name: redis-volume
          persistentVolumeClaim:
            claimName: redis-pvc
```

## Postgres

Misskey のデータを保存する Postgres を Deployment で建てています。

こちらも今思うと StatefulSet として建てたり Postgres Operator で建てたほうが良かったです。
ただ、Kubernetes における Database の永続化をどうすべきか詳しくないため、いったん Deployment のままにしています。

PersistentVolume に Misskey の Postgres データを保存しています。
しかし、このままだと PersistentVolume もしくは PersistentVolume に紐づくデータを失ってしまうと復元できません。
そのための対策として、Postgres のバックアップを CronJob で行います（後述）。

Posgres のシークレット情報については後述します。

```yaml:postgres.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-svc
spec:
  selector:
    app: postgres-server
  ports:
    - name: http
      port: 5432
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  storageClassName: local-storage
  nfs:
    path: PlaceHolder
    server: PlaceHolder
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - ganyariya-ubuntu
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: local-storage
  resources:
    requests:
      storage: 1Gi
  volumeName: postgres-pv
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-server
  template:
    metadata:
      labels:
        app: postgres-server
    spec:
      containers:
        - name: postgres
          image: postgres:15
          resources:
            limits:
              memory: "500Mi"
              cpu: "500m"
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: postgres-volume
              mountPath: /var/lib/postgresql/data
          envFrom:
            - secretRef:
                name: misskey-postgres-secret
      volumes:
        - name: postgres-volume
          persistentVolumeClaim:
            claimName: postgres-pvc
```

## Misskey Server

Misskey Server は `misskey/misskey` イメージを使って建てています。
起動時に migrateandstart を実行して misskey 実行の準備をしています。

mac から ubuntu-server の misskey にアクセスできるように NodePort Service を使っています。
ubuntu-server は 192.168.11.100 の固定 IP が割り当てられているため、 `192.168.11.100:30100` で Misskey へアクセスできるようにしています。

Misskey 設定 YAML は `misskey-default-yaml-secret` に記載し、それを `/misskey/.config/default.yaml` にマウントしています。
misskey-default-yaml-secret をどう生成しているかについては次の節で後述します。

```yaml:misskey-web.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  type: NodePort
  selector:
    app: web
  ports:
    # 192.168.11.1100:30100 に通信が来たら kube-proxy が 10.43.34.210:3003 (clusterIP) にリクエストを送信する
    # その後 clusterIP は misskey pod 3000 ポートに向かって通信をおくる
    - name: http
      protocol: TCP
      # clusterIP は 3003 で待ち受ける
      port: 3003
      # misskey pod 自体は 3000 で通信を待ち受けている
      # そのため misskey pot 3000 ポートにむかって通信する
      targetPort: 3000
      # 192.168.11.1100:30100 で misskey に通信できるようにする
      nodePort: 30100
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: misskey-server-container
          image: misskey/misskey:latest
          ports:
            - containerPort: 3000
          resources:
            limits:
              cpu: "1"
              memory: "2Gi"
          # migrateandstart を実行して用意する
          command: ["pnpm", "run", "migrateandstart"]
          volumeMounts:
            - name: misskey-files
              mountPath: /misskey/files
            - name: misskey-default-yaml-config
              mountPath: /misskey/.config
      volumes:
        - name: misskey-files
          persistentVolumeClaim:
            claimName: misskey-files-pvc
        - name: misskey-default-yaml-config
          secret:
            secretName: misskey-default-yaml-secret
            items:
              - key: misskey-default.yml
                path: default.yml
```

画像などのメディアファイルを保存する PV です。
なお、 Cloudflare r2 を利用するため、実際に使っているのは最初だけです。

```yaml:misskey-files.yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: misskey-files-pv
spec:
  storageClassName: misskey-files-class
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  nfs:
    path: PlaceHolder
    server: PlaceHolder
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - ganyariya-ubuntu
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: misskey-files-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: misskey-files-class
  resources:
    requests:
      storage: 1Gi
```

## Misskey 設定ファイル

Postgres と Misskey の設定ファイルは ExternalSecrets で管理しています。

具体的には、設定ファイル YAML 自体は Cloud Secret Manager に管理されています。
その内容を ExternalSecretsOperator が動的に取得して k8s Secret に変換しています。

![](https://storage.googleapis.com/zenn-user-upload/c34312e0edf4-20241102.png)

```yaml:external-secrets.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: misskey-postgres-external-secret
spec:
  refreshInterval: 6h
  secretStoreRef:
    kind: ClusterSecretStore
    name: cluster-gcp-secret-store
  target:
    # 作成する k8s secret 名
    name: misskey-postgres-secret
    creationPolicy: Owner
  dataFrom:
    - extract:
        # gcp 上の secret manager secret 名
        key: misskey-postgres-secret
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: misskey-default-yaml-external-secret
spec:
  refreshInterval: 6h
  secretStoreRef:
    kind: ClusterSecretStore
    name: cluster-gcp-secret-store
  target:
    # 作成する k8s secret 名
    name: misskey-default-yaml-secret
    creationPolicy: Owner
  data:
    - secretKey: misskey-default.yml
      remoteRef:
        # gcp 上の secret manager secret 名
        key: misskey-default-yaml-secret

```

各種設定ファイルは misskey のデフォルト設定に少しアレンジを加えた内容です。
その部分のみ抜粋します。

Posgres の環境変数と Misskey default.yaml で設定する内容は揃えるようにします。

```yaml:default.yaml
url: https://misskey.ganyariya.dev/

# misskey pod が動作する port
port: 3000

db:
  # misskey server → postgres に通信する
  host: misskey-postgres-svc.misskey.svc.cluster.local
  port: 5432

  db: misskey

  user: misskey-sample-postgres-user
  pass: misskey-sample-postgres-password

redis:
  # misskey server → redis に通信する
  host: misskey-redis-svc.misskey.svc.cluster.local
  port: 6379
```

```json:misskey-postgres-secret
{
  "POSTGRES_USER": "misskey-sample-postgres-user",
  "POSTGRES_PASSWORD": "misskey-sample-postgres-password",
  "POSTGRES_DB": "misskey"
}
```

## Cloudflare Tunnels

https://developers.cloudflare.com/cloudflare-one/tutorials/many-cfd-one-tunnel/

あらかじめに上記の公式ドキュメントによるセットアップを済ませておく必要があることに注意が必要です。

その後、Cloudflare Tunnels を Kubernetes Deployment として起動します。
そして Cloudflare エッジサーバと Misskey Pod を繋ぐことで、インターネットから Misskey へアクセスできるようにします。

```yaml:cloudflared.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared
spec:
  selector:
    matchLabels:
      app: cloudflared
  replicas: 2
  template:
    metadata:
      labels:
        app: cloudflared
    spec:
      containers:
        - name: cloudflared
          image: cloudflare/cloudflared:2022.3.0
          args:
            - tunnel
            - --config
            - /etc/cloudflared/config/config.yaml
            - run
          livenessProbe:
            httpGet:
              path: /ready
              port: 2000
            failureThreshold: 1
            initialDelaySeconds: 10
            periodSeconds: 10
          volumeMounts:
            # /etc/cloudflared/config/config.yaml を配置する
            - name: config
              mountPath: /etc/cloudflared/config
              readOnly: true
              # /etc/cloudflared/creds/credentials.json を配置する
            - name: creds
              mountPath: /etc/cloudflared/creds
              readOnly: true
      volumes:
        - name: creds
          secret:
            # https://developers.cloudflare.com/cloudflare-one/tutorials/many-cfd-one-tunnel/#upload-the-tunnel-credentials-file-to-kubernetes
            # 上記で設定した k8s secret を指定する
            # この k8s secret は key=credentials.json に cloudflare tunnels の 秘密鍵をもっている
            secretName: misskey-tunnel-credentials
        - name: config
          configMap:
            name: cloudflared-config-cm
            items:
              - key: cloudflared-config.yml
                path: config.yaml
```

Cloudflared で利用する設定は ConfigMap として用意しています。

Misskey の Service の ClusterIP は 3003 です。
そのため、 `ingress.[0].service` に `http://misskey-web-svc.misskey.svc.cluster.local:3003` を設定しています。
これによって cloudflared がトンネリングしたい通信を misskey-web-svc.xxx:3003 と伝えられます。

```yaml:kustomization.yaml
configMapGenerator:
  - name: cloudflared-config-cm
    files:
      - conf/cloudflared-config.yml
```

```yaml:conf/cloudflared-config.yml
tunnel: misskey-tunnel
credentials-file: /etc/cloudflared/creds/credentials.json
metrics: 0.0.0.0:2000
no-autoupdate: true
ingress:
  # 上記で指定した host 名を指定する
  - hostname: misskey.ganyariya.dev
    # misskey-web-svc の 3003 port で misskey が待ち受けている
    service: http://misskey-web-svc.misskey.svc.cluster.local:3003
  # This rule sends traffic to the built-in hello-world HTTP server. This can help debug connectivity
  # issues. If hello.example.com resolves and tunnel.example.com does not, then the problem is
  # in the connection from cloudflared to your local service, not from the internet to cloudflared.
  - hostname: hello.example.com
    service: hello_world
  # This rule matches any traffic which didn't match a previous rule, and responds with HTTP 404.
  - service: http_status:404
```

Tunnels で利用する Secret は Misskey と同様に ExternalSecrets で管理しています。

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: misskey-tunnel-external-secret
spec:
  refreshInterval: 6h
  secretStoreRef:
    kind: ClusterSecretStore
    name: cluster-gcp-secret-store
  target:
    # misskey-tunnel-credentials という secret が作成される
    name: misskey-tunnel-credentials
    creationPolicy: Owner
  data:
    # ----- misskey-tunnel-credentials -----
    # apiVersion: v1
    # data:
    #   credentials.json: ++++++++
    - secretKey: credentials.json
      remoteRef:
        # misskey-tunnels-secret は GCP Cloud Secret Manager の secret 名
        key: misskey-tunnels-secret
```

```json:misskey-tunnels-secret
{"AccountTag":"xxxxx","TunnelSecret":"xxxxxxxxxx","TunnelID":"xxxxxxxxxx"}
```

## バックアップ

Postgres を dump して別の PV に保存する CronJob を用意しています。

面倒なので、別の PV に保存するだけで済ませています。
やる気があるときに Google Cloud Storage など、クラウドストレージにバックアップするスクリプトも追加したいなと考えています。

```yaml:backup.yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: postgres-backup-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  nfs:
    path: PlaceHolder
    server: PlaceHolder
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - ganyariya-ubuntu
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: postgres-backup-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 1Gi
  volumeName: postgres-backup-pv
---
kind: CronJob
apiVersion: batch/v1
metadata:
  name: postgres-backup-cronjob
spec:
  # AM 2 時に バックアップを実行する
  schedule: "0 02 * * *"
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: postgres-backup
              image: postgres:15
              command:
                - bash
                - /scripts/backup_postgres.sh
              resources:
                limits:
                  memory: "100Mi"
                  cpu: "100m"
              envFrom:
                - secretRef:
                    name: misskey-postgres-secret
              volumeMounts:
                - name: postgres-backup-volume
                  mountPath: /backup
                - name: misskey-custom-scripts-volume
                  mountPath: /scripts
          volumes:
            - name: postgres-backup-volume
              persistentVolumeClaim:
                claimName: postgres-backup-pvc
            - name: misskey-custom-scripts-volume
              configMap:
                name: misskey-custom-scripts-cm
```

```bash:scripts/backup_postgres.sh
#!/bin/bash

set -eu

mkdir -p /backup

FILENAME="/backup/misskey-backup-$(date +"%Y%m%d%H%M%S").sql"

PGPASSWORD="$POSTGRES_PASSWORD" pg_dumpall \
    --host=misskey-postgres-svc \
    --username="$POSTGRES_USER" \
    | gzip > "$FILENAME.gz"

echo "$FILENAME backup complete!"
```

# Cloudflare r2

画像などのメディアファイルを Cloudflare r2 に保存しています。
以下の記事などが参考になります。

https://qiita.com/hihumikan/items/1f692f3bd5516820e0ec

自分が行った Cloudflare r2 の設定を画像にまとめました。
同じ色の箇所を Cloudflare 側からコピーして Misskey 側に入力します。

![](https://storage.googleapis.com/zenn-user-upload/247b93c507d1-20241102.png)

# 最後に

Misskey を Kubernetes + Cloudflared Tunnels で建てました。
なにかしらの参考になれば幸いです。

データのバックアップを GCS に行ったり、 PersistentVolume や Postgres まわりを改善できないか考えてみようと思います。
