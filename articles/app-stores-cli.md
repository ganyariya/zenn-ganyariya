---
title: "AppStoreのアプリをCLIでインストールする"
emoji: "🙆"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['AppStore', 'dotfiles']
published: true
---

# はじめに

最近Macがいい感じに壊れたので、クリーンインストールしました。
このとき、自分の [dotfiles](https://github.com/Ganariya/dotfiles)を利用しました。

その後、AppStoreにしかないアプリを手動でインストールしました。
brewにないものは手動しかないと思っていましたが、CLIでAppStoreのアプリをインストールできるものがあったので紹介します。

# mas

[mas](https://github.com/mas-cli/mas)CLIはAppStoreのアプリを一括でインストールできます。
使い方はREADMEにすべて書いてあります。
使いづらい点としては、インストールするために`ID`を検索しないといけない点ですね...

dotfilesでインストールを自動化しています。

```bash:install.sh
stores=(
    497799835
    539883307
    937984704
    975890633
    1144071713
    1295203466
    1423210932
    1429033973
    1450950860
    1483764819
)


echo "app stores"
for store in "${stores[@]}"; do
    mas install $store
done
```

`mas install ID`でAppStoreのアプリがインストールできて嬉しいですね。




