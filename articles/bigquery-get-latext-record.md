---
title: "BigQuery で最新のレコードを取得する"
emoji: "🤖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["bigquery"]
published: false
---

# はじめに

BigQuery で「グループ化したものから最新のレコードを取得する」を行いたい場合があります。
このような場合、 **`ARRAY_AGG` 関数を利用すると、効率よく最新のレコードを集計**できます。

https://cloud.google.com/bigquery/docs/best-practices-performance-functions?hl=ja#use_an_aggregate_function_to_obtain_the_latest_record

この記事では、ノベルゲームのサンプルをもとに、 ARRAY_AGG を利用した「もっとも X なレコード」の取得例を示します。

# 利用するサンプルデータ

ganyariya がプレイしたノベルゲーム履歴データを利用します。

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
select * from games;
```

![](https://storage.googleapis.com/zenn-user-upload/864d1f63c307-20230925.png)

# BAD: RANK 関数を利用する

もっとも X なレコードを取得する方法として、 RANK / ROW_NUMBER 関数を利用する方法があります。
RANK / ROW_NUMBER 関数を利用することで、 1, 2, 3, ... と番号を振ることができます。
その後、番号が 1 のレコードのみフィルターすることによって、もっとも X なレコードを取得できます。

ここでは、以下のような例を考えてみます。

> プレイしたノベルゲームのうち、各ブランドごとにもっともスコアが高かったゲームを取得する。
> つまり、各ブランドごとに一番お気に入りのゲームを取得したい。

このとき、 RANK 関数を利用すると、以下のようにクエリを書けます。

```sql
with games as (
  select 1 as gameId, 'ダンガンロンパ1' as title, 'スパイク・チュンソフト' as brand, 'mystery' as genre, 2010 as year, 90 as score, 3000 as price
  ...
),

ranked as (
  select 
    *, 
    rank() over win as rank
  from 
    games as g
  window win as (
    partition by g.brand
    order by g.score desc
  )
)

select brand, title, score
from ranked
where rank = 1
order by brand
```

![](https://storage.googleapis.com/zenn-user-upload/3b1874398388-20230925.png)

上記のクエリではウィンドウ関数というものを利用しています。
詳しくは以下の記事を参考にしてください。

https://zenn.dev/ganariya/articles/bigquery-window-function

はじめに、 `partition by` で brand というパーティションに分割し、スコアの降順で並べています。
そして、brand（パーティション）ごとに RANK 関数で順位付けをし、そのテーブルを ranked テーブルと名付けています。
最後に、 ranked テーブルからもっともスコアの高い（rank = 1）のレコードのみ取得することによって、ブランドごとにお気に入りのゲームを取得しています。

この方法では、ランキングが 2, 3, 4 位など、1 位以外のレコードについても RANK 関数で順位付けする必要があります。
そのため、消費する計算スロット量が増加します。

# GOOD: ARRAY_AGG 関数を利用する

https://cloud.google.com/bigquery/docs/best-practices-performance-functions?hl=ja#use_an_aggregate_function_to_obtain_the_latest_record

BigQuery のドキュメントでも紹介されているように、もっとも X なレコードを取得したい場合 ARRAY_AGG 関数を利用するべき、と紹介されています。

先程の RANK 関数のクエリを ARRAY_AGG 関数で書き換えると以下のようになります。

```sql
with games as (
  select 1 as gameId, 'ダンガンロンパ1' as title, 'スパイク・チュンソフト' as brand, 'mystery' as genre, 2010 as year, 90 as score, 3000 as price
  ...
)

select 
  brand,
  array_agg(struct(g.title, g.score) order by g.score desc limit 1)[OFFSET(0)]
from 
  games as g
group by brand
order by brand 
```

![](https://storage.googleapis.com/zenn-user-upload/82b8dc7850fe-20230925.png)

クエリから Window 句が消えており、かわりに ARRAY_AGG 関数が追加されていることがわかると思います。

## array_agg を読み解く

特徴的なクエリは `array_agg(struct(g.title, g.score) order by g.score desc limit 1)[OFFSET(0)]` だけです。
ここを段階的に読み解いていきます。

https://cloud.google.com/bigquery/docs/reference/standard-sql/aggregate_functions#array_agg

はじめに、 `array_agg` は、複数のレコードの値を 1 つの array に集約する関数です。
group by brand を利用したとき、 `brand` 以外のカラムについては SUM や AVG, MAX などを利用して「代表値」のみを取得しないと SELECT で表示できません。
しかし、 array_agg を利用すると、複数のレコードの値を 1 つの array に集約できます。

```sql
select 
  brand,
  array_agg(g.title)
from 
  games as g
group by brand
order by brand 
```

![](https://storage.googleapis.com/zenn-user-upload/1030a98f5f71-20230925.png)

上記の例では、 brand ごとにグループ化したのち、同じ brand のゲームタイトルを 1 つの array に集約しています。

続いて、 `array_agg(struct(g.title, g.score) order by g.score desc limit 1)` です。
これは、brand グループごとに `g.score` の降順へ order by で並び替えます。
その後、**もっともスコアが高いもののみを 1 つだけ（limit 1）で取得しています**。
これによって、**RANK 関数よりも 1, 2, 3... の番号を振る数が減ります**。
スコアが高いものについて `struct(g.title, g.score)` を利用してタイトルとスコアからなる構造体を作成しています。

最後に、 `[OFFSET(0)]` です。
これは array_agg で作成した array のうち、 index で 0 のもの、つまりもっともスコアが高いもののみを取得しています。
といっても、`array_agg(... limit 1)` によって、すでに array の length は 1 になっています。

よって、 `array_agg(struct(g.title, g.score) order by g.score desc limit 1)[OFFSET(0)]` は以下を行っています。

- brand グループごとに score の値が大きい順に並び替える
- `limit 1` によって 1 行だけ取り出す
- array_agg によって、 1 要素からなる array にする
- `[offset(0)]` によって、 array から要素を取得する（= もっとも X なレコードになっている）

## パフォーマンス

`limit 1` を実行しているため、 RANK / ROW_NUMBER と比較して、扱うレコード数が削減されます。
そのため、パフォーマンスが良いとされています。

# 最後に

BigQuery で最新のレコードを取得したい際は ARRAY_AGG 関数を利用しようと思います。
パフォーマンスも良いですし、純粋に記述量も減りそうなのでこちらを活用していきます。
