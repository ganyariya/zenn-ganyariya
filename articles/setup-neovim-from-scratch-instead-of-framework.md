---
title: "フレームワークをやめて 1 から neovim をセットアップしたら理解がとても進んだという話"
emoji: "📚"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ["neovim", "astronvim"]
published: true
---

# この記事で伝えたいこと

AstroNvim というフレームワークを使っていましたが、カスタマイズのやり方がよくわからず結局 vscode を使い続けてしまっていました。
しかし、 lazynvim をもとに 1 から neovim をセットアップしたことで理解が進んで自分がこうしたいな〜というカスタマイズができるようになり、とてもよかったです。

そのため、本記事は「フレームワークを使うのもよいのですが、腰を据えて 1 からセットアップするのもいいよ」という記事です。

![1 からセットアップした neovim による本記事の編集画面](https://storage.googleapis.com/zenn-user-upload/a292d8a24df3-20240831.png)

# 記事の記載方法について

どうしてフレームワークを使うとだめだったのか、どうして 1 からセットアップしたのかを伝わりやすさの観点から経緯順で記載します。

# vim のキーバインドだけを使い始めた

学生のころに CLI 環境を整えたいなとなっていろいろ調べたところ vim に出会いました。
ゴリラさんの vim 本を読んで、当時使っていた CLion と vscode で vim キーバインドを使い始めました。

https://nextpublishing.jp/book/11839.html

この頃から vim 単体でコードを書くことに憧れていたのですが、「IDE のほうが楽か...」と vscode を含む IDE で vim キーバインドだけ使う道を選択しました。

ただ、zenn や x でみかける vimmer の方々のコーディング画面やコーディングスキルを拝見して、やはりエディタ自体も neovim に移行したいなとなりました。

# astronvim を使い始めるがカスタマイズができない

neovim に移行することを決めてから色々調べてみると、 astronvim という neovim framework に出会いました。
こちらはインストールするだけでいい感じになる OSS であり、デフォルトで lsp, completion, filer, fuzzy finder がいい感じにセットアップされています。
そしてなにより見栄えがかっこいいです。

https://astronvim.com/

astronvim に一目惚れした結果、このフレームワークをセットアップして使っていくことにしました。
しかし 1 週間も使っていると以下の多くの問題に遭遇しました。

- キーマップの変更方法がわからない
- プラグインの追加方法がわからない
- プラグインの設定の変更方法がわからない
- わからないことが出てきたときに、その原因が neovim / astronvim / plugin のどれなのかがわからない
- astronvim v3 → v4 の変更点が大きく、それに伴って設定方法を変えるのが大変

結局メインエディタとして astronvim を使うことはなく、これまで通り vscode を使い続けてしまっていました。
たまにシェルスクリプトを書いたりコンテナのログを見るときにだけ astronvim を使っていました。
あらためて振り返るとよくないですね。

# あらためて 1 から neovim をセットアップした 

このままではいけない、ずっと neovim を使うことはないと思い 1 から neovim をセットアップすることにしました。
セットアップした neovim をずっと使い続けるのではなく、機能と設定方法を理解したら LazyVim や AstroNvim に戻るか〜、という逃げの心持ちももった状態で挑みました。
移行では強い気持ちと逃げられる状況を持つことが大事です。

neovim の設定方法をいろいろとググり、その記事を参考に lazynvim や neotree, treesitter などを設定しました。
**自分で設定することによって、これらのツールがそれぞれ何なのか、なにを叶えてくれるのかを主体的に把握できとても理解が進みました**。
これによって、これまでわかんないなぁとなっていた **キーマップの設定やプラグインのインストール方法などを lua でちゃんと書けるようになりました**。
やはり自分で手を動かしてやらないとなかなか理解には繋がらないですね...。

最終的に下記の動画にたどり着き、こちらを参考にすることで自分だけの neovim 環境をセットアップできました。

https://www.youtube.com/watch?v=6pAG3BHurdM

上記の動画でベース環境をセットアップしたあとは、 neovim の設定ファイル使う言語である lua と仕事で使う php と typescript が快適にかけることを目指せるように改修しました。
1 つの言語がきもちよく書ける環境を作ってしまえば、あとはそれと同じ設定を言語の数だけ書けばよいのでとてもよいです。

なんだかんだ 1 月ほど neovim のセットアップにはかかりましたが、終わってしまえばこちらのものです。
ある程度の作業は neovim 側を主体にできており、仕事上でも neovim を使い始めています。

セットアップした neovim 環境は以下です。

https://github.com/ganyariya/dotfiles/tree/6946ac600e91378e1da2a700c079aba8f822f003/dot_config/nvim

# 参考（+ モチベ）にさせていただいた記事について

https://developers.freee.co.jp/entry/vscode-to-neovim

もっとも参考にさせていただいたのは hachi さんの記事です。
環境やモチベがとても自分と似ており、参考になるなという点が多かったためです。

- vscode でもいいんだけど neovim を使ってみたい
- framework を使い始めたがどう操作とカスタマイズをしたらいいかわからない

https://inside.pixiv.blog/2024/05/07/120000

また yuyukun さんの記事も参考にさせていただきました。
自分も php を仕事で書いているので環境が似ていることとそれらで使っているプラグインを参考にさせていただくためです。

# 今後について

現状では lazynvim をもとに有名なプラグインを入れてそれらのキーマップを独自に設定しているのみ、というのが現状です。
より使いこなしていくために自分でプラグインを書いてみたり便利な関数を作成することでより自分好みの使いやすいエディタに育てていこうと思います。

LazyVim に載せ替えることも考えましたがまだまだ neovim の知らないことが多いと思うため、しばらくは自分でセットアップした環境を使い続けます。
こなれてきたら LazyVim に載せ替えてもよいかな...。

# 最後に

この記事は自分でセットアップ neovim 環境と magi65 というキーボードで書きました。

