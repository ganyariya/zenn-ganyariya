---
title: "Cloud Functions を利用して Misskey の投稿を Twitter にも投稿する"
emoji: "🐦"
type: "tech"
topics: ["misskey", "twitter", "cloudfunctions"]
published: true
---

# はじめに

https://zenn.dev/ganariya/articles/gcp-misskey-instance

先日、 Google Compute Engine の e2-micro インスタンスを利用し misskey の個人インスタンスを建てました。

https://misskey.ganyariya.net/@ganyariya

個人インスタンスを建てた理由としては以下の通りです。

- Twitter を見ると集中力が削がれてしまうため、 Twitter を利用する機会を減らしたかった
- 一方で `ツイート` のような、思っていることや考えていることを世に出すことはしたかった
- misskey 個人インスタンスを建てることによって、自身の情報発信のみ行うことができ、他者の情報によって集中力が削がれない

しかし、 misskey のアカウントを開いてもらわないと ganyariya のことを知ってもらえません。
そこで cloud functions を利用して misskey の投稿を twitter へ自動投稿するようにします。

この記事では上記の自動投稿に関する以下の内容について記載します。

- 使い方
- 構成
- 妥協した部分

# 使い方

https://github.com/ganyariya/misskey-twitter-post

上記 GitHub に cloud functions の go コードをまとめています。
また、 自動投稿するうえでの設定方法を README に記載しています。

Twitter Developer App のアクセストークンに関する設定と cloud functions のデプロイが一番難関かと思います。

# 構成

misskey に Note を投稿したときに、 misskey が webhook を POST します。
この webhook の向き先を cloud functions の HTTP Endpoint に設定します。
あとは cloud functions の関数で twitter API を呼び出しています。

![](https://storage.googleapis.com/zenn-user-upload/b1c7fafbfad6-20230318.png)

# 妥協した部分

## cloud functions の呼び出し認証

https://cloud.google.com/functions/docs/securing/authenticating?hl=ja

cloud functions の呼び出しに関する認証は IAM ロールを用いて行われます。
具体的には、関数を呼び出す際に IAM User もしくは Service Account のアクセストークンを `Authorization: Bearer` として送信します。
すると、 アクセストークンに紐づく IAM ロールが `roles/cloudfunctions.invoker` を持っているかどうかが cloud functions 側で検証されます。
これによって、権限をもつ適切な IAM ユーザのみ関数を呼び出せます。

しかし、今回はこれら IAM を用いた認証を利用しておらず、 `allUsers`、つまり認証なしでリクエストを受け付けています。
理由としては misskey によって送信される Webhook に対してアクセストークンを直接付与できなかったためです。

対策としては misskey が動いている GCE の VM 上で、アクセストークンを付与するだけの web server を作成することです。
つまり、 misskey は一度 `localhost` の web server に通信し、その web server が cloud functions に POST します。

これはかなり面倒なので今回は断念しました。

## 画像つきツイート

misskey で画像が投稿された場合、その画像は twitter に投稿していません。
テキストを twitter へ投稿する前に、あらかじめ media/upload を叩いて以下を行う必要があります。

1. misskey webhook から与えられた画像 url をもとに、画像を `/tmp` にダウンロードする
2. 画像を base64 にデコードする
3. `media/upload`

https://developer.twitter.com/en/docs/twitter-api/v1/media/upload-media/api-reference/post-media-upload

時間があるときに画像の投稿も対応しようと思います。

# 最後に

今は GCE の VM にそのまま乗ってしまっています。 
バックアップなども取っていないため、 VM を誤って削除したらそこで終了です。
今後は GKE や Cloud SQL, MemoryStore などに移していくことも考えていこうと思います。
