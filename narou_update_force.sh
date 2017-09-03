#!/bin/bash
# -*- coding:utf-8 -*-

trap "relese_narou_update_lock; exit" 0

if [ -f $0 ]; then
    . `dirname $0`/narou_update.settings
    . `dirname $0`/narou_update_func.sh
else
    SELF=`which $0`
    . `dirname $SELF`/narou_update.settings
    . `dirname $SELF`/narou_update_func.sh
fi

# run check
get_narou_update_lock
wait_other_script

### main ###
pushd $NAROU_DIR

# Update
if [ $USE_NAROU_API == "YES" ]; then
    touch ./log/update_log_dummy.txt
    $NAROU update -f -n --gl
    $NAROU list -t modified | $NAROU tag -a $NOCONV_TAG
    $NAROU list -t modified | $NAROU update -f -n
else
    $NAROU update -f -n
fi

NAROU_LOG=./log/`ls -1t log | head -1`
tag_add_noconv $NAROU_LOG
rm -f ./log/update_log_dummy.txt

# Send push notification if update
SS_ID=`$NAROU list -f ss | perl -pe 's/ /|/g' | perl -pe 's/^(.*)$/(\1)/g' `
RES=`egrep "は連載を再開したようです" $NAROU_LOG | egrep -v "$SS_ID"`
if [ ! "$RES" = "" ]; then
    RESTART_ID=`egrep "は連載を再開したようです" $NAROU_LOG | perl -pe 's/^ID:(\d+).*/\1/g' `
    $NAROU tag -a "再開" $RESTART_ID
    $NAROU list -t 再開 | $NAROU freeze --off > /dev/null 2>&1
    #$NAROU list -f ss | $NAROU freeze --on > /dev/null 2>&1

    case "$NOTIFY_TYPE" in
        "PUSHBULLET")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/(.*) は連載を再開したようです/【再開】\1/g' `
        send_notification "【再開】" "$BODY"
        ;;
        "LINE")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/(.*) は連載を再開したようです/【再開】\1/g' `
        send_notification "【再開】" "$BODY"
        ;;
        "SLACK")
        BODY=`echo "$RES" | perl -pe 's/\(\d+\/\d+\)//g' | \
        perl -pe 's/(.*) は連載を再開したようです/【再開:revolving_hearts:】\1/g' `
        send_notification "【全強制】" "$BODY"
    esac
fi

relese_narou_update_lock

popd
# EOF
