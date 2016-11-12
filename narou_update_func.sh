#!/bin/bash
# -*- coding:utf-8 -*-

wait_other_script () {
    while  [ `ps -ef|grep "$NAROU"|grep -v grep|wc -l` -ge 1 ]
    do
        echo "---"
        date "+%Y/%m/%d %H:%M:%S waiting other process"
        ps -ef | grep $NAROU | grep -v grep
        sleep 30
    done
}

tag_add_noconv () {
    UPD_ID=`egrep "DL開始" $1 | perl -pe 's/ID:(\d+).*/\1/g'`
    if [ ! "$UPD_ID" = "" ]; then
        $NAROU tag -a $NOCONV_TAG -c red `echo $UPD_ID`
    fi
}

send_notification_for_update () {
    RES=`egrep "(DL開始|第[0-9]+部分.*\(新着\)|完結したようです|の更新はキャンセルされました)" $2`
    case "$NOTIFY_TYPE" in
        "PUSHBULLET")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/(.*) \(新着\)$/≫【新】 \1/g' | \
        perl -pe 's/の更新はキャンセルされました/更新キャンセル/g' | \
        perl -pe 's/( のDL開始|第\d+部分　)//g' `
        ;;
        "LINE")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/(.*) \(新着\)$/≫【新】 \1/g' | \
        perl -pe 's/の更新はキャンセルされました/更新キャンセル/g' | \
        perl -pe 's/( のDL開始|第\d+部分　)//g' `
        ;;
        "SLACK")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/^ID:/\n:id:/g' | \
        perl -pe 's/(:id:[0-9]+)　(.*) の更新はキャンセルされました/\1 :broken_heart: \2/g' | \
        perl -pe 's/(.*) \(新着\)$/≫:new: \1/g' | \
        perl -pe 's/( のDL開始|第\d+部分　)//g' `
    esac
    send_notification "$1" "$BODY"
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
    BODY=`echo "$2" | perl -pe 's/\n/\\\n/g'`
    /usr/bin/curl --header "Access-Token: $PUSHBULLET_TOKEN" --header "Content-Type: application/json" --data-binary "{\"title\":\"$1\",\"body\":\"$BODY\",\"type\":\"note\"}" \
    --request POST https://api.pushbullet.com/v2/pushes

}

send_notification_line () {
    /usr/bin/curl https://notify-api.line.me/api/notify -X POST -H "Authorization: Bearer $LINE_TOKEN" -F "message=$1
$2"
}

send_notification_slack () {
    curl -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"narou.rb\", \"text\": \"$1$2\", \"icon_emoji\": \":$SLACK_ICON:\"}" $SLACK_WEBHOOK
}

# EOF
