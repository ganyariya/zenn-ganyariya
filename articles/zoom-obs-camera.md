---
title: "世界で2番目にお手軽なバーチャルアニメZoomビデオ配信"
emoji: "🎃"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ['zoom', 'obs']
published: true
---

# はじめに

先日、とある LT で発表する機会がありました。
このとき、「自分の美しくない顔と体を写したくないにゃ〜」となり、バーチャルの体で Zoom ビデオ LT をしました。

今回は、世界で 2 番目レベルに手を抜いて自分の顔を移さずに、アニメ 3D ボディで Zoom ビデオ配信をする方法をまとめます。

![](https://storage.googleapis.com/zenn-user-upload/b72adf4d38101034ebdb8d6f.png)

# ツール

以下のソフトを利用します。

- 任意のターミナルソフト (Alacritty, iTerm など)
- OBS (**Version 26.0 以上**)
- `Kalidoface 3D`
- ビデオ配信したいツール（Zoom, Microsoft Teams, Google Meets など）

https://3d.kalidoface.com/

OBS 26 から仮想カメラ機能が標準でついています。
そのため、必ず 26 以上のバージョンである OBS をインストールしてください。

[Kalidoface](https://3d.kalidoface.com/) は 2021/07 に発表された、アニメキャラモーショントラッキングを WebCam のみで行うアプリです。
動作も軽く、最初から 3D モデルも多く実装されているため、気軽に試せます。

# How To

## OBS の起動

はじめに、ターミナルから OBS を起動します。
これは OBS の機能である `ブラウザ` で `Kalidoface Web Page` を開いたときに、
OBS に含まれている Chronium ブラウザからカメラへのアクセスを許可するためです。

`enable-media-stream` オプションをつけることで、OBS Chronium ブラウザからマイクへのアクセスを許可します。

```shell
/Applications/OBS.app/Contents/MacOS/OBS --enable-media-stream
```

## ブラウザを作成

任意のシーンを作成後、`ブラウザ` を追加します。
`URL` の欄に `Kalidoface` のリンクを指定しましょう。

![](https://storage.googleapis.com/zenn-user-upload/c5eaa82cff3150a16b9dddc2.png)

`OK` をクリックすると、`Kalidoface` が画面に読み込まれます。

## ブラウザをいじる

作成したブラウザをマウスで操作して、`FaceTracking` を ON にしたり、Kalidoface アプリの背景を設定したりしましょう。
（自分の場合は、`ganariya` と表示されている背景画像を Kalidoface の背景に設定しています。）

ブラウザを右クリックすると、以下のようなメニューが表示されます。
ここで、`対話`を選択すると、ブラウザを操作できるようになります。
あとは、トラッキング機能を ON にしたり、背景などを自由に設定しましょう。

この**対話**がなかなか見つからず、ブラウザが操作できないよ〜になるため、気をつけましょう（２敗）。

![](https://storage.googleapis.com/zenn-user-upload/5f3ccdf1c5779f89c5aec7fc.png)

## 仮想カメラ配信

ここまで来ればあとは簡単です。
`仮想カメラ開始` をクリックしましょう。

クリックすると、Mac, Linux, Windows 内部で仮想カメラとして認識されます。
よって、あとは Zooom, Microsoft Teams などから、仮想カメラを指定すればかわいいアニメ 3D キャラを表示できます。

![](https://storage.googleapis.com/zenn-user-upload/3804f4a89021d90594b9708d.png)

# まとめ

僕もはやくバーチャルの体がほしいですね。
働き始めたら Windows マシンを買って、VR Chat もやってみたいなと考えています。
