---
title: "Full Weak Engineer CTF 2025 ganyariya's Writeup"
emoji: "💬"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["ctf", "writeup"]
published: true
---

# はじめに

![](https://storage.googleapis.com/zenn-user-upload/57f0a7fb733d-20250901.png)

[Full Weak Engineer CTF 2025](https://ctf.fwectf.com/) に参加させていただきました。素敵なコンテストを開いていただきありがとうございました！

ganyariya は個人チーム srrr として参加し 271 位でした。もっと精進したいです。

![](https://storage.googleapis.com/zenn-user-upload/e65ca5078742-20250901.png)

この記事では ganyariya がコンテスト中に取り組んだ問題の Writeup を書きます。
なお、解けなかった問題については別途復習するためそちらについては[個人の Note](https://note.ganyariya.dev/) もしくは zenn で別途記載します。

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

`kentucky fried chicken 1065` で検索すると 1065 店舗目？の KFC が見つかります。
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
よって、問題文で与えられた絵文字列は `problem = encode(flag)` なものであり、これを `flag = decode(problem)` のように復元する `decode` メソッドを実装すればよいです。

## 解法

```bash
❯ python3 chall.py
msg: Hello!
enc: 🐴🙅🥬🍴🎉🚀🚀🚀
```

decode メソッドを実装するために、まずを chall.py を詳しくみてみます。

やっている処理は

1. 'Hello!' を .encode() で bytes に変換する
2. bytes を `8` の 2 進数に変換して join する
3. 10 bit 単位になるように padding する
4. 10 bit ごとに分割し、得られた 10bit ごとに整数に変換して絵文字テーブルから絵文字を取得する
5. 絵文字の数が 4 の倍数になるように末尾に :rocket: をつける

です。

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
k8s や docker によって `random-domain.chal3.fwectf.com:8004` が service 3000 port に紐づけられているのだとおもいます。

フラグを得るためには app2 の `toggle` Endpoint を呼び出す必要があります。
しかし、おそらくこの app2 のポートはインターネットに公開されておらず外部からはアクセスできません。

脆弱な実装として `app` の `/fetch` という Endpoint が公開されています。
この `/fetch` を利用すると `?url=hoge` として指定した url へ app server がリクエストを送ってくれます。
この場合リクエスト送信元が `app` という hono server となるため、 app → app2 という内部リクエストではファイアウォールブロックがされていない可能性が高いです。
よって、 `/fetch` Endpoint を利用して app2 の toggle を呼び出すとよさそうです。

このような攻撃方法を `SSRF(Server Side Request Forgery)` と呼ぶようです（はじめて知りました）。
脆弱な公開サーバをハックして、予期しない Server Side Request (HTTP) を発火させて内部サーバにアクセスします。

https://blog.tokumaru.org/2018/12/introduction-to-ssrf-server-side-request-forgery.html

https://zenn.dev/chot/articles/88ea57e3108978

ただし、 `const isAllowedURL = (u: URL) => u.protocol === "http:" && !["localhost", "0.0.0.0", "127.0.0.1"].includes(u.hostname)` というガードがかけられており、これらのエンドポイントではアクセスできません。

https://qiita.com/1ain2/items/194a9372798eaef6c5ab

コンテスト中に gemini に聞いたところ `lvh.me` というドメインがローカルアドレスとして解決される、とのことでした。
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

# datamosh

![](https://storage.googleapis.com/zenn-user-upload/c7c17163a70c-20250902.png)

壊れている AVI ファイルが与えられます。
mac で開こうとしたところ開けませんよ、とポップアップがでました。

そもそも datamosh とはメディアファイルを意図的に Audacity などで書き換えてグリッチエフェクトの入ったものにする、というものだそうです。

https://note.com/gtakuya/n/na67fd821b99f

strings などで中身を見ようとしましたがフラグが得られなかったため Audacity で音声ファイルとして読み込んだりしましたらこれもうまく動作しませんでした。
最終的に VLC Media Player で開いたところ再生でき、フラグが表示されました。

![](https://storage.googleapis.com/zenn-user-upload/01824eebb4f8-20250902.png)

## 学び

`VLC Media Player だと表示できることがある`

