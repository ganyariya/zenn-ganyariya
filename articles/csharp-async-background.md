---
title: "C# の非同期処理について不自由さ克服のための移り変わりから学ぶ"
emoji: "🌊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: true
---

下記ノートをもとに、 AI にまとめてもらいながらこちらの記事を執筆しています。
修正点・不明点があればぜひコメントください。

https://note.ganyariya.dev/01_Note/CSharp-%E3%81%AE-Thread-%E2%86%92-Task-%E2%86%92-async-await-%E3%81%B8%E7%A7%BB%E3%82%8A%E5%A4%89%E3%82%8F%E3%81%A3%E3%81%9F%E7%B5%8C%E7%B7%AF%E3%82%92%E4%B8%8D%E8%87%AA%E7%94%B1%E3%81%95%E3%81%8B%E3%82%89%E8%BF%BD%E3%81%86

## この記事について

C#で非同期処理を書くとき、今では async/await を使うのが当たり前になっています。
async/await が発生した経緯や Task Thread とどう異なるかについて見ていきます。

### 対象読者

C#で非同期処理を書いたことがある方、特に async/await は使っているけど内部でどう動いているのかよく分からないほうを想定しています。Unity を使っているほうなら、コルーチンとの違いが気になっているほうにも参考になると思います。

### この記事で扱うこと・扱わないこと

- 扱うこと
    - Thread、Task、async/await それぞれの特徴と課題
    - なぜ次の手法が必要になったのかという進化の経緯
    - async/await が従来の方法と根本的に異なる点

- 扱わないこと
    - ConfigureAwait、CancellationToken などの詳細な使い方
    - パフォーマンスチューニングの具体的なテクニック
    - ValueTask などの発展的なトピック

それでは、まず前提知識として同期処理と非同期処理について整理しておきましょう。

## 前提知識：同期処理と非同期処理、そして並行と並列

非同期処理を語る前に、用語を整理しておく必要があります。特に「非同期処理」と「並列処理」を混同してしまうと、後の説明が理解しづらくなってしまいます。

### 同期処理と非同期処理

同期処理は、プログラムが上から下へ順番に実行される処理方式です。ある処理が終わるまで次の処理には進みません。一方、非同期処理では、ある処理 X を待たずに他の処理 Y、Z、W へ進むことができます。

ここで重要なのは、**非同期処理の「実現方法」自体は定義されていない**という点です。別スレッドで実行する方法もあれば、I/O 待機を活用する方法もあります。「非同期」というのはあくまで「待たない」という結果を表しているだけで、どうやって実現するかは別の話なんです。

### 並行処理と並列処理の違い

この 2 つを混同すると話がややこしくなるので、しっかり区別しておきましょう。

まず大前提として、**1 つの CPU コアは、ある 1 時点において 1 つのスレッドしか実行できません**。これは物理的な制約です。

並行処理（Concurrency）は、単一の CPU コアで複数のタスクを細かく切り替えながら実行することで、あたかも同時に動いているように見せる処理方式です。OS スケジューラが非常に短い時間で処理を切り替える（これをコンテキストスイッチと呼びます）ことで実現されています。複数のアプリケーションを同時に使えているように感じるのは、このおかげです。

一方、並列処理（Parallelism）は、複数の CPU コアで同時に処理を実行する方式です。
現代の CPU はマルチコアが当たり前なので、重い処理を複数のスレッドに分割して各コアで同時実行すれば、処理を高速化できます。

### スレッドとプロセスの関係

プロセスは実行中のプログラム本体で、独立したメモリ空間を持ちます。スレッドはプロセス内の実行単位で、1 つのプロセスは複数のスレッドを持つことができます。スレッド同士はメモリ空間を共有するため、データのやり取りが比較的簡単です。

ここで重要なのは、**CPU に割り当てられるのは実はスレッド単位**だということです。4 コアの CPU があって、1 つのプロセスが 4 つのスレッドを持っていれば、理想的には各コアが 1 つずつスレッドを処理できます。

### 非同期 ≠ 並列という誤解

よくある誤解として「非同期処理 = 並列処理」というものがありますが、正確ではありません。

非同期処理の実現方法は様々です。
CPU バウンドな重い処理を別スレッドに流してマルチコアで実際に同時実行させる場合もあります。
一方で、I/O 待機（ネットワーク通信、ファイル読み込みなど）を OS に移譲して、メインスレッドはその間に UI を更新する場合もあります。
前者は並列処理、後者は並行処理です。

また、「同期処理でも並列処理は可能」という点も押さえておきましょう。例えば、メインスレッドがサブスレッドの完了を待つ場合、メインスレッド視点では同期的に見えますが、実際にはマルチコアで並列実行されています。どの視点で処理を見るかによって、同期か非同期かの判断が変わるんです。

さて、前提知識を整理したところで、C#の非同期処理の歴史を見ていきましょう。

## C# 1.0時代：Threadクラスの課題

C# 1.0 から存在する Thread クラスは、もっとも基本的なスレッド操作の手段です。しかし、実際に使ってみると様々な問題に直面します。

### Threadで非同期処理を書いてみる

Unity の MonoBehaviour を例に、Thread を使った非同期処理を見てみましょう。

```csharp
using System;
using System.Threading;
using UnityEngine;

public class AsyncAwait_Thread : MonoBehaviour
{
    void Start()
    {
        Debug.Log($"Main Thread ID: {Thread.CurrentThread.ManagedThreadId}");

        Action finalCallback = () =>
        {
            Debug.Log($"Final Callback ID: {Thread.CurrentThread.ManagedThreadId}");
            Debug.Log("Final callback executed");
        };

        Action threadBCallback = () =>
        {
            Debug.Log($"Thread B ID: {Thread.CurrentThread.ManagedThreadId}");
            Debug.Log("Thread B Start");
            Thread.Sleep(5000);
            Debug.Log("Thread B End");
            finalCallback();
        };

        Action threadACallback = () =>
        {
            Debug.Log($"Thread A ID: {Thread.CurrentThread.ManagedThreadId}");
            Debug.Log("Thread A Start");
            Thread.Sleep(5000);
            Debug.Log("Thread A End");

            var threadB = new Thread(new ThreadStart(threadBCallback));
            threadB.Start();
            threadB.Join();
        };

        var threadA = new Thread(new ThreadStart(threadACallback));
        threadA.Start();

        Debug.Log("Start method called");
    }
}
```

![Imgur](https://i.imgur.com/pyn3kmt.png)

このコードを見ると、処理 A と B を順番に実行したいだけなのに、コールバックがネストして読みづらくなっています。これがいわゆる「コールバック地獄」です。

### Threadの何が問題だったのか

Thread を使った非同期処理には、いくつかの致命的な問題がありました。

まず、コールバック地獄です。処理を連鎖させようとするとネストがどんどん深くなり、コードの可読性が著しく低下します。上のコードでも、処理の流れを追うのが大変だと感じたのではないでしょうか。

次に、値の受け渡しが面倒です。スレッド間でデータをやり取りするには、共有変数を使ったり、コールバックの引数として渡したりする必要があります。しかし、共有変数を使うと排他制御（ロック）の問題が発生しますし、コールバックで渡すとさらにネストが深くなります。

さらに、リソース管理の負担が大きいです。スレッドの生成と破棄は重い処理なので、頻繁にスレッドを作ったり消したりするとパフォーマンスに悪影響が出ます。開発者が自分でスレッドのライフサイクルを管理しなければならないのは、かなりの負担です。

最後に、エラーハンドリングが困難です。別スレッドで発生した例外をメインスレッドで捕捉するのは簡単でなく、適切なエラー処理を実装するのが難しいです。

こうした問題を解決するために、次の段階として Task が登場します。

## C# 4.0時代：Taskによる改善とその限界

Thread の課題を解決するため、C# 4.0 で Task が導入されました。もっとも重要な改善点は、スレッドプールの活用です。

### スレッドプールという発明

Thread の問題点の 1 つは、スレッドの生成と破棄が重い処理だということでした。Task では、.NET ランタイムがスレッドプールを管理してくれます。

スレッドプールは、あらかじめ作成された再利用可能なスレッドの集まりです。Task.Run を実行すると、スレッドプールから適切なスレッドが割り当てられ、処理が終わったらそのスレッドはプールに戻されます。スレッドを毎回生成・破棄する必要がないため、パフォーマンスが大幅に向上します。

開発者はスレッドの管理を意識する必要がなくなり、より高レベルな抽象化によって使いやすくなりました。これは大きな前進でした。

### Taskで非同期処理を書いてみる

先ほどの Thread の例を Task で書き直してみましょう。

```cs
using System;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

public class AsyncAwait_Task : MonoBehaviour
{
    int TaskA(int initialValue)
    {
        Debug.Log($"Task A ID: {Thread.CurrentThread.ManagedThreadId}");
        Debug.Log("Task A Start");
        Thread.Sleep(5000);

        int result = initialValue + 1;

        Debug.Log($"Task A ID: {Thread.CurrentThread.ManagedThreadId}");
        Debug.Log($"Task A End with result: {result}");

        return result;
    }

    int TaskB(int resultA)
    {
        Debug.Log($"Task B ID: {Thread.CurrentThread.ManagedThreadId}");
        Debug.Log("Task B Start");
        Thread.Sleep(5000);

        int result = resultA * 2 + 2;
        Debug.Log($"Task B ID: {Thread.CurrentThread.ManagedThreadId}");
        Debug.Log($"Task B End with result: {result}");
        return result;
    }

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        Debug.Log($"Main Thread ID: {Thread.CurrentThread.ManagedThreadId}");

        int initialValue = 100;

        // TaskA をスレッドプール上の任意のスレッドで実行してもらう
        Task<int> taskA = Task.Run(() => TaskA(initialValue));

        // TaskA が完了したら ContinueWith で与えたコールバック関数を実行してもらう、ということを指示する
        Task<int> taskB = taskA.ContinueWith(tA =>
        {
            if (tA.IsFaulted)
            {
                Debug.Log("Task A Failed");
                // return 0; // エラー処理が面倒
                return Task.FromException<int>(tA.Exception.InnerException);
            }

            Debug.Log("Task A Succeeded");
            int resultA = tA.Result;

            // TaskB を起動する
            return Task.Run(() => TaskB(resultA));
        }).Unwrap();

        Task finalTask = taskB.ContinueWith(tB =>
        {
            if (tB.IsFaulted)
            {
                Debug.Log("Task B Failed");
                return;
            }

            Debug.Log("Final Task");
            Debug.Log($"Final callback id: {Thread.CurrentThread.ManagedThreadId}");
            Debug.Log($"Final result: {tB.Result}");
            Debug.Log("Start method is done");
        });
        // finalTask は裏のスレッドプールで走らせる
        // finalTask.Wait(); を実行してしまうと、Unity Start メソッドが終わらず１０ｓゲームが遊べない

        Debug.Log("Calling Start method");
    }
}
```

![Imgur](https://i.imgur.com/gLBF97f.png)

Thread に比べればマシになりましたが、まだ問題が残っています。

### Taskでも解決できなかった課題

ContinueWith を使った処理の連鎖は、JavaScript の Promise に似た書き方です。
Thread よりは読みやすくなりましたが、依然としてコールバックのネストが発生します。処理の流れを追うのが難しいという問題は、完全には解決されていません。

エラー処理も煩雑です。IsFaulted を手動でチェックする必要があり、try/catch のような直感的な例外処理ができません。エラーハンドリングのコードが処理のあちこちに散らばってしまい、保守性が低下します。

「もっと同期処理のように、上から下へ順番に書けないだろうか」という要望に対して、Task だけでは不十分でした。そこで登場したのが async/await です。

### Taskの本質：非同期操作の抽象化

ここで重要な概念を押さえておきましょう。**Task クラス自体は、単に非同期操作を表現するためのクラス**であり、必ずしもスレッドプールで実行される必要はありません。

Task.Run で呼び出せば、スレッドプールの別スレッドで実行されます。しかし、次に説明する async/await で使えば、必ずしも別スレッドで実行されるわけではありません。Task はあくまで「非同期処理を扱うためのメッセージクラス」であり、その実行方法は呼び出し方によって変わるんです。

この「Task は実行方法を規定しない」という性質が、async/await で重要な意味を持ってきます。

## C# 5.0時代：async/awaitによる革命

async/await は、非同期処理のコードを同期処理のように書ける革命的な機能です。Thread、Task と比べて何が違うのか、順を追って見ていきましょう。

### async/awaitで非同期処理を書いてみる

同じ処理を async/await で書き直してみます。

```cs
using System;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

public class AsyncAwait_AsyncAwait : MonoBehaviour
{
    async Task<int> TaskA(int initialValue)
    {
        // ここも 1 になることに注意する（メインスレッド）
        Debug.Log($"Task A ID: {Thread.CurrentThread.ManagedThreadId}");
        Debug.Log("Task A Start");

        // ここまで Unity メインスレッドで実行される
        // await が呼び出されると、一時的に処理を中断し Unity メインスレッドを他の GameObject へ返す
        await Task.Delay(5000);

        // 5s 経過すると Unity メインスレッドでそのまま処理が再開される
        int result = initialValue + 1;

        // ここも 1 になることに注意する（メインスレッド）
        Debug.Log($"Task A ID: {Thread.CurrentThread.ManagedThreadId}");
        Debug.Log($"Task A End with result: {result}");

        return result;
    }

    async Task<int> TaskB(int resultA)
    {
        Debug.Log($"Task B ID: {Thread.CurrentThread.ManagedThreadId}");
        Debug.Log("Task B Start");
        await Task.Delay(5000);

        int result = resultA * 2 + 2;
        Debug.Log($"Task B ID: {Thread.CurrentThread.ManagedThreadId}");
        Debug.Log($"Task B End with result: {result}");
        return result;
    }

    async Task CannotCreateGameObjectWithoutMainThread()
    {
        // Unity メインスレッドの場合は実行できる
        new GameObject("hoge");
    }

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    async void Start()
    {
        Debug.Log($"Main Thread ID: {Thread.CurrentThread.ManagedThreadId}");

        int initialValue = 100;

        int resultB = -1;
        try
        {
            // TaskA(initialValue) によって TaskA メソッドの処理が開始される
            // TaskA メソッド内の await が実行されるまで、 TaskA は Unity メインスレッドでそのまま実行される
            // TaskA メソッド内の await が実行されたら一時的に処理を中断し、Start メソッドは一時中断となる
            // → これによって Unity UI が固まることなく TaskA 5s 待機を実現できる
            var resultA = await TaskA(initialValue);

            // 5s 経過して TaskA が完了すると、 Unity メインスレッド が再度次の行の実行を再開する
            resultB = await TaskB(resultA);

            await CannotCreateGameObjectWithoutMainThread();
        }
        // 例外処理が try/catch で書けるため楽
        catch (Exception e)
        {
            throw new Exception($"Error {e.Message}");
        }

        await Task.Run(() =>
        {
            Debug.Log("Final Task");
            Debug.Log($"Final callback id: {Thread.CurrentThread.ManagedThreadId}");
            Debug.Log($"Final result: {resultB}");
            Debug.Log("Start method is done");
        });

        Debug.Log("Calling Start method");
    }
}
```

![Imgur](https://i.imgur.com/hx79t57.png)

コードがシンプルになりました。上から下へ順番に読め、かつ try/catch で例外処理もできます。これが async/await の威力です。

### async/awaitの驚くべき動作

上記のコードを実行すると、TaskA/TaskB が**メインスレッド（Thread ID: 1）で実行されている**ことに気づくはずです。これは、Task.Run の例とは大きく異なります。Task.Run では別スレッドで実行されていたのに、async/await ではメインスレッドで実行されているんです。

これは一体どういうことでしょうか。

### awaitの魔法：処理の中断と再開

await の動作メカニズムを理解するのが、async/await の本質を掴む鍵です。

`await Task.Delay(5000)`が実行されると、TaskA メソッドの処理が**一時中断**されます。ここが重要なポイントです。別スレッドに処理を投げるのではなく、今いるスレッド（この場合はメインスレッド）での処理を一時的に止めるんです。

処理が中断されると、メインスレッドが解放されます。Unity は、その間に他の GameObject の Start メソッドや UI 更新などを処理できます。メインスレッドは遊んでいるわけではなく、他の仕事をしているんです。

5 秒経過後、**メインスレッド上**で処理が再開されます。別スレッドに移動するわけではありません。中断した場所から、同じスレッドで続きを実行します。

これが、Thread や Task.Run との根本的な違いです。Thread や Task.Run は「別のスレッドで実行する」という並列処理のアプローチでしたが、async/await は「処理を中断して他の仕事をする」という並行処理のアプローチなんです。

### SynchronizationContextという仕組み

「なぜ await の後もメインスレッドで実行されるのか」という疑問が湧くかもしれません。これは**SynchronizationContext**という仕組みによるものです。

Unity のような環境では、await の後続処理は自動的にメインスレッドで実行されるように設定されています。これにより、UI 操作や GameObject の生成など、メインスレッドでしか実行できない処理を安全に行えます。

もし async/await が単にスレッドプールで実行される仕組みだったら、Unity では使い物になりません。Unity の API はメインスレッドからしか呼べないものが多いからです。SynchronizationContext のおかげで、async/await は Unity でも安全に使えるんです。

### C#コンパイラの魔法：ステートマシン

「処理を中断して再開する」なんて、普通の C#のコードではできません。これはどうやって実現されているのでしょうか。

答えは、C#コンパイラが**ステートマシン**を利用したコードに自動変換しているからです。async/await を使ったコードは、コンパイル時に複雑なステートマシンのコードに書き換えられます。このステートマシンが、処理の中断と再開を実現しているんです。

開発者はステートマシンを意識する必要はありません。async/await という簡潔な構文で書けば、コンパイラが全部やってくれます。これが async/await の素晴らしいところです。

### Task.Runとasync/awaitの使い分け

ここまでの説明をまとめると、Task.Run と async/await は実行方法が根本的に異なります。

Task.Run は、スレッドプールの別スレッドで実行されます。CPU バウンドな重い計算処理に向いています。例えば大量のデータを処理する、重い処理を計算する、といった場合です。

async/await は、呼び出し元のスレッド（多くの場合メインスレッド）で実行されます。I/O 待機など、CPU を使わない待機処理に向いています。例えば、ネットワーク通信を待つ、ファイルの読み込みを待つといった場合です。

```csharp
// CPUバウンドな処理：Task.Runで別スレッドへ
await Task.Run(() => {
    // 重い計算処理
    for (int i = 0; i < 1000000; i++) { /* ... */ }
});

// I/Oバウンドな処理：async/awaitのみ
await Task.Delay(5000);  // メインスレッドを解放して5秒待機
```

この使い分けを理解していないと、async/await を使っているのにメインスレッドがブロックされてしまう、といった問題が起きます。

## なぜasync/awaitが必要だったのか

ここまで、Thread → Task → async/await の進化を見てきました。最後に、なぜ async/await が必要だったのか、あらためて整理しておきましょう。

### コールバック地獄からの解放

Thread では、処理を連鎖させるとコールバックがネストして可読性が著しく低下しました。Task でも、ContinueWith を使った書き方は依然として読みづらいものでした。

async/await は、この問題を根本的に解決しました。非同期処理を同期処理のように、上から下へ書けるようになったんです。これは単なる糖衣構文ではなく、コンパイラによるステートマシンの自動生成という強力な仕組みによって実現されています。

### 例外処理の自然な統合

Thread ではエラーハンドリングが困難で、Task でも手動でチェックする必要がありました。
async/await において、try/catch で自然に例外処理を書けます。同期処理と同じように扱えるため、学習コストも低く、ミスも減ります。

### メインスレッドの効率的な利用

Thread や Task.Run は、別スレッドで処理を実行するアプローチでした。しかし、Unity のようなメインスレッドでしか実行できない API が多い環境では、これは使いづらいものでした。

async/await は、処理を中断してメインスレッドを解放するアプローチです。I/O 待機中にメインスレッドを有効活用でき、Unity のようなシングルスレッド中心の環境でも自然に使えます。SynchronizationContext によって、await の後も適切なスレッドで処理が再開されるため、安全です。

### 非同期処理の実現方法が増えた

Thread は並列処理でしか非同期を実現できませんでした。Task はスレッドプールという改善がありましたが、基本的には並列処理です。

async/await は、並行処理によって非同期を実現する新しいアプローチを提供しました。これにより、I/O バウンドな処理でも効率的に非同期処理が書けるようになったんです。CPU バウンドな処理は Task.Run で並列実行し、I/O バウンドな処理は async/await で並行実行する、という使い分けができるようになりました。

## おわりに

C#の非同期処理は、Thread → Task → async/await と進化してきました。それぞれの時代で何が課題だったのか、なぜ次の手法が必要になったのかを理解すると、async/await の素晴らしさがより深く分かると思います。

Thread は低レベルなスレッド操作で、コールバック地獄やリソース管理の負担が課題でした。Task はスレッドプールによる効率化で改善しましたが、依然として処理の連鎖が煩雑でした。async/await は、コンパイラによるステートマシンの自動生成という強力な仕組みによって、非同期処理を同期処理のように書けるようにしました。

重要なのは、Task は非同期操作の抽象化であり、呼び出し方によって実行方法が変わるということです。Task.Run はスレッドプールを使った並列処理、async/await は処理の中断・再開による並行処理を実現します。

現代の C#開発では、async/await を使った非同期処理が標準になっています。でも、その背後にある仕組みを理解することで、より適切に使いこなせるようになるはずです。

## 参考資料

より詳しく学びたいほうは、以下の資料がおすすめです。

- [C# の async/await の仕組み](https://blog.neno.dev/entry/2023/05/27/152855)
- [Unity における async/await の活用](https://www.docswell.com/s/DeNA_Tech/ZP239L-unitycommunity-05)
- [Unity 向け Awaiter の実装](https://zenn.dev/meson_tech_blog/articles/implement-awaiter-for-unity)
- [async/await の詳細解説](https://annulusgames.com/blog/async-await/)

## 最後に (ganyariya)

個人的には自分自身の書き方のほうが好きですね...。
自分の他記事を食わせてその Syntax で書けないか今度ためしてみようとおもいます。
