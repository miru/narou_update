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

tag_add_noconv () {
    UPD_ID=`egrep "DL開始" $1 | perl -pe 's/ID:(\d+).*/\1/g'`
    if [ ! "$UPD_ID" = "" ]; then
        $NAROU tag -a $NOCONV_TAG -c red $UPD_ID
    fi
}

send_notification_for_update () {
    RES=`egrep "(DL開始|第[0-9]+部分.*\(新着\)|完結したようです|の更新はキャンセルされました|本好きの下剋上.*のDL開始)" $2`
    case "$NOTIFY_TYPE" in
        "PUSHBULLET")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/の更新はキャンセルされました/更新キャンセル/g' | \
        perl -pe 's/^ID:(\d+)　/ID:\1 ■/g' | \
        perl -pe 's/(.*) \(新着\)$/　　【新】 \1/g' | \
        perl -pe 's/( のDL開始|第\d+部分　)//g' `
        send_notification "$1" "$BODY"
        ;;
        "LINE")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/の更新はキャンセルされました/更新キャンセル/g' | \
        perl -pe 's/^ID:(\d+)　/ID:\1 ■/g' | \
        perl -pe 's/(.*) \(新着\)$/【新】 \1/g' | \
        perl -pe 's/( のDL開始|第\d+部分　)//g' `
        send_notification "$1" "$BODY"
        ;;
        "SLACK")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/^ID:(\d+)　(.*) の更新はキャンセルされました/:id:\1 :broken_heart: \2/g' | \
        perl -pe 's/^ID:92　/:id::nine::two: :notebook_with_decorative_cover:/g' | \
        perl -pe 's/^ID:(\d+)　/:id:\1 :dizzy:/g' | \
        perl -pe 's/( |　)+/ /g' | \
        perl -pe 's/(.*) \(新着\)$/:new: \1/g' | \
        perl -pe 's/\(完結\)/:white_flower:/g' | \
        perl -pe 's/( のDL開始|第\d+部分 )//g' `
        #BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        #perl -pe 's/^ID:(\d+)　(.*) の更新はキャンセルされました/:id:\1 :broken_heart: \2/g' | \
        #perl -pe 's/^ID:(\d+)　/:id:\1 :inbox_tray:/g' | \
        #perl -pe 's/(.*) \(新着\)$/:new: \1/g' | \
        #perl -pe 's/\(完結\)/:white_flower:/g' | \
        #perl -pe 's/( のDL開始|第\d+部分　)//g' | \
        #perl -ne 'BEGIN{$title=""} {if( $_ =~ /^:id:/) {$title=$_; chomp($title)} else {$sub=$_; chomp($sub); printf("%s %s\n", $title, $sub)} }'
        #` ; echo $BODY
        send_notification ":inbox_tray::up:$1" "$BODY"
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
    #TITLE="$1\n"
    TITLE=""
    BODY="$2"
    curl -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"narou.rb\", \"text\": \"$TITLE$BODY\", \"icon_emoji\": \":$SLACK_ICON:\"}" $SLACK_WEBHOOK
}

# EOF
