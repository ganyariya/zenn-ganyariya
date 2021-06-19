---
title: "Plotly の Radar Chart をシンプルにする"
emoji: "🎉"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['python', 'plotly']
published: true
---

# はじめに

Plotly では Radar Chart を出力できます。
https://plotly.com/python/radar-chart/

![](https://storage.googleapis.com/zenn-user-upload/128d366e303dcdeddaf5001f.png)

しかし，デフォルトのままでは以下のように少し見た目が派手です。

- 色が塗りつぶされている
- 背景が青い
- 丸い円が何個も連なっている

論文に利用する場合は、もう少しシンプルなデザインにしたい場合があります。

# シンプルにする

Radar Chart の Document を読みます。
Radar Chart のデフォルトリンク先が異なるプロットである ScatterPlot であるため、以下の Ploar のドキュメントも使うと良いです。

https://plotly.com/python/reference/layout/polar/#layout-polar-radialaxis

```python
import plotly.graph_objects as go
fig = go.Figure()

fig.add_trace(
 go.Scatterpolar(
  fill="none",
  name=f"Cluster{i}",
  opacity=0.7,
  line=dict(width=5),
 )
)
```

fill を "none" に設定しておくと、描画される各 Radar が線のみで描画されてうれしいです。

```python
fig.update_layout(
    template=None,
    polar=dict(
        radialaxis=dict(
        visible=True,
        range=[0, max_axis_value],
        showline=False,
        showgrid=False,
    ),
    angularaxis=dict(tickfont=dict(size=30)),
    paper_bgcolor="rgb(255, 255, 255)",
    plot_bgcolor="rgb(255, 255, 255)",
)
```

template を None にするとデザインがシンプルになります。
また、 polar に対して、 showline や showgrid の設定を False にするといらない線が描画されなくなります。

![](https://storage.googleapis.com/zenn-user-upload/341dc8956cc02fc81dbdec6d.png)

