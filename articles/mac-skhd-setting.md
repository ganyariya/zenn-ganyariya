---
title: "skhd を設定するときに便利そうなイディオム"
emoji: "📑"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ["skhd", "shell", "terminal", "mac"]
published: true
---

# はじめに

先日、 yootaki さんの以下の記事を読んで yabai & skhd を使い始めました。

https://zenn.dev/yootaki/articles/d6ba758c63a315

もともと Rectangle というアプリを使っていたのですが、画像をみてかっこいい〜となり yabai へ乗り換えることにしました。

ショートカットバインドツールの skhd において、設定ファイルを書くときに便利なイディオムをまとめます。

# 設定ファイル

設定ファイル全体は長いため、アコーディオンに入れておきます。

 <!-- textlint-disable -->
:::details .skhdrc
```shell
# ******************************************
# Launch Applications
# ******************************************
ctrl + cmd - 0x24: osascript -e 'tell application "Notion" to run' \
  -e 'tell application "System Events"' \
  -e 'if visible of application process "Notion" is true then' \
  -e 'set visible of application process "Notion" to false' \
  -e 'else' \
  -e 'set visible of application process "Notion" to true' \
  -e 'end if' \
  -e 'end tell'
shift + cmd - 0x24: osascript -e 'tell application "Alacritty" to run' \
  -e 'tell application "System Events"' \
  -e 'if visible of application process "Alacritty" is true then' \
  -e 'set visible of application process "Alacritty" to false' \
  -e 'else' \
  -e 'set visible of application process "Alacritty" to true' \
  -e 'end if' \
  -e 'end tell'
shift + cmd - 0x01: osascript -e 'tell application "Slack" to run' \
  -e 'tell application "System Events"' \
  -e 'if visible of application process "Slack" is true then' \
  -e 'set visible of application process "Slack" to false' \
  -e 'else' \
  -e 'set visible of application process "Slack" to true' \
  -e 'end if' \
  -e 'end tell'
# ******************************************
# Focus Window
# ******************************************
alt - h: yabai -m window --focus west || yabai -m display --focus west
alt - l: yabai -m window --focus east || yabai -m display --focus east
alt - j: yabai -m window --focus south || yabai -m display --focus south
alt - k: yabai -m window --focus north || yabai -m display --focus north
alt - n: yabai -m window --focus next || yabai -m display --focus next
alt - p: yabai -m window --focus prev || yabai -m display --focus prev
# ******************************************
# Move Window between Displays
# ******************************************
ctrl + alt + cmd - left: yabai -m window --display prev \
  && yabai -m display --focus prev
ctrl + alt + cmd - right: yabai -m window --display next \
  && yabai -m display --focus next
# ******************************************
# Move Window in Same Display
# ******************************************
alt + cmd - left: yabai -m window --swap west
alt + cmd - right: yabai -m window --swap east
alt + cmd - up: yabai -m window --swap north
alt + cmd - down: yabai -m window --swap south
ctrl + shift - h: yabai -m window --resize left:-50:0 || yabai -m window --resize right:-50:0
ctrl + shift - l: yabai -m window --resize right:50:0 || yabai -m window --resize left:50:0
ctrl + shift - j: yabai -m window --resize bottom:0:20 || yabai -m window --resize top:0:20
ctrl + shift - k: yabai -m window --resize top:0:-20 || yabai -m window --resize bottom:0:-20
# ******************************************
# Focus Display
# ******************************************
alt - 0x2B: yabai -m display --focus prev \
  && yabai -m display --focus stack.prev
alt - 0x2F: yabai -m display --focus next \
  && yabai -m display --focus stack.next
# ******************************************
# Toggle FullScreen
# ******************************************
ctrl + alt + cmd - m: yabai -m window --toggle zoom-fullscreen
# ******************************************
# Mirror
# ******************************************
alt - y: yabai -m space --mirror y-axis
alt - x: yabai -m space --mirror x-axis
# ******************************************
# Rotate & Split & Balance & Toggle
# ******************************************
alt - r: yabai -m space --rotate 90
alt - e: yabai -m window --toggle split
alt - b: yabai -m space --balance
alt - t: yabai -m window --toggle float; \
  yabai -m window --grid 4:4:1:1:2:2
# ******************************************
# Restart
# ******************************************
ctrl + cmd + alt - r : \
    /usr/bin/env osascript <<< \
        "display notification \"Restarting Yabai\" with title \"Yabai\""; \
    launchctl kickstart -k "gui/${UID}/homebrew.mxcl.yabai"
```
:::
 <!-- textlint-enable -->

## アプリの起動

多くの shkd 設定ファイルだと `open /Applications/Notion.app` のようにして起動ショートカットを作っています。
しかし、この設定だと起動しかできず、開いたアプリを一度隠すということができません。

そこで、 `osascript` を叩いてアプリのトグルが行えるようにしました。
起動していないならアプリを立ち上げます。
また、見える位置にあるなら隠し、隠れているなら見えるようにします。

```shell
ctrl + cmd - 0x24: osascript -e 'tell application "Notion" to run' \
  -e 'tell application "System Events"' \
  -e 'if visible of application process "Notion" is true then' \
  -e 'set visible of application process "Notion" to false' \
  -e 'else' \
  -e 'set visible of application process "Notion" to true' \
  -e 'end if' \
  -e 'end tell'
```

osascript は複数行に渡るとき、`Enter` で改行しないとダメなのだと思っていましたが、`-e` を渡すと複数行に渡ってシングルラインで書けるんですね。
（どうして複数行のシングルラインで書く必要があるかというと、普通に複数行の osascript を書くと skhd のパースが失敗するためです。）

同じ起動コードを複数書いちゃっているので、あとでシェルスクリプトにしようと思います。

https://stackoverflow.com/questions/10022161/open-programs-with-applescript

## ウィンドウフォーカス

yabai 公式で設定されているウィンドウフォーカスは `alt - h: yabai -m window --focus west` の形式です。
しかし、これだとシングルディスプレイ内でしかフォーカスが移動できず、複数ディスプレイを移動できません。

以下のようにすると、`もし左側にウィンドウがないならば、左側のディスプレイにフォーカスする` を実現できます。
これは、`A || B` というコマンドを書くと、 A が失敗したらかわりに B を実行するという操作を実現できるためです。

```shell
alt - h: yabai -m window --focus west || yabai -m display --focus west
alt - l: yabai -m window --focus east || yabai -m display --focus east
alt - j: yabai -m window --focus south || yabai -m display --focus south
alt - k: yabai -m window --focus north || yabai -m display --focus north
alt - n: yabai -m window --focus next || yabai -m display --focus next
alt - p: yabai -m window --focus prev || yabai -m display --focus prev
```

## ウィンドウサイズ変更

先程とほぼ同じです。
yabai 公式のだとウィンドウサイズ変更について `increase`, `decrease` がそれぞれ別のショートカットで実現されているため、同じショートカットで実行できるようにしています。

```shell
alt + cmd - left: yabai -m window --swap west
alt + cmd - right: yabai -m window --swap east
alt + cmd - up: yabai -m window --swap north
alt + cmd - down: yabai -m window --swap south
ctrl + shift - h: yabai -m window --resize left:-50:0 || yabai -m window --resize right:-50:0
ctrl + shift - l: yabai -m window --resize right:50:0 || yabai -m window --resize left:50:0
ctrl + shift - j: yabai -m window --resize bottom:0:20 || yabai -m window --resize top:0:20
ctrl + shift - k: yabai -m window --resize top:0:-20 || yabai -m window --resize bottom:0:-20
```

## 再起動

yabai を再起動するときに使えます。

```shell
ctrl + cmd + alt - r : \
    /usr/bin/env osascript <<< \
        "display notification \"Restarting Yabai\" with title \"Yabai\""; \
    launchctl kickstart -k "gui/${UID}/homebrew.mxcl.yabai"
```

# 最後に

アプリバーなどをまだカスタマイズしてないので時間を見つけてしてみようと思います。

また、どうしても Neovim などの設定が弱くてかっこよさがないため、いろいろな方々の dotfiles をみてかっこよくしていきたいです。

# 参考にさせていただいたもの

https://zenn.dev/yootaki/articles/d6ba758c63a315

https://github.com/hackorum/.dotfiles

https://www.youtube.com/watch?v=-9gJH4K3fEQ
