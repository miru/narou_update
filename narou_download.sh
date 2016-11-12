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

if [ -f "./download.txt" ]; then
    mv -f ./download.txt ./download.txt.tmp
    URLS=`cat ./download.txt.tmp`
    $NAROU d -n $URLS
    $NAROU tag -a "NEW" $URLS
    if [ "$NOTIFY_TYPE" == "SLACK"]; then
        send_notification ":mega: :inbox_tray: :new:" "$URLS"
    else
        send_notification "【小説DL】" "$URLS"
    fi
fi

popd

exit
# EOF
