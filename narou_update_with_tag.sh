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

# Update
GL_FLG="none"
while [ "$1" != "" ]
do
    TAG=${1:-fastcheck}
    if [ $GL_FLG != "done" ]; then
        ONLY_NAROU=`tag_only_narou "$TAG"`

        if [ $ONLY_NAROU == "YES" -a $GL_FLG != "narou" ]; then
            $NAROU update -n --gl narou
            GL_FLG="narou"
        else
            $NAROU update -n --gl
            GL_FLG="done"
        fi
    fi

    NUM=`$NAROU list -t "$TAG modified" -e | egrep -v "(タイトル|^$)" | wc -l`
    if [ $NUM -eq 0 ]; then
        shift
        continue
    fi

    $NAROU list -t "$TAG modified" -f nonfrozen | $NAROU update -n -i
    $NAROU list -t "$TAG modified" | $NAROU tag -d modified

    # add tag: no convert
    NAROU_LOG=./log/`ls -1t log | head -1`
    tag_add_noconv $NAROU_LOG

    # Send push notification if update
    RES_NEW=`egrep "新着" $NAROU_LOG`
    if [ ! "$RES_NEW" = "" ]; then
        $NAROU mail hotentry
        send_notification_for_update "$TAG" "$NAROU_LOG"
    fi
    shift
done

$NAROU freeze --on tag:end > /dev/null 2>&1
$NAROU freeze --on tag:404 > /dev/null 2>&1

popd
# EOF
