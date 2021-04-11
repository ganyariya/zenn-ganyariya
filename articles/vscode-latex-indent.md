---
title: ""
emoji: "🎉"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---

# はじめに

現在， VSCode で$\LaTeX$の論文を書いています。
利用している拡張機能は `LaTeX Workshop` です。

しかしファイルを保存しようとすると、毎回 `フォーマットに失敗しました` という旨のメッセージが表示されます。
LaTeX Workshop の出力を見ても以下のログの通りであり、 `latexindent` まわりが原因で失敗している事がわかります。

```bash
[09:14:54] Formatting with command /Users/ganariya/.vscode/extensions/james-yu.latex-workshop-8.16.1/scripts/latexindent -c,.//,__latexindent_temp.tex,-y=defaultIndent: '    '
[09:14:54] Formatting failed with exit code 127
[09:14:54] stderr: docker: Error response from daemon: OCI runtime create failed: container_linux.go:370: starting container process caused: exec: "latexindent": executable file not found in $PATH: unknown.
```

かなり長い間この問題を放置していましたが、毎回メッセージが出力されるのも辛いため、重い腰をあげてこの問題を解決しようと思います。

# 対応策

はじめに `latexindent` コマンドが使えるか調べてみます。
打ち込んでみると以下のようにエラーメッセージ出てうまくいきませんでした。

メッセージを読むと `Log::Log4perl`  module を入れるとよいかもという旨があります。
ただ、 perl 自体を触ったことがないので、とりあえずインターネットの海へ旅立つことにしました。

``` bash
$ latexindent
Can't locate Log/Log4perl.pm in @INC (you may need to install the Log::Log4perl module) (@INC contains: /usr/local/texlive/2020/texmf-dist/scripts/latexindent /Library/Perl/5.28/darwin-thread-multi-2level /Library/Perl/5.28 /Network/Library/Perl/5.28/darwin-thread-multi-2level /Network/Library/Perl/5.28 /Library/Perl/Updates/5.28.2 /System/Library/Perl/5.28/darwin-thread-multi-2level /System/Library/Perl/5.28 /System/Library/Perl/Extras/5.28/darwin-thread-multi-2level /System/Library/Perl/Extras/5.28) at /usr/local/texlive/2020/texmf-dist/scripts/latexindent/LatexIndent/LogFile.pm line 22.
BEGIN failed--compilation aborted at /usr/local/texlive/2020/texmf-dist/scripts/latexindent/LatexIndent/LogFile.pm line 22.
Compilation failed in require at /usr/local/texlive/2020/texmf-dist/scripts/latexindent/LatexIndent/Document.pm line 25.
BEGIN failed--compilation aborted at /usr/local/texlive/2020/texmf-dist/scripts/latexindent/LatexIndent/Document.pm line 25.
Compilation failed in require at /Library/TeX/texbin/latexindent line 27.
BEGIN failed--compilation aborted at /Library/TeX/texbin/latexindent line 27.
```

以下の記事を参考にしました。

https://qiita.com/khys/items/332c3a3f34a82acf7a7a

はじめに brew で perl を入れ直して、その後 cpan で `Log::Log4perl` モジュールを追加しています。
cpan は、 perl のモジュールアーカイブであり、そのコマンド名を指します。
python では pip, nodejs では npm に相当します。

```bash
brew install perl
cpan Log::Log4perl
```

上記のコマンドは 2 つとも時間がかるため気長に待つことにします。

