#!/bin/bash
# -*- coding:utf-8 -*-

trap "relese_narou_update_lock" EXIT
trap "echo 処理を中断します" 1 2 3 15

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
    $NAROU update -n --gl
    $NAROU list -t modified | $NAROU tag -a $NOCONV_TAG
    $NAROU list -t modified | $NAROU update -n
else
    $NAROU update -n
fi

NAROU_LOG=./log/`ls -1t log | head -1`
tag_add_noconv $NAROU_LOG
rm -f ./log/update_log_dummy.txt

# Send push notification if update
#RES_NEW=`egrep "新着" $NAROU_LOG`
#if [ ! "$RES_NEW" = "" ]; then
#    send_notification_for_update "【全】" "$NAROU_LOG"
#fi

freeze_novel

popd
# EOF
