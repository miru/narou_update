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
#RES_NEW=`egrep "新着" $NAROU_LOG`
#if [ ! "$RES_NEW" = "" ]; then
#    send_notification_for_update "【全強制】" "$NAROU_LOG"
#fi

$NAROU freeze --on tag:end > /dev/null 2>&1
$NAROU freeze --on tag:404 > /dev/null 2>&1
$NAROU list -f ss | narou freeze --on > /dev/null 2>&1

relese_narou_update_lock

popd
# EOF
