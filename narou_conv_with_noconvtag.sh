#!/bin/bash
# -*- coding:utf-8 -*-

if [ -f $0 ]; then
    . `dirname $0`/narou_update.settings
    . `dirname $0`/narou_update_func.sh
else
    SELF=`which $0`
    . `dirname $SELF`/narou_update.settings
    . `dirname $SELF`/narou_update_func.sh
fi

# run check
wait_other_script

### main ###
pushd $NAROU_DIR

# Convert
NAME=`$NAROU list -t "$NOCONV_TAG $KINDLE_TAG" -e | grep -v "タイトル" | perl -F'\|' -alne 'print "ID:" . $F[0] . $F[2]'`
NID=`$NAROU list -t "$NOCONV_TAG $KINDLE_TAG" | cat`

if [ "$NID" == "" ]; then
    exit 0
fi

$NAROU convert $NID

# edit tag
$NAROU tag -a "$NOSEND_TAG" -c yellow $NID
$NAROU tag -d "$NOCONV_TAG" "tag:$NOCONV_TAG"

# Send push notification if update
case "$NOTIFY_TYPE" in
    "PUSHBULLET")
    NAME=`echo "$NAME" | perl -pe 's/ID: *[\* ]?(\d+) /ID:\1 ■/g'`
	send_notification_pushbullet "【変換完了】" "$NAME"
	;;
    "LINE")
    NAME=`echo "$NAME" | perl -pe 's/ID: *[\* ]?(\d+) /ID:\1 ■/g'`
	send_notification_line "【変換完了】" "$NAME"
	;;
    "SLACK")
    NAME=`echo "$NAME" | perl -pe 's/ID: *[\* ]?(\d+) /:id:\1 :repeat:/g' | \
    perl -pe 'BEGIN{use utf8;use Encode;} s/^:id:\*/:id::snowflake:/g' | \
    perl -pe 'BEGIN{use utf8;use Encode;} s/(^:id:[^(、|、|。)]+)(、|、|。).*\(完結\)/\1...:white_flower:/g' | \
    perl -pe 'BEGIN{use utf8;use Encode;} s/\(完結\)/\...:white_flower:/g' | \
    perl -pe 'BEGIN{use utf8;use Encode;} s/(^:id:[^(、|、|。)]+)(、|、|。).*/\1.../g' | \
    perl -pe 'BEGIN{use utf8;use Encode;} s/(^ [^(～|～|ー|「|\-|（)].*)(～|～|ー|「|\-|（).*(～|～|ー|」|\-|）)/\1.../g' `
	send_notification_slack ":mega:小説変換" "$NAME"
	;;
esac

popd
# EOF
