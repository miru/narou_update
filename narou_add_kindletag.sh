#!/bin/bash

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

$NAROU tag -a "kindle 未転送" $* > /dev/null 2>&1
$NAROU tag -d "変換済み 未読 次" $*
$NAROU convert $*

popd

# EOF
