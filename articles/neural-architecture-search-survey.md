---
title: "Neural Architecture SearchとNeuroevolutionの個人的まとめ"
emoji: "🐈"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Neural Architecture Search","Neuroevolution","NAS"]
published: true
---

# Neural Architecture Search

## 利点

## 課題点

## 論文リスト

関連度・出てきた順にまとめている。
まだきちんと内容自体は読んでない。(読もうね）

### NEURAL ARCHITECTURE SEARCH WITH REINFORCEMENT LEARNING

強化学習でアーキテクチャ探索をしている。
RNNで文字列を生成してそれを子供ネットワークとしどれくらいよいか計算して
その精度を報酬として、生成方策を修正する。

- https://www.youtube.com/watch?v=sROrvtXnT7Q
- https://www.slideshare.net/yamatookamoto5/neural-architecture-search-with
- https://speakerdeck.com/satuma777/lun-wen-shao-jie-neural-architecture-search-with-reinforcement-learning?slide=41
- https://qiita.com/norihitoishida/items/41b517225c905606a363
- https://qiita.com/chobaken/items/f782556fa58d88e05584

### Learning Transferable Architectures for Scalable Image Recognition

上のNEURAL ARCHITECTURE SEARCH WITH REINFORCEMENT LEARNINGが重すぎたので
セルブロックごとに計算した

ただし、CNNといった、ある程度のDomain知識がひつようになっている


- https://qiita.com/cvusk/items/536862d57107b9c190e2
- https://www.youtube.com/watch?v=tfCA8X4jGjk
- https://github.com/yoheikikuta/paper-reading/issues/10


### Efficient Neural Architecture Search via Parameter Sharing

個人的にこれが結構好き。

大きいグラフ用意してそれのサブグラフを取り出して学習しているらしい。
そのため、重みを共有しており、高速化が著しくできている
（GPU１個で一日で終わるらしい）

- https://vimeo.com/312307145
- https://www.slideshare.net/TaichiItoh/efficient-neural-architecture-searchvia-parameter-sharing
- https://www.slideshare.net/tkatojp/efficient-neural-architecture-search-via-parameters-sharing-icml2018
- https://qiita.com/cvusk/items/536862d57107b9c190e2

### DARTS: DIFFERENTIABLE ARCHITECTURE SEARCH

アーキテクチャのノード間に複数の接続を用意して
それぞれの接続がPooling, Convといった異なるOperationになっている。

これらを少数で重みつけをして、アーキテクチャごと微分できるようにして、どのOperationを選択するか取捨選択できるようになっている。

- https://www.slideshare.net/YutaKoreeda/darts-differentiable-architecture-search
- https://www.slideshare.net/c-bata/darts-differentiable-architecture-search-at-205326748
- https://qiita.com/cvusk/items/e7c9bb30c801996cd973


### FBNet: Hardware-Aware Efficient ConvNet Designvia Differentiable Neural Architecture Search

なんかモバイル向けだとネットワークに入力してから出力するまでの時間も重要らしいので
それを生成に取り入れるようにしたらしい

もっと調べたほうが良さそう

- https://youtu.be/PzALQZOy09c?t=3918
- http://xpaperchallenge.org/cv/survey/cvpr2019_summaries/768/


### And more...


# Neuroevolution (Genetic Algorithm)




