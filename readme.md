# これはなに？
[narou.rb](https://github.com/whiteleaf7/narou/wiki)を使って小説を更新して通知するshell scriptです。

cronに仕込んでおいて自動更新→通知＋hotentry送信→新着読みみたいな事をしています。

通知方法は、Pushbullet、LINE、Slackを選べるようにしてみました。

私が動作させている環境はUbuntu 16.04jaですが、他のLinuxディストリビューションでもたぶん動きます。

他のOSでも日本語対応とUTF-8の文字コードが扱えれば動くんじゃないか？と思います。たぶん。

負荷軽減のため、narou update を実行する時は -n オプション（小説を変換しない）を付与しています。

小説の変換は narou_conv*.sh で変換します。

-n オプションがあっても hotentry は送信されるので差分を購読するスタイルでは問題になりません。

### narou_update_with_tag.sh
指定したタグが付いた小説を更新します。

使い方は至ってシンプルで、引数がそのままタグ名になります。

指定したタグがついていても凍結した小説は更新しません。

> narou_update_with_tag タグ名

favタグが付いた小説を更新する場合は

> narou_update_with_tag fav

という感じですね。

新着や更新があった小説に NOCONV_TAG で指定されたタグを付与します。デフォルトでは ”未変換” というタグが付きます。

### narou_update.settings
このスクリプトたちの設定ファイルです。環境変数であれこれ設定をします。

| 環境変数 |  説明 |  サンプル  |
|:----------------------  |:----------------  |:---------------------  | 
|   NAROU |  narou.rbのpathを指定します |  NAROU="$HOME/src/github/narou/narou.rb" | 
|   NAROU_DIR |  narou.rbをinitしたディレクトリを指定します |  NAROU_DIR=$HOME/narou | 
|   NOTIFY_TYPE |  通知のタイプを指定します。現在はPUSHBULLET・LINE・SLACKの3種どれかを指定します。 |  NOTIFY_TYPE=SLACK | 
|   PUSHBULLET_TOKEN |  Pushbulletのトークンを指定します。トークンは [https://www.pushbullet.com/#settings/account](https://www.pushbullet.com/#settings/account) から取得できます |  PUSHBULLET_TOKEN="PUSHBULLET TOKEN" | 
|   LINE_TOKEN |  LINEのトークンを指定します。トークンは [https://notify-bot.line.me/my/](https://notify-bot.line.me/my/) から取得できます |  LINE_TOKEN="LINE TOKEN" | 
|   SLACK_WEBHOOK |  SlackのIntegrationでIncoming WebHooksを追加して、Webhook URLを指定します。 |  SLACK_WEBHOOK="SLACK Incoming WebHooks Webhook URL" | 
|   NOCONV_TAG |  変換していない小説に付けるタグを指定します |  NOCONV_TAG="未変換" | 
|   NOSEND_TAG |  変換済みの小説に付けるタグを指定します |  NOSEND_TAG="未転送" | 
|   SLACK_CHANNEL |  通知にSlackを利用している場合、投稿するチャンネルを指定します |  SLACK_CHANNEL="#narou" | 
|   SLACK_ICON |  通知にSlackを利用している場合、アイコンを指定できます |   SLACK_ICON="books"  | 


### narou_conv_from_log.sh
現在存在する [narou.rb](https://github.com/whiteleaf7/narou/wiki) のログファイルから更新のあった小説IDを抽出して変換を行います。

### narou_conv_with_noconvtag.sh
設定ファイルの NOCONV_TAG で指定されたタグが付いた小説を変換します。

デフォルトでは ”未変換” というタグが付いた小説を変換することになります。

変換した小説から NOCONV_TAG で指定されたタグを削除し、NOSEND_TAG	で指定されたタグを付与します。

デフォルトでは "未変換" タグを削除して、"未転送" タグを付与するという動作になります。

私の利用方法の場合、1日1回程度 ”未転送” タグと ”Kindle” タグの両方が付いた小説を [narou.rb](https://github.com/whiteleaf7/narou/wiki) で Kindle PaperWhite に send しています。

### narou_update.sh
凍結されていない小説を一気に更新します。

タグを指定しない事を除けば、narou_update_with_tag.sh と同じです。

### narou_update_force.sh
凍結した小説も含めてすべてを一気に更新します。

凍結した小説も更新する事を除けば、narou_update_with_tag.sh と同じです。


### narou_update_func.sh
narou_updateのシェルスクリプトで利用する bash 関数を定義しています。

利用するだけなら実行も変更もしないと思います。

### narou_update_some_tag.sh
過去の残骸。スルーで。


### crontabサンプル的な
私はこんな感じで運用してます。crontab -l（抜粋）
```

2 0,7,11,18,19,20,23 * * * /home/miru/bin/narou_update_with_tag.sh 購読中 > /dev/null 2>&1

2 12 * * 0,6 /home/miru/bin/narou_update_with_tag.sh 購読中 > /dev/null 2>&1

*/5 12 * * 1-5 /home/miru/bin/narou_update_with_tag.sh fastcheck > /dev/null 2>&1

0-30/5 13 * * 1-5 /home/miru/bin/narou_update_with_tag.sh fastcheck > /dev/null 2>&1

2 9,14 * * * /home/miru/bin/narou_conv_with_noconvtag.sh > /dev/null 2>&1

2 21 * * * (/home/miru/bin/narou_update_with_tag.sh 購読中 ; /home/miru/bin/narou_update_with_tag.sh kindle ; /home/miru/bin/narou_conv_with_noconvtag.sh) > /dev/null 2>&1

2 1 * * 1-6 (/home/miru/bin/narou_update_with_tag.sh 購読中 ; /home/miru/bin/narou_update_with_tag.sh kindle ; /home/miru/bin/narou_update.sh ; /home/miru/bin/narou_conv_with_noconvtag.sh) > /dev/null 2>&1

2 1 * * 0 (/home/miru/bin/narou_update_with_tag.sh 購読中 ; /home/miru/bin/narou_update_with_tag.sh kindle ; /home/miru/bin/narou_update_force.sh ; /home/miru/bin/narou_conv_with_noconvtag.sh) > /dev/null 2>&1

31 0,14 * * * /usr/bin/find /home/miru/narou/hotentry -name hotentry\* -mtime 7 -exec rm {} \;
```

通常は、0,7,11,18,19,20,23時02分に ”購読中” タグが付いた小説を更新。

土日の12:02分も ”購読中” タグが付いた小説を更新。

平日12:00～13:30は ”fastcheck” タグが付いた小説を5分毎に更新（＝[本好きの下剋上](http://ncode.syosetu.com/n4830bu/)の更新を5分毎にチェック）

月～土の 1:02 に "購読中" → ”Kindle” タグが付いた小説を更新してから、全小説を更新して、”未変換” タグが付いた小説を変換。
できるだけ、hotentryをタグ毎に分けたかったので順番に実行しています。

日曜の 1:02 に "購読中" → ”Kindle” タグが付いた小説を更新してから、凍結も含めた全小説を更新して、”未変換” タグが付いた小説を変換。
できるだけ、hotentryをタグ毎に分けたかったので順番に実行しています。

毎日、1週間前のhotentryを削除します。

という感じ。

 **[本好きの下剋上](http://ncode.syosetu.com/n4830bu/)のために作りました。神に感謝を！神に祈りを！**
