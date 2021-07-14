---
title: "VSCode のショートカットをいじるときに覚えておくと便利な単語"
emoji: "🦔"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ["vscode"]
published: true
---

# はじめに

VSCode では、ショートカットを自分の好きなようにカスタマイズできます。
このとき、「ペイン」や「エディタ」などの用語を頭に入れておくとカスタマイズしやすいです。

# 用語

https://code.visualstudio.com/docs/getstarted/userinterface

こちらに UI の用語について掲載されています。

![](https://storage.googleapis.com/zenn-user-upload/66203628a05d0bd4554e3526.png)

A は、`Activity Bar` です。
もっとも左側にあるバーであり、アイコンが並んでいます。

B は、`Side Bar` です。
フォルダ一覧や、拡張機能の一覧を表示します。

C は、`Editor Group` です。
上記の画像の例では、左側にエディタグループ 1（C, Untitled 2, 3）、右側にエディタグループ 2（Untitled 1）があります。
1 つのエディタグループには、**複数のエディタ (Editor)**が含まれます。
よって、**editor(エディタ)** は**ある 1 つの入力欄のみ**（ex: Untitled-3）を指しています。
また、**editors=editor group** がエディタの集合（ex: C(Untitled-2,3)）を指しています。
そして、VS Code は、複数のエディタグループを開けます（ex: C と C の右側がそれぞれエディタグループ）。

D は、`Panel` です。
統合ターミナルや出力、デバッグコンソールなどがパネルに含まれています。
エディタと間違いやすいため、注意が必要です。
また、統合ターミナル、出力などのそれぞれの表示欄を `Pane` と呼んでいるようです。

E は、`Status Bar` です。
実行している Python のバージョンや、拡張機能、Vim Mode などが下一覧に表示されます。
ョートカットでどうこうすることはなさそうです。

# 最後に

`Command+K, Command+S` でショートカット一覧を表示できます。
このページで、`Activity Bar` `Side Bar` `Editor` `Editor Group` `Panel` `Pane` を入力すると、よしなにショートカットをカスタマイズできるはずです。
<!-- textlint-disable -->
自分だけの使いやすい VS Code を育てていきましょう！
