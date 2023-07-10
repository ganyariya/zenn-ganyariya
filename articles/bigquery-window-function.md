---
title: "BigQuery のウィンドウ関数のイメージ例と使用例をまとめる"
emoji: "🐓"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["bigquery", "gcp"]
published: true
---

# はじめに

現在 ganyariya のお仕事先では Google Cloud Platform (GCP) が利用されており、とくに分析ログツールとしては BigQuery が利用されています。
ここで、 Analysis Team の方や先輩サーバエンジニアの方のクエリを拝見することがあるのですが、以下のような特徴的なクエリを書いていることがありました。

```sql
select
  *,
  rank() over (partition by x order by y)
from table
where a = b
```

上記のクエリはウィンドウ関数 (window function) と呼ばれるものであり、テーブルの行それぞれで集約関数を実行するものとなっています。

しかし、お仕事中にこれらを詳しく調べる時間がなく、理解が不十分であったためあらためて調べて勉強しました。

この記事ではウィンドウ関数の動作イメージとうれしさ、そして簡単な例をまとめようと思います。

https://cloud.google.com/bigquery/docs/reference/standard-sql/aggregate_analytic_functions?hl=ja

https://cloud.google.com/bigquery/docs/reference/standard-sql/window-function-calls

# 利用データ

今回の例の説明において、以下の ganyariya がプレイしたゲームのスコアテーブルを利用しようと思います。

```sql
with games as (
  select 1 as gameId, 'ダンガンロンパ1' as title, 'スパイク・チュンソフト' as brand, 'mystery' as genre, 2010 as year, 90 as score, 3000 as price
  union all select 2 as gameId, 'ダンガンロンパ2' as title, 'スパイク・チュンソフト' as brand, 'mystery' as genre, 2012 as year, 85 as score, 4000 as price,
  union all select 3 as gameId, 'ever17' as title, 'kid' as brand, 'adv' as genre, 2002 as year, 100 as score, 1500 as price,
  union all select 4 as gameId, 'キラ☆キラ' as title, 'overdrive' as brand, 'adv' as genre, 2007 as year, 88 as score, 6000 as price,
  union all select 5 as gameId, 'ピクミン' as title, 'nintendo' as brand, 'ai action' as genre, 2003 as year, 90 as score, 7000 as price,
  union all select 6 as gameId, 'ダンガンロンパv3' as title, 'スパイク・チュンソフト' as brand, 'mystery' as genre, 2020 as year, 99 as score, 9000 as price,
  union all select 7 as gameId, 'マリオカート8' as title, 'nintendo' as brand, 'car race' as genre, 2020 as year, 70 as score, 8000 as price,
  union all select 8 as gameId, 'マリオカートDS' as title, 'nintendo' as brand, 'car race' as genre, 2002 as year, 75 as score, 5500 as price,
  union all select 9 as gameId, 'サクラノ詩' as title, 'ケロQ' as brand, 'adv' as genre, 2012 as year, 98 as score, 9000 as price,
)

select *
from games
```

![](https://storage.googleapis.com/zenn-user-upload/12e478d1ae74-20230710.png)

# ウィンドウ関数がない場合

はじめに、ウィンドウ関数がない場合について考えてみます。

> ganyariya はゲームのジャンルごとにスコアの平均値を出したいと考えました。
> これによって、ganyariya がどのゲームジャンルが好きかを知りたいためです。
> ただし、**ジャンルごとの平均値だけを出すのではなく、もとの games テーブルの行もすべて出したいです。**

上記のようなケースを想定し、このケースを実現できるようなクエリを実装してみます。

まずは `GROUP BY` を利用してジャンルごとに集計し `AVG` で平均値を計算します。
その後、 join で games テーブルと結合する必要があります。

```sql
with games as (
 ...
),

genre_avg as  (
  select genre, avg(score) as avg_score
  from games
  group by genre
)

select a.*, b.avg_score
from games as a
left join genre_avg as b
on a.genre = b.genre
```

![](https://storage.googleapis.com/zenn-user-upload/fef6fd61155a-20230710.png)

![](https://storage.googleapis.com/zenn-user-upload/95d75e41f1c5-20230710.png)

このように、 `SUM` `AVG` のような集約関数をそのままテーブルに適用すると、 `GROUP BY` で指定したカラムごとに圧縮されてしまいます。

もし `GROUP BY` で圧縮した内容でよいのであればこのままでよいです。
しかし、元のテーブル（今回の場合 games）の行をそれぞれ保持したい場合は、圧縮後のテーブルと元のテーブルを join する必要があります。

join の処理をユーザ側で書くとクエリが長くなってしまいます。
そこで、この面倒さを解消するのが `ウィンドウ関数` です。

# ウィンドウ関数の動作イメージとうれしさ

https://cloud.google.com/bigquery/docs/reference/standard-sql/window-function-calls

ウィンドウ関数ではそれぞれの行ごとに、`特定のパーティション（集約関数を実行する範囲）`を定めます。
そして、そのパーティションごとに集約関数を実行することによって、`元のテーブルの行数を保持`できます。

![](https://storage.googleapis.com/zenn-user-upload/a95ab43ff3a4-20230710.png)

上記の画像ではオレンジ色の行それぞれが、オレンジ色の行 3 行を対象として `AVG` を実行しています。

- オレンジ色 1 行目 (スコア 90) が、 オレンジ色 1 ~ 3 行目を対象として `AVG` を実行し、 平均値 50
- オレンジ色 2 行目 (スコア 20) が、 オレンジ色 1 ~ 3 行目を対象として `AVG` を実行し、 平均値 50
- オレンジ色 3 行目 (スコア 40) が、 オレンジ色 1 ~ 3 行目を対象として `AVG` を実行し、 平均値 50

![](https://storage.googleapis.com/zenn-user-upload/2c3d80572dc1-20230710.png)

同様に、青色と薄緑色の各行でも同様にそれぞれ集約関数を実行します。

- 青色 4 行目 (スコア 100) が、 青色 4, 6 行目を対象として `AVG` を実行し、 平均値 60
- 青色 6 行目 (スコア 20) が、 青色 4, 6 行目を対象として `AVG` を実行し、 平均値 60

このように、ウィンドウ関数ではそれぞれの行ごとに集約関数を実行するパーティションを定めます。
これによって、**元の行数を保持しながら**、特定のパーティションごとに集約関数を実行できます。

# ウィンドウ関数の記法とクエリ例

## 記法

https://cloud.google.com/bigquery/docs/reference/standard-sql/window-function-calls

ウィンドウ関数は下記のような記法になっています。
記法をそのまま読み解くのは難しいため、実際のクエリの例で見てみます。

```
function_name ( [ argument_list ] ) OVER over_clause

over_clause:
  { named_window | ( [ window_specification ] ) }

window_specification:
  [ named_window ]
  [ PARTITION BY partition_expression [, ...] ]
  [ ORDER BY expression [ { ASC | DESC }  ] [, ...] ]
  [ window_frame_clause ]

window_frame_clause:
  { rows_range } { frame_start | frame_between }

rows_range:
  { ROWS | RANGE }
```

## ジャンルごとにスコア平均値を計算する (over + partition by)

一番最初の `group by + join` の例と同様に、ジャンルごとのスコア平均値をウィンドウ関数を用いて出してみます。

`window genre_avg_window as ()` で named window (名前付きウィンドウ) を定義しています。

> named window 句を定義せず、[直接 `select` の箇所でウィンドウ関数を呼び出す](https://cloud.google.com/bigquery/docs/reference/standard-sql/window-function-calls#compute_a_grand_total)書き方もあります。

`partition by genre` で、 `games.genre` ジャンルごとのパーティションに分割することを表しています。

そして、 `AVG(score) over genre_avg_window` によって、ジャンルパーティションごとに `AVG` 集約関数をそれぞれ適用することを表しています。

```sql
with games as (
 ...
)

select *, AVG(score) over genre_avg_window as genre_avg
from games
window genre_avg_window as (
  partition by genre
)
order by gameId
```

![](https://storage.googleapis.com/zenn-user-upload/a2c798daceb9-20230710.png)

- ウィンドウ関数を呼び出す場合は `集約関数 over ウィンドウ` 
- `partition by` で集約関数を実行するパーティションを決定する

## ジャンルごとにランキングをつけてみる（order by）

続いて、以下の例を考えてみます。

> ganyariya はジャンルごとに、どのゲームが一番すきなのかランキングを出すことにしました。
> ミステリのなかでどれが一番好きなのか、レースゲームでどれが一番好きなのか... をそれぞれ知りたいためです。

このような場合、 rank 関数を利用します。
また、同時に `order by` を利用します。

`partition by` でジャンルごとにパーティションへ分割するところまでは同じです。

その後、 `order by score desc` で各パーティションそれぞれでスコアの値でソートします。

```sql
with games as (
  ...
)

select *, RANK() over genre_score_rank_window as rank
from games
window genre_score_rank_window as (
  partition by genre
  order by score desc
)
order by genre, score desc
```

![](https://storage.googleapis.com/zenn-user-upload/a739adb9632a-20230710.png)

このように、 window 句のなかで order by を利用することで、パーティションごとにソートできます。
これによって、特定のグループ（パーティション）ごとに順位を簡単に求められます。

## ブランドごとにスコアの平均値が時がたつに連れて変化したのか出してみる (between)

> ganyariya は自分がプレイしたゲームのパブリッシャー（brand）のスコア平均値が、時間が立つにつれて上がったのか下がったのか気になりました。
> もしブランドのゲームスコア平均値が年が経過するにつれて上がった場合、自分とそのブランドの相性がどんどのん上がっています。
> 一方で、もしスコア平均値が下がっているのであれば、そのブランドのターゲット層ではなくなっており、異なるパブリッシャーのゲームシステムが好きになっていると言えそうです。

上記のように、brand ごとにスコアの推移を計算してみます。

このような場合、 `rows between` (or `range between`) 句を利用すると便利です。

以下のクエリでは、これらを表しています。

-  `partition by brand` でブランドごとにパーティションを分割する
-  `order by year asc` で、古いものから新しいものに並べる
-  `rows between UNBOUNDED PRECEDING AND CURRENT ROW` で、並び替えられたパーティションの一番最初の行から今の行までを集約関数の対象にする

```sql
with games as (
  ...
)

select *, AVG(score) over brand_score_avg_window as avg_score
from games
window brand_score_avg_window as (
  partition by brand
  order by year asc
  rows between UNBOUNDED PRECEDING AND CURRENT ROW
)
order by brand, year
```

![](https://storage.googleapis.com/zenn-user-upload/42dd9660e53e-20230710.png)

このように、`rows between` を利用することで、パーティションにおける集約関数をそれぞれどこまで適用するかを決められます。
これによって、より細かな表現が可能となります。

`UNBOUNDED PRECEDING` など、行の指定範囲については以下のサイトがわかりやすかったです。

https://recruit.gmo.jp/engineer/jisedai/blog/bigquery-window-function/

# まとめ

ウィンドウ関数を利用することによって、**元の行を保持したまま**、それぞれの行ごとに集約関数を実行できます。
また、`order by + rows between` でパーティション内でソートし、かつそのパーティション内でさらに適用範囲を絞り込めます。

# 参考リンク

https://qiita.com/HiromuMasuda0228/items/0b20d461f1a80bd30cfc

https://dev.classmethod.jp/articles/window-frame-m-oshiro/

https://recruit.gmo.jp/engineer/jisedai/blog/bigquery-window-function/

https://cloud.google.com/bigquery/docs/reference/standard-sql/aggregate_analytic_functions?hl=ja

https://cloud.google.com/bigquery/docs/reference/standard-sql/window-function-calls

# 備考

https://zenn.dev/smzst/articles/77b598bbbf7a01

ランキングにおいて 1 位のみ取り出したい場合においては、 `rank() over` を使うのではなく `array_agg` を利用するのが良いそうです。
利用する bigquery のスロット数が少なくなります。

```sql
with games as (
  ...
),

genre_ranked_table as (
  select g.genre, array_agg(g order by g.score desc limit 1)[offset(0)]  as genre_score
  from games as g
  group by g.genre
)

/*
row_number, rank より効率的らしい
*/

select genre, genre_score.*
from genre_ranked_table
```
