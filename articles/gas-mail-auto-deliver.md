---
title: "GASでカレンダーの予定をGmailで通知する"
emoji: "🌟"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["googleappsscript", "gmail"]
published: false
---

# はじめに

僕が所属する研究室では、毎週月曜日に「今週の予定」をお知らせするメールがラボメンに配信されます。
たとえば、ゼミの内容・輪講の内容・担当者がメールに掲載されます。
つまり、いわゆるお知らせ通知をメールで行っています。

このメールの中身は毎回 `Google Apps Scripts` (GAS) を用いて自動生成されています。
また、肝心の予定内容や時刻などは、研究室のカレンダーから取得して埋め込んでいます。

この記事では、 GAS でカレンダー情報を取得してメールを配信する方法についてまとめます。

# Google Apps Script

Google Apps Scripts は、 JavaScript の関数がトリガーをきっかけに実行できるサーバーレスな実行環境です。
FaaS の一種ですが、Google Cloud Functions とは大きく異なります。

まず、 GAS で使用できる言語は JavaScript のみです。
次に、トリガーが cron や手動などユーザ志向であり、おもに小規模向けです。
そして、 Gmail や Google Calender など Google のサービスと連携しやすいという特徴があります。

今回は、この GAS を用いて Google Calender と Gmail を連携します。

## 準備

以下のサイトで新しいプロジェクトを作ります。

https://script.google.com/home

以下の画像のように、デフォルトでは `無題のプロジェクト` という名前に設定されています。
そのため、プロジェクトの用途を分かりやすくするために `LabGmail` のようなプロジェクト名を変更するとよいです。

![](https://storage.googleapis.com/zenn-user-upload/g72dkgkdal3g4rgmhnakod6ar4vr)

エディタに新しく関数を書いて関数名を指定し、 `実行` ボタン (もしくは Command + R)を押すと関数が実行されます。
このように、 GAS は何らかのトリガーをもとに、関数が実行されるサービスになっています。
料金が心配になりますが、無料枠がかなり多いので安心です。

![](https://storage.googleapis.com/zenn-user-upload/1r88ceeo5mzpmnjyagpw0y2g2yf0)

先程、 `何らかのトリガー` とぼかして書きました。
つまり、トリガーが自由に設定できます。
たとえば、時間や Http(API リクエスト) をトリガーに設定できます。

以下の画像ように関数を指定すると、毎日午後 5, 6 時に関数 test が実行されます。

![](https://storage.googleapis.com/zenn-user-upload/2mjxzn68oihkbwpb95tc50himg53)

よって、あとは関数を詳細に書けば、自由にカレンダーや Google Document など自由に Google アプリを無料で操作できるようになります。

# Gmail と Calender の配信例

これまでの研究室のメール配信は以下のようなコードで行われていました。
かなり急いで書いたので、あまりきれいではないですが許してください。

```js

function sendWeeklyLabEvents() {
  function getTime(date){
    return Utilities.formatDate(date, 'JST', 'HH:mm');
  }
  function getDayString(date){
    return Utilities.formatDate(date, 'JST', 'YYYY/MM/dd (E)')
  }
  function getEachEventString(event){
      const title = event.getTitle()
      const dayString = getDayString(event.getStartTime());
      const hourString = `${getTime(event.getStartTime())} ~ ${getTime(event.getEndTime())}`;
      const description = `${event.getDescription()}`;
      const body = `
${dayString}  ${hourString}
${title}
${description}\n
`
      return body
  }

  const calenders = [
    CalendarApp.getCalendarById('YourCalenderID'),
  ]
  const today = new Date();
  const nextWeekDay = new Date();
  nextWeekDay.setDate(nextWeekDay.getDate() + 7);

  let all_events = []
  for (const calendar of calenders){
    const events = calendar.getEvents(today, nextWeekDay);
    all_events = all_events.concat(events);
  }
  all_events.sort((a, b) => {
    return a.getStartTime() - b.getStartTime()
  });


  const eventsBody = all_events.reduce((previous, event) => {
    return previous + getEachEventString(event);
  }, ``);

  const emailBody = `
研究室の皆様．

お世話になっております．
研究室の今週の予定について通知いたします．

===============================================
${eventsBody}
===============================================

このような予定になっております．
ご確認のほどよろしくお願いいたします．

  `;
  const addresses = [
    'lab1@example.com',
    'lab2@example.com',
    'lab3@example.com',
  ];

  MailApp.sendEmail({
    to: addresses.join(","),
    subject: '今週のゼミの予定について（リマインド）',
    body: emailBody
  })
}
```

コードの解説をおおまかにしていきます。

`sendWeeklyLabEvents` 関数を、時間ベースのトリガーとして設定します。
これによって、毎週メールが配信されます。

`CalendarApp.getCalendarById('YourCalenderID')`では、研究室のカレンダーのオブジェクトを取得します。
この ID は以下の画像のように、各カレンダーの詳細の、 `カレンダー ID` を指します。

![](https://storage.googleapis.com/zenn-user-upload/is5x3q0skhkq8cwljd5lxcee64q1)

以下のコードは、まずカレンダーの配列からカレンダーオブジェクトを取得します。
次に、 `getEvents` でカレンダーにおける一週間分の予定イベントを取り出し配列にマージします。
この処理は reduce を使うと楽そうですね。
あとは、 sort 関数に投げて開始時間が早い順になるよう並びかえます。

```js
  let all_events = []
  for (const calendar of calenders){
    const events = calendar.getEvents(today, nextWeekDay);
    all_events = all_events.concat(events);
  }
  all_events.sort((a, b) => {
    return a.getStartTime() - b.getStartTime()
  });
```

以下のコードでは、各取得したイベントを文字列に連結します。
`getEachEventString` 関数は　タイトルや日時、詳細を文字列にして返します。

```js
  const eventsBody = all_events.reduce((previous, event) => {
    return previous + getEachEventString(event);
  }, ``);
```

あとは MailApp で、配列に指定されているメアドに送信します。
これらの MailApp ならびに CalenderApp などは実行しようとすると、  Google のいつもの認証画面が出てくるため、 OK を押す必要があります。

これで大まかに毎週のカレンダーの予定を配信できます。
これまでは月曜日の朝５時ぐらいに配信するようにしていました。

![](https://storage.googleapis.com/zenn-user-upload/w4ma78ekstcb187f89q4bf2uv3zo)

# 注意点

Google はアメリカの企業なので、当然ながら JST ではないです。
そのためには、 `appsscript.json` を編集する必要があります。

**なぜか appscript.json はデフォルトでエディタに表示されない** ため、以下の画像のように表示されるよう設定します。

![](https://storage.googleapis.com/zenn-user-upload/x0vcc4pgda9q4gxcvz6y6ht9qe0t)

あとはエディタで、以下のように json を設定すると JST になります。

![](https://storage.googleapis.com/zenn-user-upload/hw2i15f9s49jf97e33u2r0nkm9vq)

```js
{
  "timeZone": "Asia/Tokyo",
  "dependencies": {
  },
  "exceptionLogging": "STACKDRIVER",
  "runtimeVersion": "V8"
}
```

# さいごに

毎週のカレンダーの予定を Gmail で配信する GAS についてまとめました。

今回のコードには以下のような悪い部分があります。

- 急いで書いていたので、可読性が悪く読みづらい
- メールアドレスを配列に直書きしているが、 Google Spread Sheet などにメールアドレスを書いて、シートを参照するほうがきれい
- そもそも GAS でなくても実現できそう (GAS が現状一番楽そうとはみています)

やっぱり最初から急がずに丁寧に書くべきでしたと反省しています。

今度は４年生の方が、メール配信を作成するようです。（世代交代）
オリジナルのあるメール配信、サービスが楽しみです＞＜。
