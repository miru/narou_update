#!/bin/bash
# -*- coding:utf-8 -*-

# Get Settings
. `dirname $0`/narou_update.settings

# Load function
. `dirname $0`/narou_update_func.sh

# run check
wait_other_script

### main ###
pushd $NAROU_DIR

# Convert
NAME=`$NAROU list -t "$NOCONV_TAG $KINDLE_TAG" -e | grep -v "タイトル" | awk -F\| '{print $3}'`
NID=`$NAROU list -t "$NOCONV_TAG $KINDLE_TAG" | cat`

if [ "$NID" == "" ]; then
    exit 0
fi

$NAROU convert $NID

# edit tag
$NAROU tag -a "$NOSEND_TAG" -c yellow $NID
$NAROU tag -d "$NOCONV_TAG" $NID

# Send push notification if update
case "$NOTIFY_TYPE" in
    "PUSHBULLET")
    NAME=`echo "$NAME" | perl -ne 'BEGIN{printf("\n")} printf(":■%s", $_)'`
	send_notification_pushbullet "【変換完了】" "$NAME"
	;;
    "LINE")
    NAME=`echo "$NAME" | perl -ne 'BEGIN{printf("\n")} printf(":■%s", $_)'`
	send_notification_line "【変換完了】" "$NAME"
	;;
    "SLACK")
    NAME=`echo "$NAME" | perl -ne 'BEGIN{printf("\n")} printf(":book:%s", $_)'`
	send_notification_slack "【変換完了】" "$NAME"
	;;
esac

popd
# EOF
