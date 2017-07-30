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
GL_FLG="none"
while [ "$1" != "" ]
do
    TAG=${1:-fastcheck}
    if [ $USE_NAROU_API == "YES" ]; then
        if [ $GL_FLG != "done" ]; then
            ONLY_NAROU=`tag_only_narou "$TAG"`

            if [ $ONLY_NAROU == "YES" -a $GL_FLG != "narou" ]; then
                $NAROU update -n --gl narou
                GL_FLG="narou"
            elif [ $ONLY_NAROU == "NO" -a $GL_FLG == "narou" ]; then
                $NAROU update -n --gl other
                GL_FLG="done"
            elif [ $ONLY_NAROU == "NO" ]; then
                $NAROU update -n --gl
                GL_FLG="done"
            fi
        fi
        if [ `$NAROU list -t "$TAG modified" -f nonfrozen -e|egrep -v "(タイトル|^$)"|wc -l` -eq 0 ]; then
            shift
            continue
        fi
        touch ./log/update_log_dummy.txt
        $NAROU list -t "$TAG modified" -f nonfrozen | $NAROU update -n -i
        # $NAROU list -t "$TAG modified" | $NAROU tag -d modified
    else
        $NAROU list -t $TAG -f nonfrozen | $NAROU update -n -i
    fi

    # add tag: no convert
    NAROU_LOG=./log/`ls -1t log | head -1`
    tag_add_noconv $NAROU_LOG
    rm -f ./log/update_log_dummy.txt

    # Send push notification if update
    RES_NEW=`egrep "新着" $NAROU_LOG`
    if [ ! "$RES_NEW" = "" ]; then
        $NAROU mail hotentry
        send_notification_for_update "$TAG" "$NAROU_LOG"
    fi
    shift
done

freeze_novel

relese_narou_update_lock

popd
# EOF
