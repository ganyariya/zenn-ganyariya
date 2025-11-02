---
title: "パッケージを自作したうえで Unity Package Manager から git URL でインポートする"
emoji: "👏"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["unity", "git"]
published: true
---

# はじめに

おしごとにおいて Unity を使いはじめました。
これまではバックエンドエンジニアとして働いていたため、知らないことばかりで大変です。

企業のゲーム開発においては、自社ライブラリをパッケージ化して、他プロダクトへ GitHub 経由で提供することが多くあります。
車輪の再開発を避けられ、開発が効率的になるためです。

しかし、 ganyariya は Unity におけるパッケージ開発ならびに GitHub 経由のインポートの仕組みを知りませんでした。
この記事では、簡単なパッケージを自作したうえで git URL によってインポートする手順を備忘録としてまとめます。

自分と同様にこの作業をしたことがないかたにとって参考になるかとおもいます。

## 取り扱うことと取り扱わないこと

- 取り扱うこと
  - パッケージを自作する手順
  - GitHub 経由でインポートする手順
  - チュートリアル形式の説明
- 取り扱わないこと
  - パッケージとはなにか
  - Unity Package Manager とはなにか

この記事では取り扱いませんが、パッケージ周辺について調べた Note があるためよければ参考ください。

https://note.ganyariya.dev/01_Note/Unity-Package-Manager-%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6%E8%AA%BF%E3%81%B9%E3%82%8B

## 注意点

- `UnitySample_Adder/Packages/com.ganyariya.adderpackage`
- `UnitySample_Adder/Packages/SampleAdder`

この記事に出てくる上記 2 つのパスは同じディレクトリを指していることに注意してください。
Unity エディタ上で見ると `package.json:displayName` で表示されるため `SampleAdder` というディレクトリに見えます。
一方、ファイルシステム上でみると `com.ganyariya.adderpackage` というディレクトリになります。

## GitHub リポジトリ

今回作成したリポジトリをまとめておきます。

- [UnitySample_Adder](https://github.com/ganyariya/UnitySample_Adder)
  - SampleAdder という提供用パッケージを開発するプロジェクト
    - `他プロダクトへライブラリを提供したい` プロジェクト
- [UnitySample_AdderUser](https://github.com/ganyariya/UnitySample_AdderUser)
  - SampleAdder パッケージを利用する側のプロジェクト
    - `既存プロダクトで開発されたパッケージを利用し、車輪の再開発を避けたい` プロジェクト

# SampleAdder パッケージを開発する

今回は `SampleAdder` というパッケージを開発し他プロジェクトへ提供していきます。
このパッケージには `Adder` という `Add(int x, int y)` だけを提供するクラスを実装します。

## パッケージ開発用プロジェクトを用意する

UnitySample_Adder というプロジェクトを新たに作成します。
これはただの空 Scene しかないプロジェクトです。

https://github.com/ganyariya/UnitySample_Adder/tree/568385142dd9abd205a3ecef79747701fced1fa3

![Imgur](https://i.imgur.com/ZxovjEH.png)

パッケージ開発において、Unity 公式から推奨されるレイアウトがあります。
空デフォルトプロジェクトの状態から、このレイアウトを導入していきます。

https://docs.unity3d.com/ja/2021.3/Manual/cus-layout.html

この図において、 `[YourUnityProject=UnitySample_Adder]/Packages/[YourPackage] = <root>` となります。

```bash
<root>
  ├── package.json
  ├── README.md
  ├── CHANGELOG.md
  ├── LICENSE.md
  ├── Third Party Notices.md
  ├── Editor
  │   ├── [company-name].[package-name].Editor.asmdef
  │   └── EditorExample.cs
  ├── Runtime
  │   ├── [company-name].[package-name].asmdef
  │   └── RuntimeExample.cs
  ├── Tests
  │   ├── Editor
  │   │   ├── [company-name].[package-name].Editor.Tests.asmdef
  │   │   └── EditorExampleTest.cs
  │   └── Runtime
  │        ├── [company-name].[package-name].Tests.asmdef
  │        └── RuntimeExampleTest.cs
  ├── Samples~
  │        ├── SampleFolder1
  │        ├── SampleFolder2
  │        └── ...
  └── Documentation~
       └── [package-name].md
```

今回は下記のようなプロジェクト・パッケージ構成を目指します。

```bash
UnitySample_Adder/Packages/com.ganyariya.adderpackage
  ├── package.json
  ├── README.md
  ├── Editor
  │   ├── com.ganyariya.adderpackage.Editor.asmdef
  │   └── EditorExample.cs
  ├── Runtime
  │   ├── com.ganyariya.adderpackage.asmdef
  │   └── RuntimeExample.cs
  ├── Tests
  │   └── Runtime
  │        ├── com.ganyariya.adderpackage.Tests.asmdef
  │        └── RuntimeExampleTest.cs
  ├── Samples~
  │        ├── SampleFolder1
  │        ├── SampleFolder2
  │        └── ...
```

`Editor` は Unity エディタ上でのみ有効にしたいもの、つまり `Unity 開発を手助けする拡張機能のコード` を入れます。
一方、Runtime は Publish Build したときにも含まれるコードになります。

Editor/Runtime を分けることでよい設計になり、かつ実機のバイナリサイズが小さくなります。

Tests にはユニットテストを、Samples にはユーザに使い方を説明できるようなサンプルシーンを用意します。

## package.json を作成する

それでは実際に SampleAdder パッケージを作っていきます。

https://docs.unity3d.com/ja/2019.4/Manual/upm-manifestPkg.html

`UnitySample_Adder/Packages` 配下に `手動で` `com.ganyariya.adderpackage` ディレクトリを作成し、かつ package.json を手動で作成します。
下記のように package.json を記入しました。

```bash
UnitySample_Adder/Packages/com.ganyariya.adderpackage on  main [?] is 📦 v1.0.0 via  v22.14.0 [☁️ ]
❯ cat package.json -p
{
    "name": "com.ganyariya.adderpackage",
    "displayName": "SampleAdder",
    "version": "1.0.0",
    "unity": "2022.3",
    "description": "Unity Learn. Only Add Package.",
    "keywords": [],
    "license": "MIT",
    "category": "",
    "dependencies": {}
}
```

この状態で Unity を開くと `SampleAdder` という Package が表示されます。
`package` というファイルを開くと、インスペクタ上で package.json の値が確認できます。

![Imgur](https://i.imgur.com/QEtvyhg.png)

##  Assembly Definition を作成する

https://docs.unity3d.com/ja/2018.4/Manual/ScriptCompilationAssemblyDefinitionFiles.html

パッケージを提供するとき、利用側プロジェクトからパッケージコードが認識されるよう Assembly Definition を作成する必要があります。
今回は Editor, Runtime, Tests とディレクトリごとに asmdef を作成します。

Assembly Definition のわかりやすい説明としては下記を参考ください。

https://qiita.com/toRisouP/items/d206af3029c7d80326ed

Unity 上で Runtime というディレクトリを作成します。
その後 Runtime ディレクトリ上で Assembly Definition を作成します。
`com.ganyariya.adderpackage.asmdef` の設定はなにも変更せずデフォルトのままとしました。

![Imgur](https://i.imgur.com/68iAG4A.png)
![Imgur](https://i.imgur.com/ZqSprst.png)
![Imgur](https://i.imgur.com/VwcTo2W.png)

同様に Editor ディレクトリを作成し、 asmdef ファイルを作成します。
Editor の asmdef ファイルには下記の変更を加えています。

- Assembly Definition References に `com.ganyariya.adderpackage` を指定している
	- Runtime で実装した機能を Editor で利用するため
- Platforms を `Editor` のみにする
	- Editor 配下で実装したものは Unity 開発中でしか有効にしないため (Publish Build へ入れたくない)

![Imgur](https://i.imgur.com/WP5mEKI.png)

ここまでおこなうと SampleAdder というパッケージが Package Manager 上で確認できます。
![Imgur](https://i.imgur.com/CUgtT3u.png)

https://github.com/ganyariya/UnitySample_Adder/pull/1

## Runtime 配下に C# スクリプトを書いたうえでテストも実装する

Ganyariya.SampleAdder namespace に Adder クラスを実装しました。

![Imgur](https://i.imgur.com/lR6OHmC.png)

```cs:Packages/SampleAdder/Runtime/Adder.cs
namespace Ganyariya.SampleAdder
{
    public class Adder
    {
        public int Add(int x, int y)
        {
            return x + y;
        }
    }
}
```

続いてテストできるようにしていきます。
`SampleAdder/Tests/Runtime` ディレクトリを手動で作成します。

![Imgur](https://i.imgur.com/GxBgBag.png)

SampleAdder/Tests/Runtime へ com.ganyariya.adderpackage.Tests.asmdef を作成します。
そして、下記のように設定することで Adder クラスに対するユニットテストを実装できるようにします。

- Assembly Definition References を設定する
	- UnityEditor.TestRunner
	- UnityEngine.TestRunner
		- Test Runner を実行するために必要
	- com.ganyariya.adder.package
		- SampleAdder.Adder を参照するために必要
- Platforms を `Editor` に設定する

![Imgur](https://i.imgur.com/Tkqk3SO.png)

最後に SampleAdder/Tests/Runtime へ AdderTest.cs を作成しユニットテストを実装します。

```cs:Packages/SampleAdder/Tests/AdderTest.cs
using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;

namespace Ganyariya.SampleAdder.Tests
{
    public class AdderTest
    {
        [TestCase(1, 2, 3)]
        [TestCase(-1, 2, 1)]
        [TestCase(0, 0, 0)]
        public void AdderAddTest(int x, int y, int expected)
        {
            var adder = new Adder();
            var actual = adder.Add(x, y);
            Assert.AreEqual(expected, actual, $"x: {x}, y: {y}");
        }
    }
}
```

Test Runner でテストが通れば `SampleAdder Package 内において、正しく Adder が Test から参照できている` ことがわかります。

![Imgur](https://i.imgur.com/4IaWPdK.png)

## Editor 配下に C# スクリプトを書く

本来 Editor 配下には Unity 上での開発を便利にする拡張機能などを実装します。
ただし、今回はあくまでも仕組みの理解のため、意味のない動作チェック用コードを書きます。

シーンを再生したときに `ganyariya.adderpackage をインストールしてますよ` というメッセージを Console に出すだけのスクリプトです。
`RuntimeInitializeOnLoadMethod` という Attribute を利用しています。

![Imgur](https://i.imgur.com/UBifkuo.png)

```cs:Packages/SampleAdder/Editor/EditorAdderConfirmer.cs
using UnityEngine;

namespace Ganyariya.SampleAdder
{
    public static class EditorAdderConfirmer
    {
        [RuntimeInitializeOnLoadMethod]
        public static void ConfirmFeature()
        {
            Debug.Log("あなたは ganyariya.adderpackage をインストールしています");

            var adder = new Adder();
            const int x = 10;
            const int y = 20;
            
            Debug.Log($"x = {x} + y = {y} の結果は {adder.Add(x, y)}です。 これは adderpackage の Adder クラスで計算できます。");
        }
    }
}
```

空プロジェクトをつくったときに作成されたデフォルト Scene を再生すると、このメッセージが正しく表示されています。

![Imgur](https://i.imgur.com/jg35fZn.png)

ここまでの内容のコミットが以下です。 PR を作り忘れたのでコミットそのままになっています。

https://github.com/ganyariya/UnitySample_Adder/commit/b771e10b31104c0ed5261e0de190fec01ae89f36

## サンプルシーンを用意する

ライブラリ利用者向けにどのように使うのかを説明するためのサンプルシーンを作ります。

Samples フォルダを作成し、 com.ganyariya.adderpackage.sample という asmdef を作成します。
設定内容は画像のとおりです。
注意すべき点として、Platform を Any Platform としています。

<!-- textlint-disable -->
:::message
実は最初 Platform を `Editor` のみにしていたのですが、 後述する `AdderConsoleLogger` を GameObject へアタッチできませんでした。候補からそもそもでてこなかったのです。
これは Unity において実行時 (Runtime) に MonoBehaviour がアタッチされる仕組みであり、 `Editor` のものは表示されないのが原因であると考えられます。
よって Any Platform に変更しています。
:::
<!-- textlint-enable -->


![Imgur](https://i.imgur.com/EQ6RJHg.png)

```cs
using Ganyariya.SampleAdder;
using UnityEngine;


namespace Ganyariya.SampleAdder.Sample
{
    public class AdderConsoleLogger : MonoBehaviour
    {
        [SerializeField] private int x;
        [SerializeField] private int y;

        void Start()
        {
            var adder = new Adder();
            var result = adder.Add(x, y);

            Debug.Log($"x = {x}, y = {y}, addResult = {result} in AdderConsoleLogger");
        }
    }
}
```

上記の AdderConsoleLogger を AdderConsoleLoggerGameObject へアタッチしシーンを実行したところ、正しくログが表示されました。
このように Samples 配下へテストシーンを用意することで、どのようにライブラリを使うのかを説明できそうです。

![Imgur](https://i.imgur.com/UxSUplc.png)

https://github.com/ganyariya/UnitySample_Adder/pull/2

# SampleAdder パッケージを別プロジェクトから git 経由で利用する

それではさきほどまで開発した SampleAdder パッケージを、別プロジェクト `UnitrySample_AdderUser` から利用することとします。

![Imgur](https://i.imgur.com/MMnkoyi.png)

空プロジェクトとして作成したコミットは以下です。

https://github.com/ganyariya/UnitySample_AdderUser/tree/d9ebb716e9b54c744d00ad431e5c5bf13eb1afb6

## SamplePackage を UTM 経由でインポートする

#UnityPackageManager を利用して、 SamplePackage を UnitySample_AdderUser へインポートします。

![Imgur](https://i.imgur.com/KWBO8gi.png)

UnityPackageManager へ GitHub への URL で追加するときのレファレンスは下記が参考になります。

https://orotiyamatano.hatenablog.com/entry/2023/05/30/%E3%80%90%E5%82%99%E5%BF%98%E9%8C%B2%E3%80%91%28Unity%29git%E3%81%8B%E3%82%89PackageManager%E3%81%B8%E3%81%AE%E8%BF%BD%E5%8A%A0%E6%96%B9%E6%B3%95

- https://github.com/ganyariya/UnitySample_Adder を repository 対象とする
- package.json があるのは `UnitySample_Adder/Packages/com.ganyariya.adderpackage` になる

上記のことから、今回入力すべき git URL は以下になります。

```bash
https://github.com/ganyariya/UnitySample_Adder.git?path=/Packages/com.ganyariya.adderpackage
```

![Imgur](https://i.imgur.com/HUtbnO3.png)

インストールが完了すると `SampleAdder` パッケージの情報が期待通りに表示されています。

![Imgur](https://i.imgur.com/VAS4Gi0.png)

インストールした Package の情報は UnitySample_AdderUser の `Packages/manifest.json` に追加されていました。
Unity Package Manager が管理する情報はこの manifest.json にまとめられます。
なお、直接 manifest.json 上にインポートしたいパッケージを書けば、次回プロジェクトを開いたときに自動インストールされるようです。

https://docs.unity3d.com/ja/2019.4/Manual/upm-manifestPrj.html

```json
UnitySample_AdderUser/Packages on  feature/import-sampleadder-from-utm [!] [☁️ ] took 18s
❯ cat manifest.json -p
{
  "dependencies": {
    "com.ganyariya.adderpackage": "https://github.com/ganyariya/UnitySample_Adder.git?path=/Packages/com.ganyariya.adderpackage",
    "com.unity.ai.navigation": "2.0.9",
    "com.unity.collab-proxy": "2.10.0",
    "com.unity.ide.rider": "3.0.38",
    "com.unity.ide.visualstudio": "2.0.25",
    "com.unity.inputsystem": "1.14.2",
```

SampleAdder パッケージをインポートした PR は以下になります。

https://github.com/ganyariya/UnitySample_AdderUser/pull/1

## 余談: パッケージがローカルマシン上のどこに保存されるか

ちなみに、 UnitySample_AdderUser 上で Adder.cs を開くと `UnitySample_AdderUser/Library/PackageCache` に存在しました。

![Imgur](https://i.imgur.com/VstJdFL.png)

複数のプロジェクトをまたいで利用するかつ変更しないものについてはグローバルキャッシュ (mac であれば `~/Library/Unity/cache`) に配置されます。
そして、今回のような git url のものは Project/Library/PackageCache へ配置されるようです。

```bash
❯ pwd
/Users/ganyariya/Library/Unity/cache/packages/packages.unity.com

cache/packages/packages.unity.com [☁️ ]
❯ ls
 com.unity.addressables@1.19.19      com.unity.ide.vscode@1.2.5                 com.unity.test-framework@1.1.33
 com.unity.burst@1.8.18              com.unity.inputsystem@1.7.0                com.unity.textmeshpro@3.0.6
 com.unity.collab-proxy@2.5.2        com.unity.mathematics@1.2.6                com.unity.timeline@1.6.5
 com.unity.ext.nunit@1.0.6           com.unity.nuget.newtonsoft-json@3.2.1      com.unity.visualscripting@1.9.4
 com.unity.ide.rider@3.0.31          com.unity.scriptablebuildpipeline@1.20.1
 com.unity.ide.visualstudio@2.0.22   com.unity.searcher@4.9.1
```

```bash
UnitySample_AdderUser/Library/PackageCache on  main [!] [☁️ ]
❯ ls
 com.ganyariya.adderpackage@3a23e91f5544     com.unity.render-pipelines.core@04755ad51d99
 com.unity.ai.navigation@5218e4bf7edc        com.unity.render-pipelines.universal-config@8dc1aab4af1d
 com.unity.burst@1df634d836b8                com.unity.render-pipelines.universal@bc6f352be672
 com.unity.collab-proxy@1e5e48aff19d         com.unity.rendering.light-transport@2c9279f90d7c
 com.unity.collections@aea9d3bd5e19          com.unity.searcher@1e17ce91558d
 com.unity.ext.nunit@031a54704bff            com.unity.shadergraph@2c9221ffedf4
 com.unity.ide.rider@1f60b3138684            com.unity.test-framework.performance@0840f58e4562
 com.unity.ide.visualstudio@74aa435fc4bb     com.unity.test-framework@d97b7cd61ded
 com.unity.inputsystem@be6c4fd0abf5          com.unity.timeline@6b9e48457ddb
 com.unity.mathematics@8017b507cc74          com.unity.ugui@7056cb05de4c
 com.unity.multiplayer.center@f3fb577b3546   com.unity.visualscripting@b4d700247d4b
 com.unity.nuget.mono-cecil@d78732e851eb

```

## UnitySample_AdderUser プロジェクト側で Add メソッドを呼び出す

最後に UnitySample_AdderUser 側で Add メソッドを呼び出します。
UserAdder.cs を作成し、 UserAdderGameObject へアタッチします。

Play した結果正しく result が表示されました。

```cs
using Ganyariya.SampleAdder;
using UnityEngine;

public class UseAdder : MonoBehaviour
{
    [SerializeField] private int x;
    [SerializeField] private int y;
    
    void Start()
    {
        var adder = new Adder();
        var result = adder.Add(x, y);
        Debug.Log($"use adder package: x={x} + y={y} = {result}");
    }
}
```

![Imgur](https://i.imgur.com/bbPWyYG.png)

https://github.com/ganyariya/UnitySample_AdderUser/pull/2

# まとめ

- UnityPackageManager でインポートできるようなパッケージを作成したい場合 `package.json` を含むディレクトリを作成する
	- ライブラリ開発用 UnityProject の `Packages/[PackageName]` でつくるとよい
- GitHub 経由でインポートする場合は package.json の path を入力する

`Packages/[PackageName]` のように開発すると、利用者側は `?path=/Packages/[PackageName]` のように指定してインポートしないといけず面倒です。
`Packages/[PackageName]` 配下を submodule として開発し、そのまま配布する、というのも手なのかもしれませんね。

## 参考文献

https://note.ganyariya.dev/01_Note/Unity-%E3%81%AE-Package-%E3%82%92%E8%87%AA%E4%BD%9C%E3%81%97%E3%81%9F%E3%81%86%E3%81%88%E3%81%A7-git-%E7%B5%8C%E7%94%B1%E3%81%A7-UTM-%E3%81%A7%E8%A8%AD%E5%AE%9A%E3%81%99%E3%82%8B

https://www.hanachiru-blog.com/entry/2023/10/23/120000
