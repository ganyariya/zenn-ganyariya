---
title: "git rebase について具体例を用いてうれしさをまとめる"
emoji: "😸"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["git", "rebase"]
published: true
---

# はじめに

先日職場において、とある話題がきっかけで `git rebase` の話題になりました。
このとき ganyariya は「git rebase よくわかってないな...」となりました。

そのため、今回は git rebase について具体例をもちいてまとめようと思います。

# 具体例

ganyariya はノベルゲーム専門のオンライン通販ショップ `ノベストア` を開発しています。
ノベストアでは、さまざまなノベルゲームを通販で販売しています。
ノベストアの開発言語は php7.4 であり、セキュリティの都合上 php8 系へアップデートすることを考えています。

今後のノベストアの開発においては、以下 2 つを並行して進めることにしました。

- php のバージョンをアップデートする
- HTML5&JavaScript ノベルゲームをオンラインで作成・共有できる機能を作成する
  - オンラインでプレイできるノベルゲームをサイト上に追加することで、ユーザ数を増やしたい

# git rebase

![](https://storage.googleapis.com/zenn-user-upload/1d307633825b-20230811.png)

現在、ノベストアはリリース済みであり、コミットするたびに自動テストが行われるようになっています。

---

![](https://storage.googleapis.com/zenn-user-upload/b4bd03414764-20230811.png)

```shell
# main から checkout
git checkout -b feature/php8-update
```

ganyariya-A さんは php8 のアップデートブランチを作成し、アップデートの準備をしています。
はじめは php8.0 にアップデートする予定でしたが、できるだけあげようという方針に変更され php8.2 へ上げることにしました。

---

![](https://storage.googleapis.com/zenn-user-upload/d33b7f590d02-20230811.png)

```shell
# main から checkout
git checkout -b feature/online-novel-game-share
```

ganyariya-B さんは、 php8 アップデートではなく、HTML5 ノベルゲームをオンラインで公開できる機能を作成しました。
php8 アップデート作業は難航している、かつ失敗すると事業的影響が大きいため、先にオンライン公開機能を本番リリースすることになりました。

---

![](https://storage.googleapis.com/zenn-user-upload/1eec7dc95fcf-20230811.png)

```shell
git checkout main
git merge feature/online-novel-game-share
```

main ブランチに `feature/online-novel-game-share` をマージして本番デプロイしました。

---

![](https://storage.googleapis.com/zenn-user-upload/c0f267b4fc27-20230811.png)

ganyariya-A さんは、まだまだ php8 アップデートの作業が残っています。
CI/CD を php8 対応させたり、 Dockerfile も php8 対応させる必要があります。

ここで、 ganyariya-A さんは main ブランチ側で「オンライン公開機能」がすでにリリースされていることに気づきました。
上記の機能を php8 ブランチに取り込み、 php8 ランタイムでもうまく動くか確認する必要があります。

このとき、普段つかっている `merge` にくわえて、 `rebase` で取り込む方法も試してみることにしました。

```shell
git checkout feature/php8-update
git checkout -b feature/php8-update-merge
git checkout -b feature/php8-update-rebase
```

---

![](https://storage.googleapis.com/zenn-user-upload/7bbe9f268618-20230811.png)

```shell
git checkout feature/php8-update-merge
git merge main
```

まずは普段使っている `merge` の方法です。

`feature/php8-update-merge` に `main` を取り込んだところ、マージコミット `8456b075` が作成されました。

`feature/php8-update-merge` のコミット履歴を見ると、`php8 アップデート` がより過去にコミットされており、そののちに `ノベルゲーム公開機能` がコミットされています。

歴史的経緯としては `php8 アップデート`を ganyariya-A が行ってから、 ganyariya-B が `ノベルゲーム公開機能` を行っているため正しいです。


![](https://storage.googleapis.com/zenn-user-upload/9f51af570ca2-20230811.png)
![](https://storage.googleapis.com/zenn-user-upload/47e84fa37443-20230811.png)

しかし、今後も php8 アップデート作業が長期化し、その間にリリースされたノベストア機能コードを `feature/php8-update-merge` へマージするたびにコミット履歴が汚くなります。
上記 2 枚の画像では、ノベストア機能コードを適宜 `feature/php8-update-merge` にマージしていったときのコミット履歴です。

php8 と機能開発コミットが時系列順に混ざって表示されており、どのコミットが php8 に関するものなのか分かりづらくなってしまいます。

---

![](https://storage.googleapis.com/zenn-user-upload/a238b30fca34-20230811.png)

一方で、 `rebase` では `re base` (ベースをつけかえる) という名の通り、**コミット履歴を改ざんします**。

```shell
git checkout feature/php8-update-rebase
git rebase main
```

`feature/php8-update-rebase` で行われていたコミット操作が **`あたかも main ブランチ上で作業していた` かのようにコミットが付け替えられます**。

もともとの php8 アップデートは `99e99aa6` から `21fb92b9` のコミットでした。
これを `main` 側につけかえることによって、あらたに `0956a274` から `a17e97f8` というコミットが git 側で自動作成されています。

この自動コミット付け替えによって、あたかも `オンライン公開機能が作成されてから php8 アップデート作業をはじめた` かのようなコミット履歴を作成できます。

![](https://storage.googleapis.com/zenn-user-upload/301c08ac7274-20230811.png)

ノベストア機能開発がどんどん進んでいたとしても、 上記の画像のように rebase できれいなコミット履歴を作れます。

## git rebase -i

rebase 操作でよく使う `git rebase -i` についても記載します。

![](https://storage.googleapis.com/zenn-user-upload/90a35dc281bf-20230811.png)

php8 アップデート作業を ganyariya-A が行っていたところ、ローカル環境における phpunit テストが落ち続けるようになりました。
phpunit テストが落ち続ける原因はなんなのか、色々な箇所をコミットしながらテストが動くまで試行錯誤しました。
結果として、phpunit に与えるメモリが足らなかったとわかり、メモリを多く与えることで解決しました。

しかし、ここまでの試行錯誤においてコミット履歴がだいぶ汚れてしまいました。
そこで、直近の phpunit 試行錯誤のコミットを `git rebase -i` できれいにすることを目指しました。

---

```shell
git checkout feature/php8-update-rebase
git checkout -b feature/php8-update-rebase-i
git rebase -i main
```

`git rebase -i main` で `feature/php8-update-rebase-i` のコミットを `main` 上であたかも行ったように見せかけるコミット改ざんを行います。
また、 `-i (interactive)` オプションによってコミットごとにどのように操作するかを指定できます。

![](https://storage.googleapis.com/zenn-user-upload/b827a804eca5-20230811.png)

今回は `7619443` と `42a8596` で行った操作を `ed2e088` コミットに `squash` (押しつぶして混ぜる)ことにしました。
これによって、README の追加や php8.2 へのアップデートを 1 つのコミットにまとめられます。

また、 unittest 系の試行錯誤は必要ないと判断したため、 `drop` でコミットを削除することにしました。

`047374e` に `reword` を指定することで、 `phpunit に与えるメモリを増やす` というコミットメッセージへ修正することにしました。

![](https://storage.googleapis.com/zenn-user-upload/dad48d30fa0c-20230811.png)

このように `rebase -i` を指定することで、単純に base を付け替えるだけでなく、どのコミットを利用するのかなどを編集できます。
これによって、コミット履歴をよりきれいに保てます。

# 注意

ここまでの通り、 `git rebase` はコミット履歴を改ざんする操作になっています。
そのため、すでに GitHub の PullRequest に branch を push しているなど、他の人と共有するブランチを rebase するのは危険が高いです。
なにかコンフリクトした場合、うまく解決する必要が出てきます。

安全に `rebase` をしたいのであるならば、自分のローカル環境のみで `rebase` を行い、 origin 上では行わないのが安全かと思います。

自分の場合は rebase する場合、以下にするように気をつけています。

- 他の人の commit は rebase しない。 rebase 対象は自分のコミットのみ。
- 一度でも origin に push したものは rebase しない。
- つまり、 rebase していいものは自分のコミット、かつ origin に push していないもの。

https://www.zoma-blog.com/post/other/git/20230222_git_rebase_avoid/

# 参考リンク

https://git-scm.com/book/ja/v2/Git-%E3%81%AE%E3%83%96%E3%83%A9%E3%83%B3%E3%83%81%E6%A9%9F%E8%83%BD-%E3%83%AA%E3%83%99%E3%83%BC%E3%82%B9

https://zenn.dev/tana0102/articles/475d8952933af6

https://style.biglobe.co.jp/entry/2022/03/22/090000
