---
title: "Plotlyで高画質の画像を出力する"
emoji: "🦔"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ["plotly", "python"]
published: true
---

# Plotly で高画質の画像を出力する

Python の Plotly パッケージは、 JavaScript の Plotly.js を内部で利用しています。
そのため、`fig.show()` で画像を表示しようとするとサーバーが起動します。
そして、リンクが自動で開かれることにより、ブラウザに画像が表示されます。

画像を直接生成するためには、`fig.write_image`メソッドを呼び出します。
また、画像を書き出すためには [kaleido](https://github.com/plotly/Kaleido) などの画像生成パッケージを先に入れておく必要があります。

このメソッドで生成される画像はかなり解像度が悪いです。
そのため、以下の画像のように `scale` を設定することによって高解像度の画像を得ることができます。

```python
fig.write_image("some.png", engine="kaleido", scale=10)
```

# 参考リンク

- https://plotly.github.io/plotly.py-docs/generated/plotly.io.write_image.html
- https://github.com/plotly/Kaleido
- https://kamino.hatenablog.com/entry/plotly_for_report

