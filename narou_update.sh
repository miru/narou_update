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
#$NAROU update -n
$NAROU update -n --gl
$NAROU list -t modified | $NAROU update -n
# $NAROU mail hotentry

tag_add_noconv ./log/`ls -1t log | head -1`

$NAROU list -t modified | $NAROU tag -a $NOCONV_TAG
$NAROU list -t modified | $NAROU tag -d modified

$NAROU freeze --on tag:end > /dev/null 2>&1
$NAROU freeze --on tag:404 > /dev/null 2>&1

popd
# EOF
