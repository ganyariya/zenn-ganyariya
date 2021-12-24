---
title: "VSCode の起動時間 高速化の荒業"
emoji: "👏"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["vscode"]
published: true
---

# はじめに

この記事は Visual Studio Code Advent Calendar 2021 の 25 日目の記事です。

https://qiita.com/advent-calendar/2021/vscode

10 日目にも記事を書いているので、ぜひ読んでもらえると嬉しいです。

https://zenn.dev/ganariya/articles/tmux-like-vscode

みなさんは VSCode の拡張機能を使っていますか。
VSCode には様々な拡張機能があり、つい色々と追加してしまいます。
その結果、 たくさんの拡張機能が溜まり、エディタが完全に起動するまで 10s ほどかかってしまいます。

というわけで、自分の VSCode 環境の起動時間を高速化した荒業を段階的にまとめます。

# 1: 使わないものを削除する

心惜しいですが、使わない・起動に時間がかかるものは削除していきましょう。
VSCode では、起動にかかる時間を拡張機能ごとに表示してくれます。
また、コマンドパレットで `Developer:Show Running Extensions` を打つと起動にかかる時間順で表示してくれます。
これらを参考に削除していきます。

![](https://storage.googleapis.com/zenn-user-upload/58815cb58f07-20211224.png)

![](https://storage.googleapis.com/zenn-user-upload/36727f515398-20211224.png)


# 2: 全体で使用しない拡張機能を無効化する

使わない・遅いものを削除してもまだまだ遅いことがあります。
このような場合の次の手段として、全体で使わない拡張機能を無効化してあげるとよさそうです。

たとえば、以下の画像に載っている拡張機能については、全体で無効化しています（画像の下に本当はまだ続いています）。
$\LaTeX$ プロジェクトや、 C++ プロジェクトなど、特定のプロジェクトのみでしか使わない拡張機能であるためです。
また、 Live Server, Live Share なども常に使うというわけではないので無効化しています。

![](https://storage.googleapis.com/zenn-user-upload/b28709a449e8-20211224.png)

# 3: ワークスペースごとに拡張機能を有効化する

2 で無効化してしまった拡張機能を使うことはできません。
無効化してしまったためです（当たり前ですね）。

ということで、ワークスペースごとに追加で利用する拡張機能を有効化してあげます。
拡張機能欄で無効になっているものを右クリックして、`有効にする（ワークスペース）` を選択すればよいです。

![](https://storage.googleapis.com/zenn-user-upload/718e2d0101e1-20211224.png)

ただし注意点として、これらワークスペースで有効化した拡張機能などの情報は `.vscode/settings.json` には保存されません。
ローカルの PC の設定フォルダに sqlite のデータとして保存されるようです。
そのため、 PC ごとに有効化をしてあげる必要があります。

以下の Issue で議論されているようなので、今後 settings.json で切り替えられるようになるといいですね。

https://github.com/microsoft/vscode/issues/40239
