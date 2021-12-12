---
title: "ganyariya with ABC231"
emoji: "🐡"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["atcoder", "競技プログラミング"]
published: true
---

# 解説

https://scrapbox.io/ganariya-competitive/AtCoderBeginnerContest231_A%E5%95%8F%E9%A1%8C100%E7%82%B9_%E3%80%8CWater_Pressure%E3%80%8D

https://scrapbox.io/ganariya-competitive/AtCoderBeginnerContest231_B%E5%95%8F%E9%A1%8C200%E7%82%B9_%E3%80%8CElection%E3%80%8D

https://scrapbox.io/ganariya-competitive/AtCoderBeginnerContest231_C%E5%95%8F%E9%A1%8C300%E7%82%B9_%E3%80%8CCounting_2%E3%80%8D

https://scrapbox.io/ganariya-competitive/AtCoderBeginnerContest231_D%E5%95%8F%E9%A1%8C400%E7%82%B9_%E3%80%8CNeighbors%E3%80%8D

https://scrapbox.io/ganariya-competitive/AtCoderBeginnerContest231_E%E5%95%8F%E9%A1%8C500%E7%82%B9_%E3%80%8CMinimal_payments%E3%80%8D

https://scrapbox.io/ganariya-competitive/AtCoderBeginnerContest231_F%E5%95%8F%E9%A1%8C500%E7%82%B9_%E3%80%8CJealous_Two%E3%80%8D

# 個人的感想と学び

## 感想

参加日はお酒を飲んでいたので unrated で出ました。
せっかくなのでバーチャルの姿で動画を取りながら参加しています（コンテスト後に動画を後悔しています）。

go の `map` の書き方を覚えていて嬉しくなっている自分がいました。
（毎回忘れていたので。）

https://www.youtube.com/watch?v=X3-Nga7vbdA

## 学び

#### map

Go の map は `make(map[string]int)` のように `map[T]R` として書く。

#### コンストラクタ

Go のコンストラクタは、`NewT() *T` のように、ポインタを返す。
コンストラクタ関数内では、`&T` や `new(T)` としてメモリ領域に確保する。

#### レシーバ

`func (p *Person) hello (g string) string {}` のように、 Person という型にメソッドを生やす機能を**レシーバ**という。
こういう書き方は Nim に近いなぁって思いました。
拡張しやすくていいですね。

```go
type UnionFind struct {
 	par   []int
 	sizes []int
 }
 
 func NewUnionFind(n int) *UnionFind {
 	ret := &UnionFind{
 		par:   make([]int, n),
 		sizes: make([]int, n),
 	}
 	for i := 0; i < n; i++ {
 		ret.par[i] = i
 	}
 	return ret
 }
 
 func (uf *UnionFind) Find(x int) int {
 	if x == uf.par[x] {
 		return x
 	} else {
 		ret := uf.Find(uf.par[x])
 		uf.par[x] = ret
 		return ret
 	}
 }
 
 func (uf *UnionFind) Unite(x, y int) bool {
 	x = uf.Find(x)
 	y = uf.Find(y)
 	if x == y {
 		return false
 	}
 	if uf.sizes[x] < uf.sizes[y] {
 		x, y = y, x
 	}
 	uf.par[y] = x
 	uf.sizes[x] += uf.sizes[y]
 	return true
 }
 
 func (uf *UnionFind) Same(x, y int) bool {
 	return uf.Find(x) == uf.Find(y)
 }
 
 func (uf *UnionFind) GetSize(x int) int {
 	return uf.sizes[uf.Find(x)]
 }
 
```
