---
title: "LaTeX の MultiRow MultiColumn のお気持ちを理解する"
emoji: "🎃"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['latex', 'tex']
published: true
---

# はじめに

$\LaTeX$ で論文を書くとき、分析した内容をテーブルで書きたいときが多々あります。
また、このときいくつかのセルを連結したいときがあります。
このとき、立ちはだかるのが `multirow` と `multicolumn` です。
`table` 環境だけでもコンパイルを通すのが難しいのにも関わらず、さらに難しい概念が登場します。

今回は `multirow` と `multicolumn` のお気持ちを理解することを目的とします。

# 流行りのテーブル

$\LaTeX$ で書かれるテーブルにおいて、近頃は線が少ないほど美しいという傾向があります。
すべてのセルに対して上下左右に線を引くのではなく、以下の画像のように重要な箇所のみ横方向に線を引きます。

![](https://storage.googleapis.com/zenn-user-upload/f01392018cf7f92a6af93f32.png)

以降では `booktabs` と `multirow` パッケージを使用するため、必ず以下の usepackage をしてください。

```latex
\usepackage{booktabs}
\usepackage{multirow}
```

# スタート地点: シンプルな booktabs テーブル

mutlirow と multicolumn を理解するために、`booktabs` を用いてスタート地点のテーブルを作ります。
このテーブルに拡張を加えることで、 multirow, multicolumn を実装します。

`booktabs`では、`\toprule`, `\midrule`, `\bottomrule` というコマンドを用いて横方向に線を引きます。
これによって、非常にシンプルでクリーンなテーブルを構築できます。

![](https://storage.googleapis.com/zenn-user-upload/949dc4c96f66fea0353cc756.png)

```latex
\begin{table}
    \centering
    \caption{Start}
    \begin{tabular}{cccccc}
        \toprule
        Group & Column-A & Column-B & Column-C & Column-D & Column-E \\
        \midrule
        X     & a        & b        & c        & d        & e        \\
        X     & a        & b        & c        & d        & e        \\
        X     & a        & b        & c        & d        & e        \\
        \midrule
        Y     & a        & b        & c        & d        & e        \\
        Y     & a        & b        & c        & d        & e        \\
        \bottomrule
    \end{tabular}
\end{table}
```

## お気持ち

`booktabs` で縦の線を減らせて嬉しいです。
極力横方向の線のみに抑えることで、クリーンな印象を与えられました。

しかし、`Group` のカラムで同じグループを表す `X` を 3 回も書いてしまっています。
極力これらは同じグループとしてまとめ上げてしまいたいです。

そこで、これらを**置き換える気持ちで multirow** を設定します。

# multicolumn

先程のテーブルでは、`X` と `Y` を同じグループであることを示すために複数回書いてしまいました。
そこで、これらを `multirow` で**置き換え**ます。

![](https://storage.googleapis.com/zenn-user-upload/f01392018cf7f92a6af93f32.png)

```latex
\begin{table}
    \centering
    \caption{BookTabs MultiRow}
    \begin{tabular}{cccccc}
        \toprule
        Group              & Column-A & Column-B & Column-C & Column-D & Column-E \\
        \midrule
        \multirow{3}{*}{X} & a        & b        & c        & d        & e        \\
                           & a        & b        & c        & d        & e        \\
                           & a        & b        & c        & d        & e        \\
        \midrule
        \multirow{2}{*}{Y} & a        & b        & c        & d        & e        \\
                           & a        & b        & c        & d        & e        \\
        \bottomrule
    \end{tabular}
\end{table}
```

`X` が縦方向に連続していた箇所を `\multirow{3}{*}{X}` と置き換えました。
これは、`{3 行分}{いい感じに}{X というテキストを書く}`ことを表しています。
`\multirow{3}{*}{X}` の下 2 行に関しては、すでに `\multirow{3}{*}{X}` で置き換えられているため何も書かなくて良いです。

このように、あらかじめすべてを埋めたテーブルを書いてから重複している箇所を「置き換え」る気持ちで `multirow` を書くことを意識すると、自分はかなり理解しやすくなりました。

# multicolumn

`multirow` で得た経験と同じように、`multicolumn` に関しても置き換えるお気持ちで臨むとよいです。
これは、連結したい横のセルの個数だけ `multicolumn` を設定すればよいです。

![](https://storage.googleapis.com/zenn-user-upload/4b5f5947748ced9db118b7de.png)

```latex
\begin{table}
    \centering
    \caption{BookTab MultiRow And MultiColumn}
    \begin{tabular}{cccccc}
        \toprule
        Group              & Column-A                 & Column-B                & Column-C & Column-D & Column-E \\
        \midrule
        \multirow{3}{*}{X} & a                        & \multicolumn{3}{c}{nya} & e                              \\
                           & \multicolumn{2}{r}{hoge} & c                       & d        & e                   \\
                           & a                        & b                       & c        & d        & e        \\
        \midrule
        \multirow{2}{*}{Y} & a                        & b                       & c        & d        & e        \\
                           & a                        & b                       & c        & d        & e        \\
        \bottomrule
    \end{tabular}
\end{table}
```

`multicolumn` を書いた位置から $n$ 個分をセルをぶち抜きます。
`\multicolumn{個数}{置く位置}{テキスト}` の形式です。
`置く位置` の形式は、左揃え・中央揃え・右揃えなど、通常の $\LaTeX$ テーブルの形式と同じです。

# まとめ

`multirow`, `multicolumn` を使うときは、最初にベタ書きですべてのセルを書いてから置き換えるお気持ちで臨むと
コンパイルも通りやすく理解しやすいのかなと思いました。

# P.S

`latexindent` という $\LaTeX$ のコードをフォーマットしてくれるコマンドがあります。
テーブルを書くとき、`latexindent` するのとしないのとでは快適さがまるで違うため、利用するとよさそうです。

また、VSCode の拡張である LaTeX Workshop を使うと、Save 時に自動フォーマットしてくれるためおすすめです。
