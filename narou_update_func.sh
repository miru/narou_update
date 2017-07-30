#!/bin/bash
# -*- coding:utf-8 -*-

wait_other_script () {
    while  [ `ps -ef|grep "$NAROU"|grep -v grep|wc -l` -ge 1 ]
    do
        date "+--- %Y/%m/%d %H:%M:%S waiting other process ---"
        ps -ef | grep $NAROU | grep -v grep
        sleep 30
    done
}

get_narou_update_lock () {
    while [ -f $LOCKFILE ]
    do
        echo "INFO: Get lock for narou_update scripts"
        sleep 10
    done
    touch $LOCKFILE
    echo "INFO: Getted lock for narou_update scripts."
}

relese_narou_update_lock () {
    rm -f $LOCKFILE
    echo "INFO: Release lock for narou_update scripts."
}

tag_add_noconv () {
    UPD_ID=`egrep "DL開始" $1 | perl -pe 's/ID:(\d+).*/\1/g'`
    if [ ! "$UPD_ID" = "" ]; then
        $NAROU tag -a "$NOCONV_TAG" -c red $UPD_ID
    fi
}

tag_only_narou () {
    TAG="$1"
    NUM=`$NAROU list -t "$TAG" -sg "-小説家になろう" -e | egrep -v "(タイトル|^$)" | wc -l`
    if [ $NUM -eq 0 ]; then
        echo YES
    else
        echo NO
    fi
}

freeze_novel () {
    $NAROU freeze --on tag:end > /dev/null 2>&1
    $NAROU freeze --on tag:404 > /dev/null 2>&1
    $NAROU list -f ss | $NAROU freeze --on > /dev/null 2>&1
    $NAROU list -f ss | $NAROU tag -a "end" > /dev/null 2>&1
    $NAROU list -t 切 | $NAROU freeze --on > /dev/null 2>&1
    $NAROU list -t "end" | $NAROU tag -d "購読中 購読中な 購読中他" > /dev/null 2>&1
}

send_notification_for_update () {
    RES=`egrep "(DL開始|第[0-9]+部分.*\(新着\)|完結したようです|の更新はキャンセルされました|hotentry_.*.mobi を出力しました|は連載を再開したようです|(本好きの下剋上|ハンネローレ).*のDL開始)" $2`
    case "$NOTIFY_TYPE" in
        "PUSHBULLET")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/の更新はキャンセルされました/更新キャンセル/g' | \
        perl -pe 's/(.*) は連載を再開したようです/【再開】\1/g' | \
        perl -pe 's/^ID:(\d+)　/ID:\1 ■/g' | \
        perl -pe 's/(.*) \(新着\)$/　　【新】 \1/g' | \
        perl -pe 's/( のDL開始|第\d+部分　)//g' `
        send_notification "【更新】TAG:$1" "$BODY"
        ;;
        "LINE")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/の更新はキャンセルされました/更新キャンセル/g' | \
        perl -pe 's/(.*) は連載を再開したようです/【再開】\1/g' | \
        perl -pe 's/^ID:(\d+)　/ID:\1 ■/g' | \
        perl -pe 's/(.*) \(新着\)$/【新】 \1/g' | \
        perl -pe 's/( のDL開始|第\d+部分　)//g' `
        send_notification "【更新】TAG:$1" "$BODY"
        ;;
        "SLACK")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/^ID:(\d+)　(.*) の更新はキャンセルされました/:id:\1 \2 :broken_heart:/g' | \
        perl -pe 's/(.*) は連載を再開したようです/【再開:revolving_hearts:】\1/g' | \
        perl -pe 's/本好きの下剋上/:notebook_with_decorative_cover:本好きの下剋上:notebook_with_decorative_cover:/g' | \
        perl -pe 's/^ID:(\d+)　/:id:\1 :dizzy:/g' | \
        perl -pe 's/( |　)+/ /g' | \
        perl -pe 's/(.*) \(新着\)$/:new: \1/g' | \
        perl -pe 's/( のDL開始|第\d+部分 )//g' | \
        perl -pe 's/(hotentry_.*\.mobi を出力しました)/:red_circle:\1/g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/(^:id:[^(、|。)]+)(、|。).*\(完結\)/\1... :white_flower:/g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/\(完結\)/\...:white_flower:/g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/(^:id:[^(、|。)]+)(、|。).*/\1.../g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/(^:id:[^(～|ー|「|\-|（)].*)(～|ー|「|\-|（).*(～|ー|」|\-|）)/\1.../g' `
        send_notification ":bookmark:$1" "$BODY"
    esac
}

send_notification () {
    FLG=NG
    while [ $FLG = "NG" ]
    do
        case "$NOTIFY_TYPE" in
            "PUSHBULLET")
            send_notification_pushbullet "$1" "$2"
            ;;
            "LINE")
            send_notification_line "$1" "$2"
            ;;
            "SLACK")
            send_notification_slack "$1" "$2"
        esac
        if [ $? -eq 0 ]; then
            FLG=OK
        fi
    done
}

send_notification_pushbullet () {
    TITLE="$1"
    BODY=`echo "$2" | perl -pe 's/\n/\\\n/g'`
    /usr/bin/curl --header "Access-Token: $PUSHBULLET_TOKEN" --header "Content-Type: application/json" --data-binary "{\"title\":\"$TITLE\",\"body\":\"$BODY\",\"type\":\"note\"}" --request POST https://api.pushbullet.com/v2/pushes
}

send_notification_line () {
    TITLE="$1\n"
    BODY="$2"
    /usr/bin/curl https://notify-api.line.me/api/notify -X POST -H "Authorization: Bearer $LINE_TOKEN" -F "message=$TITLE$BODY"
}

send_notification_slack () {
    TITLE="$1\n"
    BODY="$2"
    /usr/bin/curl -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"narou.rb\", \"text\": \"$TITLE$BODY\", \"icon_emoji\": \":$SLACK_ICON:\"}" $SLACK_WEBHOOK
}

# EOF
