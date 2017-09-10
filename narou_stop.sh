#!/bin/bash

trap "relese_narou_update_lock" EXIT
trap "echo 処理を中断します ; exit 1" 1 2 3 15

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

for NID in $*
do
    $NAROU tag -d "kindle 購読中 購読中な 購読中R18 未変換 未転送 変換済み 未読" $NID > /dev/null 2>&1
    $NAROU tag -a "切" $NID
done

popd
# EOF
