---
title: "tmux っぽく VSCode を操作する"
emoji: "😺"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["tmux", "vscode"]
published: true
---
# はじめに

この記事は Visual Studio Code Advent Calendar 2021 の 10 日目の記事です。

https://qiita.com/advent-calendar/2021/vscode

みなさんは tmux を使っていますか。
そう、あの tmux です（どれだよ）。
https://github.com/tmux/tmux

具体的には、 tmux は仮想的な端末多重化ソフトウェアです。
以下の画像のように、同時に複数の端末・ペインを手軽なショートカットで使えます。

![tmux image1](https://i.gyazo.com/90f2ec44f2480684eef244282b7cef3b.gif)
![tmux iamge2](https://i.gyazo.com/c58ea0ee03afaba091cabe822c183818.gif)

tmux のショートカットに慣れると、 VSCode も tmux っぽく操作したくなります。
というわけで、 VSCode のショートカット設定をいじって、 tmux のような操作ができるようにしました。

## 前設定

tmux っぽくいじる前に以下の設定を入れておくと幸せになります。
``ctrl + ` `` を入力すると、エディタとターミナルを行き来できるようになります。

（VSCode だと `when` を設定できるのでいいですね。）

```json
    // ------------------------------ Terminal ------------------------------
    {
        "key": "ctrl+`",
        "command": "workbench.action.terminal.focus"
    },
    {
        "key": "ctrl+`",
        "command": "workbench.action.focusActiveEditorGroup",
        "when": "terminalFocus"
    },
```

# VSCode の設定

<!-- textlint-disable -->
:::details 設定ファイル (json)
<!-- textlint-enable -->

```json
[
    // ------------------------------ Tmux ------------------------------
    {
        "key": "ctrl+a h",
        "command": "workbench.action.focusLeftGroup",
        "when": "!terminalFocus"
    },
    {
        "key": "cmd+k cmd+left",
        "command": "-workbench.action.focusLeftGroup"
    }, // Group Left Move
    {
        "key": "ctrl+a l",
        "command": "workbench.action.focusRightGroup",
        "when": "!terminalFocus"
    },
    {
        "key": "cmd+k cmd+right",
        "command": "-workbench.action.focusRightGroup"
    }, // Group Right Move
    {
        "key": "ctrl+a j",
        "command": "workbench.action.focusBelowGroup",
        "when": "!terminalFocus"
    },
    {
        "key": "cmd+k cmd+down",
        "command": "-workbench.action.focusBelowGroup"
    }, // Group Below Move
    {
        "key": "ctrl+a k",
        "command": "workbench.action.focusAboveGroup",
        "when": "!terminalFocus"
    },
    {
        "key": "cmd+k cmd+up",
        "command": "-workbench.action.focusAboveGroup"
    }, // Group Above Move
    {
        "key": "ctrl+a shift+\\",
        "command": "workbench.action.splitEditor",
        "when": "!terminalFocus"
    },
    {
        "key": "cmd+\\",
        "command": "-workbench.action.splitEditor"
    }, // Split Vertical
    {
        "key": "ctrl+a -",
        "command": "workbench.action.splitEditorOrthogonal",
        "when": "!terminalFocus"
    },
    {
        "key": "cmd+k cmd+\\",
        "command": "-workbench.action.splitEditorOrthogonal"
    }, // Split Horizon
    {
        "key": "alt+cmd+right",
        "command": "-workbench.action.nextEditor"
    },
    {
        "key": "ctrl+a shift+l",
        "command": "workbench.action.increaseViewWidth",
        "when": "!terminalFocus"
    },
    {
        "key": "ctrl+a shift+m",
        "command": "workbench.action.decreaseViewWidth",
        "when": "!terminalFocus"
    }, // group increase or decrease
    {
        "key": "ctrl+a x",
        "command": "workbench.action.closeActiveEditor",
        "when": "!terminalFocus"
    }, // delete Editor
    {
        "key": "ctrl+a shift+[",
        "command": "workbench.action.moveEditorToPreviousGroup",
        "when": "!terminalFocus"
    },
    {
        "key": "ctrl+a shift+]",
        "command": "workbench.action.moveEditorToNextGroup",
        "when": "!terminalFocus"
    }, // current editor to (next|previous) group
    {
        "key": "ctrl+a n",
        "command": "workbench.action.focusNextGroup",
        "when": "!terminalFocus"
    },
    {
        "key": "ctrl+a p",
        "command": "workbench.action.focusPreviousGroup",
        "when": "!terminalFocus"
    }, // current editor to (next|previous) group
    {
        "key": "ctrl+a [",
        "command": "workbench.action.terminal.searchWorkspace",
        "when": "terminalFocus && terminalProcessSupported && terminalTextSelected"
    },
    {
        "key": "ctrl+a [",
        "command": "workbench.action.findInFiles"
    },
    {
        "key": "ctrl+a [",
        "command": "workbench.view.search",
        "when": "workbench.view.search.active && neverMatch =~ /doesNotMatch/"
    }, // global serach
    {
        "key": "ctrl+a shift+\\",
        "command": "workbench.action.terminal.split",
        "when": "terminalFocus"
    }, // split terminal in same Pane
    {
        "key": "ctrl+a -",
        "command": "workbench.action.terminal.new",
        "when": "terminalFocus"
    }, // split terminal as New
    {
        "key": "ctrl+a n",
        "command": "workbench.action.terminal.focusNextPane",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+a p",
        "command": "workbench.action.terminal.focusPreviousPane",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+a l",
        "command": "workbench.action.terminal.focusNextPane",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+a h",
        "command": "workbench.action.terminal.focusPreviousPane",
        "when": "terminalFocus"
    }, // focus terminal in same pane
    {
        "key": "ctrl+a shift+n",
        "command": "workbench.action.terminal.focusNext",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+a shift+p",
        "command": "workbench.action.terminal.focusPrevious",
        "when": "terminalFocus"
    }, // focus terminal to next different pane
    {
        "key": "ctrl+a x",
        "command": "workbench.action.terminal.kill",
        "when": "terminalFocus"
    }, // focus terminal to next different pane
]
```

:::

設定ファイルは以上のようなものです。
かなり長いためアコーディオンにしてあります。

極力 tmux のきもちで操作できるようにしています。
基本的にはコードで書いてあるとおりですが、意識したポイントをまとめようと思います。

## prefix

ganyariya は tmux の prefix を `ctrl + a` にしている勢です。
デフォルトは確か `ctrl+b` でしたが、`b` が押しづらいので `a` に変更しています。

## エディタ操作

エディタウィンドウに関してはかなりデフォルトの tmux を意識しています。
特にグループ移動系はそれっぽく作れている気がします。

![vscode-tmux-move](https://i.gyazo.com/d51f4663dd4e0578f627a58702bcbed4.gif)

逆にまだ実現できていないことも多いです。
たとえば、`ctrl+s` のセッション一覧などは、そもそも VSCode にないため実現できていません。
同様に `ctrl+w` のウィンドウ一覧などもです。
ほかにも VSCode には操作できるコマンドが多くあるため、 tmux っぽいものを追加していこうと思います。

## ターミナル操作

ターミナルに関しても tmux 操作を設定します。
このとき、設定ファイルでは以下のように tmux / editor を分けて設定します。
ターミナルを操作しているときは `terminalFocus` 側が実行されます。
そうでないとき（エディタを操作しているとき）は `!terminalFocus` 側が実行されます。

```json
    {
        "key": "ctrl+a h",
        "command": "workbench.action.focusLeftGroup",
        "when": "!terminalFocus"
    },
    {
        "key": "ctrl+a h",
        "command": "workbench.action.terminal.focusPreviousPane",
        "when": "terminalFocus"
    }
```

ターミナル側では、ウィンドウグループのように上下には端末を切れないため、
かなり少ない操作数しか用意していません。
それでもこれだけあればマウスなしですべて操作できそうな感じがでてとても精神上良いです。

![vscode-tmux-terminal](https://i.gyazo.com/2209c384d861d3c010bc152587470008.gif)

# 最後に

今回は tmux っぽく VSCode を操作できるようにしました。
<!-- textlint-disable -->
tmux を使っている方はぜひ VSCode に tmux 操作を盛り込んでみると良いかな〜と思います。

VSCode の Powerline 文字化けしているの直さないとなぁ...
