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

if [ -f "./download.txt" -a -s "./download.txt" ]; then
    DT=`date +%Y%m%d_%H%M%S`
    mv -f ./download.txt $DOWN_HISTORY/download.$DT.txt
    touch ./download.txt
    URLS=`egrep -v "(^$|^#)" $DOWN_HISTORY/download.$DT.txt`
    $NAROU d -n $URLS
    $NAROU tag -a "未読" $URLS

    G=`echo "$URLS" | perl -pe 's/( |\r)//g' | perl -ne 'BEGIN{@F=()} {chomp(); push(@F,$_)}; END{print "(" . join("|",@F) . ")"}'`

    if [ "$NOTIFY_TYPE" == "SLACK" ]; then
        TITLE=`$NAROU list -u -e | egrep -e "$G" | egrep -v "タイトル" | \
        perl -F'\|' -alne 'print ":id:" . $F[0] . ":inbox_tray:" . $F[2]' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/(^:id:[^(、|、|。)]+)(、|、|。).*\(完結\)/\1... :white_flower:/g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/\(完結\)/\:white_flower:/g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/^:id:\*/:id::snowflake:/g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/(^:id:[^(、|、|。)]+)(、|、|。).*/\1.../g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/(^ [^(～|ー|「|\-|（)].*)(～|ー|「|\-|（).*(～|ー|」|\-|）)/\1.../g' `
        send_notification ":inbox_tray:小説ダウンロード" "$TITLE"
    else
        TITLE=`$NAROU list -u -e | egrep -e "$G" | egrep -v "タイトル" | \
        perl -F'\|' -alne 'print "ID:" . $F[0] . "■" . $F[2]'
        perl -pe 'BEGIN{use utf8;use Encode;} s/(～|～|「|\-|（).*(～|～|」|\-|）)//g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/(^ID:[^(、|、|。)]+)(、|、|。).*(\(完結\))?/\1\3/g' `
        send_notification "【小説DL】" "$TITLE"
    fi
fi

freeze_novel

popd
# EOF
