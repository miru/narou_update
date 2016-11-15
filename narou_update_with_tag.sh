#!/bin/bash
# -*- coding:utf-8 -*-

# Get Settings
. `dirname $0`/narou_update.settings

# Load function
. `dirname $0`/narou_update_func.sh

# tag for check
TAG=${1:-fastcheck}

# run check
wait_other_script

### main ###
pushd $NAROU_DIR

# Update
if [ "$USE_UPDATETAG" == "yes" ]; then
    NID="tag:$TAG"
else
    NID=`$NAROU list -t $TAG -f nonfrozen | cat`
fi
$NAROU update -n $NID

NAROU_LOG=./log/`ls -1t log | head -1`

# add tag: no convert
tag_add_noconv $NAROU_LOG

# Send push notification if update
RES_NEW=`egrep "新着" $NAROU_LOG`

if [ ! "$RES_NEW" = "" ]; then
    send_notification_for_update "$TAG" "$NAROU_LOG"
fi

$NAROU freeze --on 404

popd
# EOF
