---
title: "tmux っぽく VSCode を操作する"
emoji: "😺"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["tmux", "vscode"]
published: true
---

# 更新

#### 2021/12/10 

- サイドバーに関する tmux っぽい操作を追加しました
  - `sideBarFocus` で表現できます
- `!terminalFocus` を `editorFocus` に変更しました。
- エディタ操作についていくつか操作を追加しました。


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
    // ------------------------------------------------------------------
    // ------------------------------ Tmux ------------------------------
    // ------------------------------------------------------------------
    // ------------------------------ Tmux Editor ------------------------------
    {
        "key": "ctrl+a h",
        "command": "workbench.action.focusLeftGroup",
        "when": "editorFocus"
    },
    {
        "key": "cmd+k cmd+left",
        "command": "-workbench.action.focusLeftGroup"
    }, // Group Left Move
    {
        "key": "ctrl+a l",
        "command": "workbench.action.focusRightGroup",
        "when": "editorFocus"
    },
    {
        "key": "cmd+k cmd+right",
        "command": "-workbench.action.focusRightGroup"
    }, // Group Right Move
    {
        "key": "ctrl+a j",
        "command": "workbench.action.focusBelowGroup",
        "when": "editorFocus"
    },
    {
        "key": "cmd+k cmd+down",
        "command": "-workbench.action.focusBelowGroup"
    }, // Group Below Move
    {
        "key": "ctrl+a k",
        "command": "workbench.action.focusAboveGroup",
        "when": "editorFocus"
    },
    {
        "key": "cmd+k cmd+up",
        "command": "-workbench.action.focusAboveGroup"
    }, // Group Above Move
    {
        "key": "ctrl+a shift+\\",
        "command": "workbench.action.splitEditor",
        "when": "editorFocus"
    },
    {
        "key": "cmd+\\",
        "command": "-workbench.action.splitEditor"
    }, // Split Vertical
    {
        "key": "ctrl+a -",
        "command": "workbench.action.splitEditorOrthogonal",
        "when": "editorFocus"
    },
    {
        "key": "cmd+k cmd+\\",
        "command": "-workbench.action.splitEditorOrthogonal"
    }, // Split Horizon
    {
        "key": "ctrl+a shift+l",
        "command": "workbench.action.increaseViewWidth",
        "when": "editorFocus"
    },
    {
        "key": "ctrl+a shift+m",
        "command": "workbench.action.decreaseViewWidth",
        "when": "editorFocus"
    }, // group width increase or decrease
    {
        "key": "ctrl+a shift+j",
        "command": "workbench.action.increaseViewHeight",
        "when": "editorFocus"
    },
    {
        "key": "ctrl+a shift+k",
        "command": "workbench.action.decreaseViewHeight",
        "when": "editorFocus"
    }, // group height increase or decrease
    {
        "key": "ctrl+a x",
        "command": "workbench.action.closeActiveEditor",
        "when": "editorFocus"
    },
    {
        "key": "ctrl+a shift+x",
        "command": "workbench.action.closeEditorsAndGroup",
        "when": "editorFocus"
    }, // delete Editor
    {
        "key": "ctrl+a shift+[",
        "command": "workbench.action.moveEditorToPreviousGroup",
        "when": "editorFocus"
    },
    {
        "key": "ctrl+a shift+]",
        "command": "workbench.action.moveEditorToNextGroup",
        "when": "editorFocus"
    }, // current editor to (next|previous) group
    {
        "key": "ctrl+a n",
        "command": "workbench.action.focusNextGroup",
        "when": "editorFocus"
    },
    {
        "key": "ctrl+a p",
        "command": "workbench.action.focusPreviousGroup",
        "when": "editorFocus"
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
        "key": "ctrl+a z",
        "command": "workbench.action.maximizeEditor",
        "when": "editorFocus"
    }, // maximizeEditor
    // ------------------------------ Tmux Terminal ------------------------------
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
    }, // delete terminal
    {
        "key": "ctrl+a shift+k",
        "command": "workbench.action.terminal.resizePaneUp",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+a shift+j",
        "command": "workbench.action.terminal.resizePaneDown",
        "when": "terminalFocus"
    }, // change terminalSize
    {
        "key": "ctrl+a j",
        "command": "workbench.action.nextSideBarView",
        "when": "sideBarFocus"
    },
    {
        "key": "ctrl+a n",
        "command": "workbench.action.nextSideBarView",
        "when": "sideBarFocus"
    },
    {
        "key": "ctrl+a k",
        "command": "workbench.action.previousSideBarView",
        "when": "sideBarFocus"
    },
    {
        "key": "ctrl+a p",
        "command": "workbench.action.previousSideBarView",
        "when": "sideBarFocus"
    },
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
このとき、設定ファイルでは以下のように tmux / editor / sideBar を分けて設定します。
ターミナルを操作しているときは `terminalFocus` 側が実行されます。
エディタを操作しているときは `editorFocus` が実行されます。

```json
    {
        "key": "ctrl+a h",
        "command": "workbench.action.focusLeftGroup",
        "when": "editorFocus"
    },
    {
        "key": "ctrl+a h",
        "command": "workbench.action.terminal.focusPreviousPane",
        "when": "terminalFocus"
    }
```

ターミナル側では、ウィンドウグループのように上下には端末を切れないため、かなり少ない操作数しか用意していません。
それでもこれだけあればマウスなしですべて操作できそうな感じがでてとても精神上良いです。

![vscode-tmux-terminal](https://i.gyazo.com/2209c384d861d3c010bc152587470008.gif)

## サイドバー操作

サイドバーについても `ctrl+a n`, `ctrl+a p` などで次のサイドバーの項目へ移動できるようにしています。

# 最後に

今回は tmux っぽく VSCode を操作できるようにしました。
<!-- textlint-disable -->
tmux を使っている方はぜひ VSCode に tmux 操作を盛り込んでみると良いかな〜と思います。

VSCode の Powerline 文字化けしているの直さないとなぁ...
